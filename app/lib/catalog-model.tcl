namespace eval ::fossilhub::catalog {
  variable defaultDatabase /data/catalog/fossilhub.sqlite
  variable defaultSqlite /usr/bin/sqlite3
}

proc ::fossilhub::catalog::databasePath {} {
  variable defaultDatabase
  if {[info exists ::env(FOSSILHUB_CATALOG_DB)] &&
      $::env(FOSSILHUB_CATALOG_DB) ne ""} {
    return [file normalize $::env(FOSSILHUB_CATALOG_DB)]
  }
  return [file normalize $defaultDatabase]
}

proc ::fossilhub::catalog::sqliteBinary {} {
  variable defaultSqlite
  if {[info exists ::env(FOSSILHUB_SQLITE)] &&
      $::env(FOSSILHUB_SQLITE) ne ""} {
    return $::env(FOSSILHUB_SQLITE)
  }
  return $defaultSqlite
}

proc ::fossilhub::catalog::textLiteral {value} {
  set bytes [encoding convertto utf-8 $value]
  return "CAST(X'[binary encode hex $bytes]' AS TEXT)"
}

proc ::fossilhub::catalog::integerValue {value} {
  if {![string is wideinteger -strict $value]} {
    return 0
  }
  return $value
}

proc ::fossilhub::catalog::decodeRows {raw columnCount} {
  set rows {}
  foreach line [split [string trimright $raw "\r\n"] "\n"] {
    if {$line eq ""} {
      continue
    }
    set fields [split [string trimright $line "\r"] "\t"]
    if {[llength $fields] != $columnCount} {
      error "unexpected catalogue query column count"
    }
    set row {}
    foreach field $fields {
      if {[string length $field] % 2 != 0 ||
          ![regexp {^[[:xdigit:]]*$} $field]} {
        error "invalid hexadecimal field from catalogue"
      }
      lappend row [encoding convertfrom utf-8 [binary format H* $field]]
    }
    lappend rows $row
  }
  return $rows
}

proc ::fossilhub::catalog::sqlRows {sql columnCount} {
  set database [::fossilhub::catalog::databasePath]
  if {![file isfile $database]} {
    return {}
  }
  set raw [exec \
    [::fossilhub::catalog::sqliteBinary] \
    -readonly -batch -noheader -separator "\t" \
    $database $sql]
  return [::fossilhub::catalog::decodeRows $raw $columnCount]
}

proc ::fossilhub::catalog::searchOptions {{options {}}} {
  set result [dict create q "" kind all sort recent limit 100]
  foreach key {q kind sort limit} {
    if {[dict exists $options $key]} {
      dict set result $key [dict get $options $key]
    }
  }

  set query [string trim [string map [list \u0000 ""] [dict get $result q]]]
  dict set result q [string range $query 0 119]

  if {[dict get $result kind] ni {all code wiki tickets forum}} {
    dict set result kind all
  }
  if {[dict get $result sort] ni {recent oldest name size}} {
    dict set result sort recent
  }
  set limit [dict get $result limit]
  if {![string is integer -strict $limit] || $limit < 1 || $limit > 200} {
    dict set result limit 100
  }
  return $result
}

proc ::fossilhub::catalog::repositoryQuerySql {{options {}}} {
  set options [::fossilhub::catalog::searchOptions $options]
  set query [dict get $options q]
  set where {1=1}
  if {$query ne ""} {
    set pattern [string map [list \\ \\\\ % \\% _ \\_] $query]
    append where " AND lower(name || ' ' || project_name || ' ' || description || ' ' || category || ' ' || language) LIKE '%' || lower([::fossilhub::catalog::textLiteral $pattern]) || '%' ESCAPE '\\'"
  }

  switch -- [dict get $options kind] {
    code    { append where { AND checkins > 0} }
    wiki    { append where { AND wiki_events > 0} }
    tickets { append where { AND ticket_events > 0} }
    forum   { append where { AND forum_events > 0} }
  }

  switch -- [dict get $options sort] {
    oldest { set order {opened_epoch ASC, name COLLATE NOCASE ASC} }
    name   { set order {project_name COLLATE NOCASE ASC, name COLLATE NOCASE ASC} }
    size   { set order {bytes DESC, name COLLATE NOCASE ASC} }
    default { set order {latest_epoch DESC, featured DESC, name COLLATE NOCASE ASC} }
  }

  return [format {
    SELECT hex(name), hex(slug), hex(project_name), hex(description),
           hex(source_url), hex(category), hex(language),
           hex(CAST(featured AS TEXT)), hex(CAST(bytes AS TEXT)),
           hex(project_code), hex(CAST(artifacts AS TEXT)),
           hex(CAST(checkins AS TEXT)), hex(CAST(wiki_events AS TEXT)),
           hex(CAST(ticket_events AS TEXT)), hex(CAST(forum_events AS TEXT)),
           hex(CAST(contributors AS TEXT)), hex(CAST(open_tickets AS TEXT)),
           hex(CAST(opened_epoch AS TEXT)), hex(CAST(latest_epoch AS TEXT)),
           hex(CAST(indexed_epoch AS TEXT))
      FROM repositories
     WHERE %s
     ORDER BY %s
     LIMIT %d;
  } $where $order [dict get $options limit]]
}

proc ::fossilhub::catalog::eventQuerySql {} {
  return {
    SELECT hex(repository_name), hex(type), hex(CAST(epoch AS TEXT)),
           hex(uuid), hex(user), hex(comment)
      FROM events
     ORDER BY epoch DESC, event_rank ASC;
  }
}

proc ::fossilhub::catalog::repositories {{options {}}} {
  set rows [::fossilhub::catalog::sqlRows \
    [::fossilhub::catalog::repositoryQuerySql $options] 20]
  set eventsByRepository {}
  foreach row [::fossilhub::catalog::sqlRows \
      [::fossilhub::catalog::eventQuerySql] 6] {
    lassign $row name type epoch uuid user comment
    dict lappend eventsByRepository $name [dict create \
      type $type epoch $epoch uuid $uuid user $user comment $comment]
  }

  set result {}
  foreach row $rows {
    lassign $row name slug projectName description sourceUrl category language \
      featured bytes projectCode artifacts checkins wikiEvents ticketEvents \
      forumEvents contributors openTickets openedEpoch latestEpoch indexedEpoch
    set events {}
    if {[dict exists $eventsByRepository $name]} {
      set events [dict get $eventsByRepository $name]
    }
    lappend result [dict create \
      available 1 name $name slug $slug path "" \
      project_name $projectName description $description source_url $sourceUrl \
      category $category language $language featured $featured bytes $bytes \
      project_code $projectCode artifacts $artifacts checkins $checkins \
      wiki_events $wikiEvents ticket_events $ticketEvents \
      forum_events $forumEvents contributors $contributors \
      open_tickets $openTickets opened_epoch $openedEpoch \
      latest_epoch $latestEpoch indexed_epoch $indexedEpoch events $events]
  }
  return $result
}

proc ::fossilhub::catalog::schemaSql {} {
  return {
    PRAGMA journal_mode=OFF;
    PRAGMA synchronous=OFF;
    PRAGMA foreign_keys=ON;
    CREATE TABLE repositories(
      name TEXT PRIMARY KEY,
      slug TEXT NOT NULL UNIQUE,
      project_name TEXT NOT NULL,
      description TEXT NOT NULL,
      source_url TEXT NOT NULL,
      category TEXT NOT NULL,
      language TEXT NOT NULL,
      featured INTEGER NOT NULL CHECK(featured IN (0,1)),
      bytes INTEGER NOT NULL CHECK(bytes >= 0),
      project_code TEXT NOT NULL,
      artifacts INTEGER NOT NULL,
      checkins INTEGER NOT NULL,
      wiki_events INTEGER NOT NULL,
      ticket_events INTEGER NOT NULL,
      forum_events INTEGER NOT NULL,
      contributors INTEGER NOT NULL,
      open_tickets INTEGER NOT NULL,
      opened_epoch INTEGER NOT NULL,
      latest_epoch INTEGER NOT NULL,
      indexed_epoch INTEGER NOT NULL
    ) STRICT;
    CREATE TABLE events(
      repository_name TEXT NOT NULL REFERENCES repositories(name) ON DELETE CASCADE,
      event_rank INTEGER NOT NULL,
      type TEXT NOT NULL,
      epoch INTEGER NOT NULL,
      uuid TEXT NOT NULL,
      user TEXT NOT NULL,
      comment TEXT NOT NULL,
      PRIMARY KEY(repository_name,event_rank)
    ) STRICT;
    CREATE INDEX repositories_recent ON repositories(latest_epoch DESC);
    CREATE INDEX repositories_category ON repositories(category,latest_epoch DESC);
    CREATE INDEX events_recent ON events(epoch DESC);
    PRAGMA user_version=1;
  }
}

proc ::fossilhub::catalog::insertRepositorySql {repository indexedEpoch} {
  set columns {
    name slug project_name description source_url category language
    featured bytes project_code artifacts checkins wiki_events ticket_events
    forum_events contributors open_tickets opened_epoch latest_epoch
  }
  set values {}
  foreach column $columns {
    set value [dict get $repository $column]
    if {$column in {
        featured bytes artifacts checkins wiki_events ticket_events forum_events
        contributors open_tickets opened_epoch latest_epoch}} {
      lappend values [::fossilhub::catalog::integerValue $value]
    } else {
      lappend values [::fossilhub::catalog::textLiteral $value]
    }
  }
  lappend values [::fossilhub::catalog::integerValue $indexedEpoch]
  return "INSERT INTO repositories VALUES([join $values ,]);\n"
}

proc ::fossilhub::catalog::insertEventsSql {repository} {
  set sql ""
  set rank 0
  foreach event [dict get $repository events] {
    incr rank
    set values [list \
      [::fossilhub::catalog::textLiteral [dict get $repository name]] \
      $rank \
      [::fossilhub::catalog::textLiteral [dict get $event type]] \
      [::fossilhub::catalog::integerValue [dict get $event epoch]] \
      [::fossilhub::catalog::textLiteral [dict get $event uuid]] \
      [::fossilhub::catalog::textLiteral [dict get $event user]] \
      [::fossilhub::catalog::textLiteral [dict get $event comment]]]
    append sql "INSERT INTO events VALUES([join $values ,]);\n"
  }
  return $sql
}

proc ::fossilhub::catalog::writeDatabase {repositories {target ""}} {
  if {$target eq ""} {
    set target [::fossilhub::catalog::databasePath]
  } else {
    set target [file normalize $target]
  }
  set directory [file dirname $target]
  file mkdir $directory
  file attributes $directory -permissions 0750

  set temporary "${target}.new.[pid].[clock clicks]"
  if {[file exists $temporary]} {
    error "refusing to reuse catalogue temporary file"
  }
  set indexedEpoch [clock seconds]
  set sql [::fossilhub::catalog::schemaSql]
  append sql "BEGIN IMMEDIATE;\n"
  foreach repository $repositories {
    append sql [::fossilhub::catalog::insertRepositorySql \
      $repository $indexedEpoch]
    append sql [::fossilhub::catalog::insertEventsSql $repository]
  }
  append sql "COMMIT;\nPRAGMA quick_check;\n"

  try {
    exec [::fossilhub::catalog::sqliteBinary] -batch $temporary << $sql
    file attributes $temporary -permissions 0600
    file rename -force $temporary $target
  } on error {message options} {
    if {[file exists $temporary]} {
      file delete -force $temporary
    }
    return -options $options $message
  }
  return [llength $repositories]
}

proc ::fossilhub::catalog::rebuild {} {
  set repositories {}
  if {[llength [info commands ::fossilhub::platform::publicRepositories]] > 0 &&
      [file isfile [::fossilhub::platform::databasePath]]} {
    set entries [::fossilhub::platform::publicRepositories]
  } else {
    set entries [::fossilhub::manifest::all]
  }
  foreach entry $entries {
    set name [dict get $entry name]
    set path [::fossilhub::model::repositoryPath $name]
    if {![file isfile $path]} {
      continue
    }
    if {[catch {
      set repository [::fossilhub::model::repository $name 12]
    }]} {
      puts stderr "FossilHub: unable to index [file tail $name]"
      continue
    }
    foreach key {slug source_url category language featured} {
      dict set repository $key [dict get $entry $key]
    }
    if {[dict exists $entry id]} {
      dict set repository project_name [dict get $entry title]
      dict set repository description [dict get $entry description]
    } elseif {[string trim [dict get $repository project_name]] in {
        {} {Untitled Fossil repository}}} {
      dict set repository project_name [dict get $entry title]
    }
    if {![dict exists $entry id] &&
        [string trim [dict get $repository description]] eq ""} {
      dict set repository description [dict get $entry description]
    }
    lappend repositories $repository
  }
  return [::fossilhub::catalog::writeDatabase $repositories]
}
