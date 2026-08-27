namespace eval ::fossilhub::platform {
  variable defaultDatabase /data/platform/fossilhub.sqlite
  variable defaultSqlite /usr/bin/sqlite3
  variable schemaVersion 3
}

proc ::fossilhub::platform::databasePath {} {
  variable defaultDatabase
  if {[info exists ::env(FOSSILHUB_PLATFORM_DB)] &&
      $::env(FOSSILHUB_PLATFORM_DB) ne ""} {
    return [file normalize $::env(FOSSILHUB_PLATFORM_DB)]
  }
  return [file normalize $defaultDatabase]
}

proc ::fossilhub::platform::sqliteBinary {} {
  variable defaultSqlite
  if {[info exists ::env(FOSSILHUB_SQLITE)] &&
      $::env(FOSSILHUB_SQLITE) ne ""} {
    return $::env(FOSSILHUB_SQLITE)
  }
  return $defaultSqlite
}

proc ::fossilhub::platform::textLiteral {value} {
  set bytes [encoding convertto utf-8 $value]
  return "CAST(X'[binary encode hex $bytes]' AS TEXT)"
}

proc ::fossilhub::platform::integerValue {value} {
  if {![string is wideinteger -strict $value]} {
    error "invalid platform integer"
  }
  return $value
}

proc ::fossilhub::platform::decodeRows {raw columnCount} {
  set rows {}
  foreach line [split [string trimright $raw "\r\n"] "\n"] {
    if {$line eq ""} {
      continue
    }
    set fields [split [string trimright $line "\r"] "\t"]
    if {[llength $fields] != $columnCount} {
      error "unexpected platform query column count"
    }
    set row {}
    foreach field $fields {
      if {[string length $field] % 2 != 0 ||
          ![regexp {^[[:xdigit:]]*$} $field]} {
        error "invalid hexadecimal field from platform database"
      }
      lappend row [encoding convertfrom utf-8 [binary format H* $field]]
    }
    lappend rows $row
  }
  return $rows
}

proc ::fossilhub::platform::sqlRows {sql columnCount {database ""}} {
  if {$database eq ""} {
    set database [::fossilhub::platform::databasePath]
  } else {
    set database [file normalize $database]
  }
  if {![file isfile $database]} {
    return {}
  }
  set raw [exec \
    [::fossilhub::platform::sqliteBinary] \
    -readonly -batch -noheader -separator "\t" \
    $database $sql]
  return [::fossilhub::platform::decodeRows $raw $columnCount]
}

proc ::fossilhub::platform::execute {database sql} {
  set database [file normalize $database]
  return [exec [::fossilhub::platform::sqliteBinary] \
    -batch -bail $database << $sql]
}

proc ::fossilhub::platform::schemaSql {} {
  return {
    PRAGMA journal_mode=DELETE;
    PRAGMA synchronous=FULL;
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;

    CREATE TABLE schema_migrations(
      version INTEGER PRIMARY KEY,
      applied_epoch INTEGER NOT NULL,
      description TEXT NOT NULL
    ) STRICT;

    CREATE TABLE users(
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL COLLATE NOCASE UNIQUE,
      email TEXT NOT NULL COLLATE NOCASE UNIQUE,
      display_name TEXT NOT NULL DEFAULT '',
      biography TEXT NOT NULL DEFAULT '',
      website TEXT NOT NULL DEFAULT '',
      location TEXT NOT NULL DEFAULT '',
      role TEXT NOT NULL DEFAULT 'user'
        CHECK(role IN ('user','administrator')),
      status TEXT NOT NULL DEFAULT 'active'
        CHECK(status IN ('active','disabled','deactivated')),
      created_epoch INTEGER NOT NULL,
      updated_epoch INTEGER NOT NULL,
      last_login_epoch INTEGER NOT NULL DEFAULT 0,
      must_change_password INTEGER NOT NULL DEFAULT 0
        CHECK(must_change_password IN (0,1))
    ) STRICT;

    CREATE TABLE credentials(
      user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      password_hash TEXT NOT NULL,
      password_changed_epoch INTEGER NOT NULL
    ) STRICT;

    CREATE TABLE sessions(
      id_hash TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      csrf_hash TEXT NOT NULL,
      created_epoch INTEGER NOT NULL,
      seen_epoch INTEGER NOT NULL,
      idle_expires_epoch INTEGER NOT NULL,
      absolute_expires_epoch INTEGER NOT NULL,
      reauthenticated_epoch INTEGER NOT NULL DEFAULT 0,
      user_agent_hash TEXT NOT NULL DEFAULT '',
      address_hash TEXT NOT NULL DEFAULT ''
    ) STRICT;

    CREATE TABLE login_attempts(
      key_hash TEXT PRIMARY KEY,
      attempts INTEGER NOT NULL CHECK(attempts >= 0),
      window_epoch INTEGER NOT NULL,
      blocked_until_epoch INTEGER NOT NULL DEFAULT 0
    ) STRICT;

    CREATE TABLE form_challenges(
      token_hash TEXT PRIMARY KEY,
      session_id_hash TEXT REFERENCES sessions(id_hash) ON DELETE CASCADE,
      purpose TEXT NOT NULL,
      created_epoch INTEGER NOT NULL,
      expires_epoch INTEGER NOT NULL
    ) STRICT;

    CREATE TABLE repositories(
      id TEXT PRIMARY KEY,
      slug TEXT NOT NULL COLLATE NOCASE UNIQUE,
      fossil_name TEXT NOT NULL COLLATE NOCASE UNIQUE,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      source_url TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT 'uncategorized',
      language TEXT NOT NULL DEFAULT 'Not set',
      visibility TEXT NOT NULL DEFAULT 'public'
        CHECK(visibility IN ('public','private')),
      state TEXT NOT NULL DEFAULT 'active'
        CHECK(state IN ('active','archived','quarantined')),
      owner_user_id TEXT REFERENCES users(id) ON DELETE RESTRICT,
      default_branch TEXT NOT NULL DEFAULT 'trunk',
      featured INTEGER NOT NULL DEFAULT 0 CHECK(featured IN (0,1)),
      created_epoch INTEGER NOT NULL,
      updated_epoch INTEGER NOT NULL,
      archived_epoch INTEGER NOT NULL DEFAULT 0
    ) STRICT;

    CREATE TABLE memberships(
      repository_id TEXT NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      role TEXT NOT NULL
        CHECK(role IN ('reader','triage','writer','maintainer','owner')),
      created_epoch INTEGER NOT NULL,
      updated_epoch INTEGER NOT NULL,
      PRIMARY KEY(repository_id,user_id)
    ) STRICT;

    CREATE TABLE audit_events(
      id TEXT PRIMARY KEY,
      actor_user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
      repository_id TEXT REFERENCES repositories(id) ON DELETE SET NULL,
      action TEXT NOT NULL,
      target TEXT NOT NULL DEFAULT '',
      outcome TEXT NOT NULL CHECK(outcome IN ('success','denied','failure')),
      request_id TEXT NOT NULL DEFAULT '',
      detail TEXT NOT NULL DEFAULT '',
      created_epoch INTEGER NOT NULL
    ) STRICT;

    CREATE TABLE settings(
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_epoch INTEGER NOT NULL
    ) STRICT;

    CREATE INDEX users_status ON users(status,username COLLATE NOCASE);
    CREATE INDEX sessions_user ON sessions(user_id,absolute_expires_epoch);
    CREATE INDEX form_challenges_expiry ON form_challenges(expires_epoch);
    CREATE INDEX repositories_public
      ON repositories(state,visibility,featured DESC,slug COLLATE NOCASE);
    CREATE INDEX repositories_owner ON repositories(owner_user_id,state);
    CREATE INDEX memberships_user ON memberships(user_id,role);
    CREATE INDEX audit_recent ON audit_events(created_epoch DESC,id);
    CREATE INDEX audit_actor ON audit_events(actor_user_id,created_epoch DESC);
    CREATE INDEX audit_repository
      ON audit_events(repository_id,created_epoch DESC);

    INSERT INTO settings VALUES('registration','open',0);
    INSERT INTO settings VALUES('default_visibility','public',0);
    INSERT INTO settings VALUES('maintenance_banner','',0);
    INSERT INTO schema_migrations VALUES(1,0,'initial platform schema');
    INSERT INTO schema_migrations VALUES(2,0,'form challenge store');
    INSERT INTO schema_migrations VALUES(3,0,'forced password change state');
    PRAGMA user_version=3;
    COMMIT;
    PRAGMA quick_check;
  }
}

proc ::fossilhub::platform::databaseVersion {{database ""}} {
  if {$database eq ""} {
    set database [::fossilhub::platform::databasePath]
  } else {
    set database [file normalize $database]
  }
  if {![file isfile $database]} {
    return 0
  }
  set raw [exec [::fossilhub::platform::sqliteBinary] \
    -readonly -batch -noheader $database {PRAGMA user_version;}]
  set version [string trim $raw]
  if {![string is integer -strict $version] || $version < 0} {
    error "invalid platform schema version"
  }
  return $version
}

proc ::fossilhub::platform::createDatabase {database} {
  set database [file normalize $database]
  set directory [file dirname $database]
  file mkdir $directory
  file attributes $directory -permissions 0750
  set temporary "${database}.new.[pid].[clock clicks]"
  if {[file exists $temporary]} {
    error "refusing to reuse platform database temporary file"
  }
  try {
    set output [::fossilhub::platform::execute \
      $temporary [::fossilhub::platform::schemaSql]]
    if {[string trim [lindex [split $output "\n"] end]] ne "ok"} {
      error "platform database integrity check failed"
    }
    file attributes $temporary -permissions 0600
    file rename $temporary $database
  } on error {message options} {
    if {[file exists $temporary]} {
      file delete -force $temporary
    }
    return -options $options $message
  }
}

proc ::fossilhub::platform::migrateDatabase {database fromVersion} {
  variable schemaVersion
  set database [file normalize $database]
  if {$fromVersion == $schemaVersion} {
    return
  }
  if {$fromVersion > $schemaVersion} {
    error "platform database schema is newer than this application"
  }

  set backup "${database}.backup-v${fromVersion}.[pid].[clock clicks]"
  set temporary "${database}.migrate.[pid].[clock clicks]"
  if {[file exists $backup] || [file exists $temporary]} {
    error "refusing to reuse platform migration files"
  }
  file copy $database $backup
  file attributes $backup -permissions 0600
  try {
    if {$fromVersion == 0 && [file size $database] == 0} {
      ::fossilhub::platform::createDatabase $temporary
    } elseif {$fromVersion in {1 2}} {
      file copy $database $temporary
      set currentVersion $fromVersion
      while {$currentVersion < $schemaVersion} {
        switch -- $currentVersion {
          1 {
            set migration {
              PRAGMA foreign_keys=ON;
              BEGIN IMMEDIATE;
              CREATE TABLE form_challenges(
                token_hash TEXT PRIMARY KEY,
                session_id_hash TEXT REFERENCES sessions(id_hash)
                  ON DELETE CASCADE,
                purpose TEXT NOT NULL,
                created_epoch INTEGER NOT NULL,
                expires_epoch INTEGER NOT NULL
              ) STRICT;
              CREATE INDEX form_challenges_expiry
                ON form_challenges(expires_epoch);
              INSERT INTO schema_migrations
                VALUES(2,0,'form challenge store');
              PRAGMA user_version=2;
              COMMIT;
              PRAGMA quick_check;
            }
          }
          2 {
            set migration {
              PRAGMA foreign_keys=ON;
              BEGIN IMMEDIATE;
              ALTER TABLE users ADD COLUMN must_change_password INTEGER
                NOT NULL DEFAULT 0 CHECK(must_change_password IN (0,1));
              INSERT INTO schema_migrations
                VALUES(3,0,'forced password change state');
              PRAGMA user_version=3;
              COMMIT;
              PRAGMA quick_check;
            }
          }
          default {
            error "unsupported platform database migration from version $currentVersion"
          }
        }
        set output [::fossilhub::platform::execute $temporary $migration]
        if {[string trim $output] ne "ok"} {
          error "platform migration integrity check failed"
        }
        incr currentVersion
      }
      file attributes $temporary -permissions 0600
    } else {
      error "unsupported platform database migration from version $fromVersion"
    }
    file rename -force $temporary $database
    file attributes $database -permissions 0600
  } on error {message options} {
    if {[file exists $temporary]} {
      file delete -force $temporary
    }
    return -options $options $message
  }
}

proc ::fossilhub::platform::seedSql {} {
  set now [clock seconds]
  set sql "PRAGMA foreign_keys=ON;\nBEGIN IMMEDIATE;\n"
  foreach repository [::fossilhub::manifest::all] {
    set slug [dict get $repository slug]
    set values [list \
      [::fossilhub::platform::textLiteral "seed:$slug"] \
      [::fossilhub::platform::textLiteral $slug] \
      [::fossilhub::platform::textLiteral [dict get $repository name]] \
      [::fossilhub::platform::textLiteral [dict get $repository title]] \
      [::fossilhub::platform::textLiteral [dict get $repository description]] \
      [::fossilhub::platform::textLiteral [dict get $repository source_url]] \
      [::fossilhub::platform::textLiteral [dict get $repository category]] \
      [::fossilhub::platform::textLiteral [dict get $repository language]] \
      [::fossilhub::platform::textLiteral public] \
      [::fossilhub::platform::textLiteral active] \
      NULL \
      [::fossilhub::platform::textLiteral trunk] \
      [expr {[dict get $repository featured] ? 1 : 0}] \
      $now $now 0]
    append sql "INSERT OR IGNORE INTO repositories VALUES([join $values ,]);\n"
  }
  append sql "COMMIT;\nPRAGMA quick_check;\n"
  return $sql
}

proc ::fossilhub::platform::seedRepositories {{database ""}} {
  if {$database eq ""} {
    set database [::fossilhub::platform::databasePath]
  } else {
    set database [file normalize $database]
  }
  set output [::fossilhub::platform::execute \
    $database [::fossilhub::platform::seedSql]]
  if {[string trim $output] ne "ok"} {
    error "platform repository seed integrity check failed"
  }
  file attributes $database -permissions 0600
}

proc ::fossilhub::platform::initialize {{database ""}} {
  variable schemaVersion
  if {$database eq ""} {
    set database [::fossilhub::platform::databasePath]
  } else {
    set database [file normalize $database]
  }
  if {![file exists $database]} {
    ::fossilhub::platform::createDatabase $database
  } else {
    if {![file isfile $database]} {
      error "platform database path is not a regular file"
    }
    ::fossilhub::platform::migrateDatabase \
      $database [::fossilhub::platform::databaseVersion $database]
  }
  if {[::fossilhub::platform::databaseVersion $database] != $schemaVersion} {
    error "platform database schema initialization failed"
  }
  ::fossilhub::platform::seedRepositories $database
  return $schemaVersion
}

proc ::fossilhub::platform::publicRepositories {} {
  set rows [::fossilhub::platform::sqlRows {
    SELECT hex(id),hex(fossil_name),hex(slug),hex(title),hex(description),
           hex(source_url),hex(category),hex(language),
           hex(CAST(featured AS TEXT)),hex(default_branch)
      FROM repositories
     WHERE state='active' AND visibility='public'
     ORDER BY featured DESC,slug COLLATE NOCASE;
  } 10]
  set repositories {}
  foreach row $rows {
    lassign $row id name slug title description sourceUrl category language \
      featured defaultBranch
    lappend repositories [dict create \
      id $id name $name slug $slug title $title description $description \
      source_url $sourceUrl category $category language $language \
      featured $featured default_branch $defaultBranch visibility public \
      state active]
  }
  return $repositories
}

proc ::fossilhub::platform::publicRepository {name} {
  set literal [::fossilhub::platform::textLiteral $name]
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(id),hex(fossil_name),hex(slug),hex(title),hex(description),
           hex(source_url),hex(category),hex(language),
           hex(CAST(featured AS TEXT)),hex(default_branch)
      FROM repositories
     WHERE state='active' AND visibility='public'
       AND fossil_name=%s COLLATE NOCASE
     LIMIT 1;
  } $literal] 10]
  if {[llength $rows] == 0} {
    return ""
  }
  lassign [lindex $rows 0] id fossilName slug title description sourceUrl \
    category language featured defaultBranch
  return [dict create \
    id $id name $fossilName slug $slug title $title description $description \
    source_url $sourceUrl category $category language $language \
    featured $featured default_branch $defaultBranch visibility public \
    state active]
}

proc ::fossilhub::platform::publicContains {name} {
  expr {[::fossilhub::platform::publicRepository $name] ne ""}
}
