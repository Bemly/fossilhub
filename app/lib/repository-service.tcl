namespace eval ::fossilhub::repositories {
  variable publicNobodyCapabilities gjorz2
  variable publicAnonymousCapabilities hmnc3
}

proc ::fossilhub::repositories::validateSlug {slug} {
  set slug [string tolower [string trim $slug]]
  if {![regexp {^[a-z0-9](?:[a-z0-9-]{0,37}[a-z0-9])?$} $slug] ||
      [string first -- $slug] >= 0} {
    error "Repository name must use 1–39 letters, numbers, or single hyphens."
  }
  if {$slug in {account admin api assets catalog explore fossil healthz index \
      login logout new public register repo settings status}} {
    error "That repository name is reserved."
  }
  return $slug
}

proc ::fossilhub::repositories::validateTitle {title} {
  set title [string trim $title]
  if {$title eq "" || [string length $title] > 100 ||
      [string first "\u0000" $title] >= 0} {
    error "Repository title must use 1–100 characters."
  }
  return $title
}

proc ::fossilhub::repositories::validateDescription {description} {
  set description [string trim $description]
  if {[string length $description] > 500 ||
      [string first "\u0000" $description] >= 0} {
    error "Repository description must be no longer than 500 characters."
  }
  return $description
}

proc ::fossilhub::repositories::validateVisibility {visibility} {
  if {$visibility ni {public private}} {
    error "Repository visibility must be public or private."
  }
  return $visibility
}

proc ::fossilhub::repositories::validateBranch {branch} {
  set branch [string trim $branch]
  if {![regexp {^[A-Za-z0-9](?:[A-Za-z0-9._/-]{0,98}[A-Za-z0-9])?$} \
      $branch] || [string first .. $branch] >= 0 ||
      [string first // $branch] >= 0} {
    error "Default branch contains unsupported characters."
  }
  return $branch
}

proc ::fossilhub::repositories::fromRow {row} {
  lassign $row id slug fossilName title description sourceUrl category language \
    visibility state ownerUserId defaultBranch featured createdEpoch \
    updatedEpoch archivedEpoch
  return [dict create \
    id $id slug $slug name $fossilName title $title description $description \
    source_url $sourceUrl category $category language $language \
    visibility $visibility state $state owner_user_id $ownerUserId \
    default_branch $defaultBranch featured $featured \
    created_epoch $createdEpoch updated_epoch $updatedEpoch \
    archived_epoch $archivedEpoch]
}

proc ::fossilhub::repositories::selectColumns {{alias ""}} {
  if {$alias ne "" && ![regexp {^[a-z][a-z0-9_]*$} $alias]} {
    error "invalid repository query alias"
  }
  set prefix [expr {$alias eq "" ? "" : "${alias}."}]
  return [format {
    hex(%sid),hex(%sslug),hex(%sfossil_name),hex(%stitle),
    hex(%sdescription),hex(%ssource_url),hex(%scategory),hex(%slanguage),
    hex(%svisibility),hex(%sstate),hex(COALESCE(%sowner_user_id,'')),
    hex(%sdefault_branch),hex(CAST(%sfeatured AS TEXT)),
    hex(CAST(%screated_epoch AS TEXT)),hex(CAST(%supdated_epoch AS TEXT)),
    hex(CAST(%sarchived_epoch AS TEXT))
  } $prefix $prefix $prefix $prefix $prefix $prefix $prefix $prefix $prefix \
    $prefix $prefix $prefix $prefix $prefix $prefix $prefix]
}

proc ::fossilhub::repositories::byName {name} {
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s FROM repositories
     WHERE fossil_name=%s COLLATE NOCASE LIMIT 1;
  } [::fossilhub::repositories::selectColumns] \
    [::fossilhub::platform::textLiteral $name]] 16]
  if {[llength $rows] == 0} {
    return ""
  }
  return [::fossilhub::repositories::fromRow [lindex $rows 0]]
}

proc ::fossilhub::repositories::bySlug {slug} {
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s FROM repositories
     WHERE slug=%s COLLATE NOCASE LIMIT 1;
  } [::fossilhub::repositories::selectColumns] \
    [::fossilhub::platform::textLiteral $slug]] 16]
  if {[llength $rows] == 0} {
    return ""
  }
  return [::fossilhub::repositories::fromRow [lindex $rows 0]]
}

proc ::fossilhub::repositories::membershipRole {repositoryId userId} {
  if {$userId eq ""} {
    return ""
  }
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(role) FROM memberships
     WHERE repository_id=%s AND user_id=%s LIMIT 1;
  } [::fossilhub::platform::textLiteral $repositoryId] \
    [::fossilhub::platform::textLiteral $userId]] 1]
  if {[llength $rows] == 0} {
    return ""
  }
  return [lindex [lindex $rows 0] 0]
}

proc ::fossilhub::repositories::effectiveRole {repository context} {
  if {![dict get $context authenticated]} {
    return visitor
  }
  set user [dict get $context user]
  if {[dict get $user role] eq "administrator"} {
    return administrator
  }
  if {[dict get $repository owner_user_id] eq [dict get $user id]} {
    return owner
  }
  set role [::fossilhub::repositories::membershipRole \
    [dict get $repository id] [dict get $user id]]
  if {$role eq ""} {
    return visitor
  }
  return $role
}

proc ::fossilhub::repositories::roleRank {role} {
  set ranks [dict create visitor 0 reader 10 triage 20 writer 30 \
    maintainer 40 owner 50 administrator 60]
  if {![dict exists $ranks $role]} {
    return 0
  }
  return [dict get $ranks $role]
}

proc ::fossilhub::repositories::allows {repository context capability} {
  set role [::fossilhub::repositories::effectiveRole $repository $context]
  switch -- $capability {
    read {
      if {[dict get $repository state] ne "active"} {
        return 0
      }
      if {[dict get $repository visibility] eq "public"} {
        return 1
      }
      return [expr {[::fossilhub::repositories::roleRank $role] >= 10}]
    }
    triage {
      return [expr {[dict get $repository state] eq "active" &&
        [::fossilhub::repositories::roleRank $role] >= 20}]
    }
    write {
      return [expr {[dict get $repository state] eq "active" &&
        [::fossilhub::repositories::roleRank $role] >= 30}]
    }
    manage {
      return [expr {[::fossilhub::repositories::roleRank $role] >= 40}]
    }
    owner {
      return [expr {[::fossilhub::repositories::roleRank $role] >= 50}]
    }
  }
  return 0
}

proc ::fossilhub::repositories::forUser {userId} {
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s
      FROM repositories AS r
      LEFT JOIN memberships AS m
        ON m.repository_id=r.id AND m.user_id=%s
     WHERE r.owner_user_id=%s OR m.user_id IS NOT NULL
     ORDER BY r.updated_epoch DESC,r.slug COLLATE NOCASE;
  } [::fossilhub::repositories::selectColumns r] \
    [::fossilhub::platform::textLiteral $userId] \
    [::fossilhub::platform::textLiteral $userId]] 16]
  set result {}
  foreach row $rows {
    lappend result [::fossilhub::repositories::fromRow $row]
  }
  return $result
}

proc ::fossilhub::repositories::members {repositoryId} {
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(u.id),hex(u.username),hex(u.display_name),hex(m.role),
           hex(CAST(m.created_epoch AS TEXT))
      FROM memberships AS m
      JOIN users AS u ON u.id=m.user_id
     WHERE m.repository_id=%s
     ORDER BY CASE m.role WHEN 'owner' THEN 0 WHEN 'maintainer' THEN 1
              WHEN 'writer' THEN 2 WHEN 'triage' THEN 3 ELSE 4 END,
              u.username COLLATE NOCASE;
  } [::fossilhub::platform::textLiteral $repositoryId]] 5]
  set result {}
  foreach row $rows {
    lassign $row id username displayName role createdEpoch
    lappend result [dict create id $id username $username \
      display_name $displayName role $role created_epoch $createdEpoch]
  }
  return $result
}

proc ::fossilhub::repositories::runFossil {label arguments} {
  if {[catch {exec [::fossilhub::model::fossilBinary] --nocgi {*}$arguments}]} {
    error "FossilHub: $label failed; captured Fossil output was suppressed"
  }
}

proc ::fossilhub::repositories::lockRoot {} {
  if {[info exists ::env(FOSSILHUB_LOCK_DIR)] &&
      $::env(FOSSILHUB_LOCK_DIR) ne ""} {
    return [file normalize $::env(FOSSILHUB_LOCK_DIR)]
  }
  return [file normalize [file join \
    [file dirname [::fossilhub::model::repositoryRoot]] locks]]
}

proc ::fossilhub::repositories::quarantineRoot {} {
  if {[info exists ::env(FOSSILHUB_QUARANTINE_DIR)] &&
      $::env(FOSSILHUB_QUARANTINE_DIR) ne ""} {
    return [file normalize $::env(FOSSILHUB_QUARANTINE_DIR)]
  }
  return [file normalize [file join \
    [file dirname [::fossilhub::model::repositoryRoot]] quarantine]]
}

proc ::fossilhub::repositories::acquireLock {key} {
  if {![regexp {^[a-z0-9-]{1,80}$} $key]} {
    error "invalid repository lock"
  }
  set root [::fossilhub::repositories::lockRoot]
  file mkdir $root
  file attributes $root -permissions 0750
  set lock [file join $root "${key}.lock"]
  if {[catch {set channel [open $lock {WRONLY CREAT EXCL}]}]} {
    error "Repository is busy. Try again shortly."
  }
  try {
    puts $channel "[pid] [clock seconds]"
  } finally {
    close $channel
  }
  file attributes $lock -permissions 0600
  return $lock
}

proc ::fossilhub::repositories::releaseLock {lock} {
  set root [::fossilhub::repositories::lockRoot]
  set lock [file normalize $lock]
  if {[file dirname $lock] ne $root || ![file isfile $lock] ||
      [file extension $lock] ne ".lock"} {
    error "refusing to release an unknown repository lock"
  }
  file delete $lock
}

proc ::fossilhub::repositories::configureVisibility {repository visibility} {
  variable publicNobodyCapabilities
  variable publicAnonymousCapabilities
  if {$visibility eq "public"} {
    set nobody $publicNobodyCapabilities
    set anonymous $publicAnonymousCapabilities
  } else {
    set nobody ""
    set anonymous ""
  }
  ::fossilhub::repositories::runFossil {nobody capability update} [list \
    user capabilities nobody $nobody --repository $repository]
  ::fossilhub::repositories::runFossil {anonymous capability update} [list \
    user capabilities anonymous $anonymous --repository $repository]
}

proc ::fossilhub::repositories::create {owner slug title description visibility} {
  set slug [::fossilhub::repositories::validateSlug $slug]
  set title [::fossilhub::repositories::validateTitle $title]
  set description [::fossilhub::repositories::validateDescription $description]
  set visibility [::fossilhub::repositories::validateVisibility $visibility]
  set fossilName "${slug}.fossil"
  if {[::fossilhub::repositories::bySlug $slug] ne ""} {
    error "A repository with that name already exists."
  }
  set repositoryRoot [::fossilhub::model::repositoryRoot]
  file mkdir $repositoryRoot
  file attributes $repositoryRoot -permissions 0750
  set destination [::fossilhub::model::repositoryPath $fossilName]
  if {[file exists $destination]} {
    error "A repository file with that name already exists."
  }
  set lock [::fossilhub::repositories::acquireLock "create-$slug"]
  set temporary "${destination}.new.[pid].[clock clicks]"
  set published 0
  try {
    ::fossilhub::repositories::runFossil {repository initialization} [list \
      init --admin-user fossilhub --project-name $title \
      --project-desc $description $temporary]
    ::fossilhub::repositories::configureVisibility $temporary $visibility
    ::fossilhub::repositories::runFossil {administrator lockdown} [list \
      user capabilities fossilhub "" --repository $temporary]
    ::fossilhub::repositories::runFossil {autosync lockdown} [list \
      setting autosync off --repository $temporary]
    file attributes $temporary -permissions 0600
    file rename $temporary $destination
    set published 1

    set id [::fossilhub::auth::randomToken 16]
    set now [clock seconds]
    set sql [format {
      PRAGMA foreign_keys=ON;
      BEGIN IMMEDIATE;
      INSERT INTO repositories VALUES(
        %s,%s,%s,%s,%s,'','project','Not set',%s,'active',%s,'trunk',0,%d,%d,0
      );
      INSERT INTO memberships VALUES(%s,%s,'owner',%d,%d);
      INSERT INTO audit_events VALUES(%s,%s,%s,'repository.create',%s,'success','','',%d);
      COMMIT;
    } \
      [::fossilhub::platform::textLiteral $id] \
      [::fossilhub::platform::textLiteral $slug] \
      [::fossilhub::platform::textLiteral $fossilName] \
      [::fossilhub::platform::textLiteral $title] \
      [::fossilhub::platform::textLiteral $description] \
      [::fossilhub::platform::textLiteral $visibility] \
      [::fossilhub::platform::textLiteral [dict get $owner id]] $now $now \
      [::fossilhub::platform::textLiteral $id] \
      [::fossilhub::platform::textLiteral [dict get $owner id]] $now $now \
      [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
      [::fossilhub::platform::textLiteral [dict get $owner id]] \
      [::fossilhub::platform::textLiteral $id] \
      [::fossilhub::platform::textLiteral $slug] $now]
    ::fossilhub::platform::execute \
      [::fossilhub::platform::databasePath] $sql
    if {[catch {::fossilhub::catalog::rebuild}]} {
      ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
        "DELETE FROM repositories WHERE id=[::fossilhub::platform::textLiteral $id];"
      set quarantine [::fossilhub::repositories::quarantineRoot]
      file mkdir $quarantine
      file attributes $quarantine -permissions 0750
      file rename $destination [file join $quarantine \
        "failed-index-${id}-${fossilName}"]
      set published 0
      error "Repository catalogue update failed."
    }
    return [::fossilhub::repositories::byName $fossilName]
  } on error {message options} {
    if {[file exists $temporary]} {
      file delete -force $temporary
    }
    if {$published && [file exists $destination] &&
        [::fossilhub::repositories::byName $fossilName] eq ""} {
      set quarantine [::fossilhub::repositories::quarantineRoot]
      file mkdir $quarantine
      file attributes $quarantine -permissions 0750
      file rename $destination [file join $quarantine \
        "failed-create-[clock seconds]-${fossilName}"]
    }
    return -options $options $message
  } finally {
    ::fossilhub::repositories::releaseLock $lock
  }
}

proc ::fossilhub::repositories::updateSettings {repository title description \
    visibility defaultBranch actorId} {
  if {[dict get $repository state] ne "active"} {
    error "Archived repository settings cannot be changed."
  }
  set title [::fossilhub::repositories::validateTitle $title]
  set description [::fossilhub::repositories::validateDescription $description]
  set visibility [::fossilhub::repositories::validateVisibility $visibility]
  set defaultBranch [::fossilhub::repositories::validateBranch $defaultBranch]
  set repositoryPath [::fossilhub::model::repositoryPath \
    [dict get $repository name]]
  set lock [::fossilhub::repositories::acquireLock \
    "settings-[dict get $repository slug]"]
  set database [::fossilhub::platform::databasePath]
  set databaseUpdated 0
  set visibilityUpdated 0
  try {
    if {$visibility ne [dict get $repository visibility]} {
      ::fossilhub::repositories::configureVisibility $repositoryPath $visibility
      set visibilityUpdated 1
    }
    set now [clock seconds]
    set sql [format {
      PRAGMA foreign_keys=ON;
      BEGIN IMMEDIATE;
      UPDATE repositories
         SET title=%s,description=%s,visibility=%s,default_branch=%s,
             updated_epoch=%d
       WHERE id=%s AND state='active';
      COMMIT;
    } \
      [::fossilhub::platform::textLiteral $title] \
      [::fossilhub::platform::textLiteral $description] \
      [::fossilhub::platform::textLiteral $visibility] \
      [::fossilhub::platform::textLiteral $defaultBranch] $now \
      [::fossilhub::platform::textLiteral [dict get $repository id]]]
    ::fossilhub::platform::execute $database $sql
    set databaseUpdated 1
    ::fossilhub::catalog::rebuild
    ::fossilhub::auth::audit repository.settings success $actorId \
      [dict get $repository slug] [dict get $repository id]
  } on error {message options} {
    if {$databaseUpdated} {
      set rollbackSql [format {
        UPDATE repositories
           SET title=%s,description=%s,visibility=%s,default_branch=%s,
               updated_epoch=%d
         WHERE id=%s;
      } \
        [::fossilhub::platform::textLiteral [dict get $repository title]] \
        [::fossilhub::platform::textLiteral [dict get $repository description]] \
        [::fossilhub::platform::textLiteral [dict get $repository visibility]] \
        [::fossilhub::platform::textLiteral [dict get $repository default_branch]] \
        [dict get $repository updated_epoch] \
        [::fossilhub::platform::textLiteral [dict get $repository id]]]
      catch {::fossilhub::platform::execute $database $rollbackSql}
    }
    if {$visibilityUpdated} {
      catch {::fossilhub::repositories::configureVisibility $repositoryPath \
        [dict get $repository visibility]}
    }
    if {$databaseUpdated} {
      catch {::fossilhub::catalog::rebuild}
    }
    return -options $options $message
  } finally {
    ::fossilhub::repositories::releaseLock $lock
  }
  return [::fossilhub::repositories::byName [dict get $repository name]]
}

proc ::fossilhub::repositories::addMember {repository user role actorId} {
  if {[dict get $repository state] ne "active"} {
    error "Archived repository collaborators cannot be changed."
  }
  if {$role ni {reader triage writer maintainer}} {
    error "Collaborator role is invalid."
  }
  if {[dict get $repository owner_user_id] eq [dict get $user id]} {
    error "The repository owner already has full access."
  }
  set now [clock seconds]
  set sql [format {
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;
    INSERT INTO memberships VALUES(%s,%s,%s,%d,%d)
      ON CONFLICT(repository_id,user_id) DO UPDATE SET
        role=excluded.role,updated_epoch=excluded.updated_epoch;
    INSERT INTO audit_events VALUES(%s,%s,%s,'repository.member-set',%s,'success','','',%d);
    UPDATE repositories SET updated_epoch=%d WHERE id=%s;
    COMMIT;
  } \
    [::fossilhub::platform::textLiteral [dict get $repository id]] \
    [::fossilhub::platform::textLiteral [dict get $user id]] \
    [::fossilhub::platform::textLiteral $role] $now $now \
    [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
    [::fossilhub::platform::textLiteral $actorId] \
    [::fossilhub::platform::textLiteral [dict get $repository id]] \
    [::fossilhub::platform::textLiteral [dict get $user username]] $now \
    $now [::fossilhub::platform::textLiteral [dict get $repository id]]]
  ::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] $sql
  return 1
}

proc ::fossilhub::repositories::removeMember {repository userId actorId} {
  if {[dict get $repository state] ne "active"} {
    error "Archived repository collaborators cannot be changed."
  }
  if {$userId eq [dict get $repository owner_user_id]} {
    error "The repository owner cannot be removed."
  }
  if {[::fossilhub::repositories::membershipRole \
      [dict get $repository id] $userId] eq ""} {
    return 0
  }
  set now [clock seconds]
  set output [::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] [format {
      PRAGMA foreign_keys=ON;
      BEGIN IMMEDIATE;
      DELETE FROM memberships WHERE repository_id=%s AND user_id=%s;
      SELECT changes();
      INSERT INTO audit_events VALUES(%s,%s,%s,'repository.member-remove',%s,'success','','',%d);
      COMMIT;
    } \
      [::fossilhub::platform::textLiteral [dict get $repository id]] \
      [::fossilhub::platform::textLiteral $userId] \
      [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
      [::fossilhub::platform::textLiteral $actorId] \
      [::fossilhub::platform::textLiteral [dict get $repository id]] \
      [::fossilhub::platform::textLiteral $userId] $now]]
  expr {[lindex [split [string trim $output] "\n"] 0] eq "1"}
}

proc ::fossilhub::repositories::transfer {repository nextOwner actorId} {
  if {[dict get $repository state] ne "active"} {
    error "Archived repository ownership cannot be transferred."
  }
  set nextOwnerId [dict get $nextOwner id]
  set currentOwner [dict get $repository owner_user_id]
  if {$nextOwnerId eq $currentOwner} {
    error "That user already owns the repository."
  }
  set now [clock seconds]
  set sql [format {
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;
    UPDATE repositories SET owner_user_id=%s,updated_epoch=%d WHERE id=%s;
    INSERT INTO memberships VALUES(%s,%s,'owner',%d,%d)
      ON CONFLICT(repository_id,user_id) DO UPDATE SET
        role='owner',updated_epoch=excluded.updated_epoch;
    UPDATE memberships SET role='maintainer',updated_epoch=%d
      WHERE repository_id=%s AND user_id=%s;
    INSERT INTO audit_events VALUES(%s,%s,%s,'repository.transfer',%s,'success','','',%d);
    COMMIT;
  } \
    [::fossilhub::platform::textLiteral $nextOwnerId] $now \
    [::fossilhub::platform::textLiteral [dict get $repository id]] \
    [::fossilhub::platform::textLiteral [dict get $repository id]] \
    [::fossilhub::platform::textLiteral $nextOwnerId] $now $now $now \
    [::fossilhub::platform::textLiteral [dict get $repository id]] \
    [::fossilhub::platform::textLiteral $currentOwner] \
    [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
    [::fossilhub::platform::textLiteral $actorId] \
    [::fossilhub::platform::textLiteral [dict get $repository id]] \
    [::fossilhub::platform::textLiteral [dict get $nextOwner username]] $now]
  ::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] $sql
  return [::fossilhub::repositories::byName [dict get $repository name]]
}

proc ::fossilhub::repositories::archive {repository actorId} {
  if {[dict get $repository state] ne "active"} {
    error "Repository is not active."
  }
  set source [::fossilhub::model::repositoryPath [dict get $repository name]]
  if {![file isfile $source]} {
    error "Repository file is unavailable."
  }
  set lock [::fossilhub::repositories::acquireLock \
    "archive-[dict get $repository slug]"]
  set quarantine [::fossilhub::repositories::quarantineRoot]
  file mkdir $quarantine
  file attributes $quarantine -permissions 0750
  set archivedName "[dict get $repository id]-[dict get $repository name]"
  set destination [file join $quarantine $archivedName]
  if {[file exists $destination]} {
    ::fossilhub::repositories::releaseLock $lock
    error "Repository quarantine target already exists."
  }
  set database [::fossilhub::platform::databasePath]
  set databaseUpdated 0
  try {
    file rename $source $destination
    file attributes $destination -permissions 0600
    set now [clock seconds]
    ::fossilhub::platform::execute $database \
      [format {
        PRAGMA foreign_keys=ON;
        BEGIN IMMEDIATE;
        UPDATE repositories SET state='archived',archived_epoch=%d,
          updated_epoch=%d WHERE id=%s;
        COMMIT;
      } $now $now \
        [::fossilhub::platform::textLiteral [dict get $repository id]]]
    set databaseUpdated 1
    ::fossilhub::catalog::rebuild
    ::fossilhub::auth::audit repository.archive success $actorId \
      [dict get $repository slug] [dict get $repository id]
  } on error {message options} {
    if {$databaseUpdated} {
      set rollbackSql [format {
        UPDATE repositories SET state='active',archived_epoch=%d,
          updated_epoch=%d WHERE id=%s;
      } [dict get $repository archived_epoch] \
        [dict get $repository updated_epoch] \
        [::fossilhub::platform::textLiteral [dict get $repository id]]]
      catch {::fossilhub::platform::execute $database $rollbackSql}
    }
    if {[file isfile $destination] && ![file exists $source]} {
      file rename $destination $source
    }
    if {$databaseUpdated} {
      catch {::fossilhub::catalog::rebuild}
    }
    return -options $options $message
  } finally {
    ::fossilhub::repositories::releaseLock $lock
  }
  return 1
}

proc ::fossilhub::repositories::restore {repository actorId} {
  if {[dict get $repository state] ne "archived"} {
    error "Repository is not archived."
  }
  set source [file join [::fossilhub::repositories::quarantineRoot] \
    "[dict get $repository id]-[dict get $repository name]"]
  set destination [::fossilhub::model::repositoryPath [dict get $repository name]]
  if {![file isfile $source] || [file exists $destination]} {
    error "Repository cannot be restored from quarantine."
  }
  set lock [::fossilhub::repositories::acquireLock \
    "archive-[dict get $repository slug]"]
  set database [::fossilhub::platform::databasePath]
  set databaseUpdated 0
  try {
    file rename $source $destination
    file attributes $destination -permissions 0600
    set now [clock seconds]
    ::fossilhub::platform::execute $database \
      [format {
        PRAGMA foreign_keys=ON;
        BEGIN IMMEDIATE;
        UPDATE repositories SET state='active',archived_epoch=0,
          updated_epoch=%d WHERE id=%s;
        COMMIT;
      } $now [::fossilhub::platform::textLiteral [dict get $repository id]]]
    set databaseUpdated 1
    ::fossilhub::catalog::rebuild
    ::fossilhub::auth::audit repository.restore success $actorId \
      [dict get $repository slug] [dict get $repository id]
  } on error {message options} {
    if {$databaseUpdated} {
      set rollbackSql [format {
        UPDATE repositories SET state='archived',archived_epoch=%d,
          updated_epoch=%d WHERE id=%s;
      } [dict get $repository archived_epoch] \
        [dict get $repository updated_epoch] \
        [::fossilhub::platform::textLiteral [dict get $repository id]]]
      catch {::fossilhub::platform::execute $database $rollbackSql}
    }
    if {[file isfile $destination] && ![file exists $source]} {
      file rename $destination $source
    }
    if {$databaseUpdated} {
      catch {::fossilhub::catalog::rebuild}
    }
    return -options $options $message
  } finally {
    ::fossilhub::repositories::releaseLock $lock
  }
  return 1
}
