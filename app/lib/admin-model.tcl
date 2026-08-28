namespace eval ::fossilhub::admin {}

proc ::fossilhub::admin::searchPattern {value} {
  set value [string trim [string map [list \u0000 ""] $value]]
  set value [string range $value 0 120]
  return [string map [list \\ \\\\ % \\% _ \\_] $value]
}

proc ::fossilhub::admin::overview {} {
  set rows [::fossilhub::platform::sqlRows {
    SELECT hex(CAST((SELECT COUNT(*) FROM users) AS TEXT)),
           hex(CAST((SELECT COUNT(*) FROM users WHERE status='active') AS TEXT)),
           hex(CAST((SELECT COUNT(*) FROM users WHERE status!='active') AS TEXT)),
           hex(CAST((SELECT COUNT(*) FROM repositories) AS TEXT)),
           hex(CAST((SELECT COUNT(*) FROM repositories WHERE state='active') AS TEXT)),
           hex(CAST((SELECT COUNT(*) FROM repositories WHERE state!='active') AS TEXT)),
           hex(CAST((SELECT COUNT(*) FROM audit_events
             WHERE created_epoch>=CAST(strftime('%s','now') AS INTEGER)-86400) AS TEXT)),
           hex(CAST((SELECT COUNT(*) FROM audit_events
             WHERE outcome='failure' AND
             created_epoch>=CAST(strftime('%s','now') AS INTEGER)-86400) AS TEXT));
  } 8]
  if {[llength $rows] == 0} {
    set counts [lrepeat 8 0]
  } else {
    set counts [lindex $rows 0]
  }
  lassign $counts users activeUsers inactiveUsers repositories \
    activeRepositories inactiveRepositories activity failures
  set storageBytes 0
  set readable 0
  foreach repository [::fossilhub::admin::repositories "" all all 10000] {
    if {[dict get $repository state] ne "active"} {
      continue
    }
    set path [::fossilhub::model::repositoryPath [dict get $repository name]]
    if {[file isfile $path] && [file readable $path]} {
      incr readable
      incr storageBytes [file size $path]
    }
  }
  return [dict create users $users active_users $activeUsers \
    inactive_users $inactiveUsers repositories $repositories \
    active_repositories $activeRepositories \
    inactive_repositories $inactiveRepositories activity_24h $activity \
    failures_24h $failures storage_bytes $storageBytes \
    readable_repositories $readable]
}

proc ::fossilhub::admin::users {{query ""} {status all} {role all} {limit 200}} {
  set limit [expr {max(1,min(500,int($limit)))}]
  set where {1=1}
  set pattern [::fossilhub::admin::searchPattern $query]
  if {$pattern ne ""} {
    append where [format { AND lower(u.username || ' ' || u.email || ' ' ||
      u.display_name) LIKE '%%' || lower(%s) || '%%' ESCAPE '\'} \
      [::fossilhub::platform::textLiteral $pattern]]
  }
  if {$status in {active disabled deactivated}} {
    append where " AND u.status=[::fossilhub::platform::textLiteral $status]"
  }
  if {$role in {user administrator}} {
    append where " AND u.role=[::fossilhub::platform::textLiteral $role]"
  }
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s,
      hex(CAST((SELECT COUNT(*) FROM repositories r
        WHERE r.owner_user_id=u.id) AS TEXT)),
      hex(CAST((SELECT COUNT(*) FROM sessions s
        WHERE s.user_id=u.id) AS TEXT))
      FROM users AS u WHERE %s
     ORDER BY u.updated_epoch DESC,u.username COLLATE NOCASE LIMIT %d;
  } [::fossilhub::auth::userSelect] $where $limit] 15]
  set result {}
  foreach row $rows {
    set user [::fossilhub::auth::userFromRow [lrange $row 0 12]]
    dict set user repository_count [lindex $row 13]
    dict set user session_count [lindex $row 14]
    lappend result $user
  }
  return $result
}

proc ::fossilhub::admin::userDetail {id} {
  set user [::fossilhub::auth::userById $id]
  if {$user eq ""} {
    return ""
  }
  dict set user repositories [::fossilhub::repositories::forUser $id]
  dict set user sessions [::fossilhub::auth::sessionsForUser $id]
  dict set user activity [::fossilhub::workspace::activityRows \
    "a.actor_user_id=[::fossilhub::platform::textLiteral $id]" 30]
  return $user
}

proc ::fossilhub::admin::changeUserRole {actorId targetId role} {
  if {$role ni {user administrator}} {
    error "User role is invalid."
  }
  set target [::fossilhub::auth::userById $targetId]
  if {$target eq ""} {
    error "User was not found."
  }
  if {[dict get $target role] eq "administrator" && $role eq "user" &&
      [dict get $target status] eq "active" &&
      [::fossilhub::auth::administratorCount] <= 1} {
    error "The last active administrator cannot be demoted."
  }
  set now [clock seconds]
  ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
    [format {
      PRAGMA foreign_keys=ON;
      BEGIN IMMEDIATE;
      UPDATE users SET role=%s,updated_epoch=%d WHERE id=%s;
      INSERT INTO audit_events VALUES(%s,%s,NULL,'admin.user-role',%s,
        'success','','',%d);
      COMMIT;
    } [::fossilhub::platform::textLiteral $role] $now \
      [::fossilhub::platform::textLiteral $targetId] \
      [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
      [::fossilhub::platform::textLiteral $actorId] \
      [::fossilhub::platform::textLiteral [dict get $target username]] $now]
  return [::fossilhub::auth::userById $targetId]
}

proc ::fossilhub::admin::changeUserStatus {actorId targetId status} {
  if {$status ni {active disabled}} {
    error "User status is invalid."
  }
  set target [::fossilhub::auth::userById $targetId]
  if {$target eq ""} {
    error "User was not found."
  }
  if {$status eq "disabled" && [dict get $target role] eq "administrator" &&
      [dict get $target status] eq "active" &&
      [::fossilhub::auth::administratorCount] <= 1} {
    error "The last active administrator cannot be disabled."
  }
  set now [clock seconds]
  set revoke [expr {$status eq "active" ? "" :
    "DELETE FROM sessions WHERE user_id=[::fossilhub::platform::textLiteral $targetId];"}]
  ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
    [format {
      PRAGMA foreign_keys=ON;
      BEGIN IMMEDIATE;
      %s
      UPDATE users SET status=%s,updated_epoch=%d WHERE id=%s;
      INSERT INTO audit_events VALUES(%s,%s,NULL,'admin.user-status',%s,
        'success','','',%d);
      COMMIT;
    } $revoke [::fossilhub::platform::textLiteral $status] $now \
      [::fossilhub::platform::textLiteral $targetId] \
      [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
      [::fossilhub::platform::textLiteral $actorId] \
      [::fossilhub::platform::textLiteral [dict get $target username]] $now]
  return [::fossilhub::auth::userById $targetId]
}

proc ::fossilhub::admin::revokeUserSessions {actorId targetId} {
  set target [::fossilhub::auth::userById $targetId]
  if {$target eq ""} {
    error "User was not found."
  }
  set output [::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] [format {
      BEGIN IMMEDIATE;
      DELETE FROM sessions WHERE user_id=%s;
      SELECT changes();
      COMMIT;
    } [::fossilhub::platform::textLiteral $targetId]]]
  ::fossilhub::auth::audit admin.user-session-revoke success $actorId \
    [dict get $target username]
  return [string trim $output]
}

proc ::fossilhub::admin::repositories {{query ""} {state all} \
    {visibility all} {limit 200}} {
  set limit [expr {max(1,min(10000,int($limit)))}]
  set where {1=1}
  set pattern [::fossilhub::admin::searchPattern $query]
  if {$pattern ne ""} {
    append where [format { AND lower(r.slug || ' ' || r.title || ' ' ||
      r.description || ' ' || COALESCE(u.username,''))
      LIKE '%%' || lower(%s) || '%%' ESCAPE '\'} \
      [::fossilhub::platform::textLiteral $pattern]]
  }
  if {$state in {active archived quarantined}} {
    append where " AND r.state=[::fossilhub::platform::textLiteral $state]"
  }
  if {$visibility in {public private}} {
    append where " AND r.visibility=[::fossilhub::platform::textLiteral $visibility]"
  }
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s,hex(COALESCE(u.username,'')),hex(COALESCE(u.display_name,''))
      FROM repositories AS r
      LEFT JOIN users AS u ON u.id=r.owner_user_id
     WHERE %s ORDER BY r.updated_epoch DESC,r.slug COLLATE NOCASE LIMIT %d;
  } [::fossilhub::repositories::selectColumns r] $where $limit] 18]
  set result {}
  foreach row $rows {
    set repository [::fossilhub::repositories::fromRow [lrange $row 0 15]]
    dict set repository owner_username [lindex $row 16]
    dict set repository owner_display_name [lindex $row 17]
    lappend result $repository
  }
  return $result
}

proc ::fossilhub::admin::repositoryDetail {slug} {
  if {[catch {set slug [::fossilhub::repositories::validateSlug $slug]}]} {
    return ""
  }
  set repositories [::fossilhub::admin::repositories $slug all all 20]
  foreach repository $repositories {
    if {[dict get $repository slug] eq $slug} {
      return $repository
    }
  }
  return ""
}

proc ::fossilhub::admin::auditEvents {{query ""} {outcome all} \
    {action ""} {limit 200}} {
  set limit [expr {max(1,min(1000,int($limit)))}]
  set where {1=1}
  set pattern [::fossilhub::admin::searchPattern $query]
  if {$pattern ne ""} {
    append where [format { AND lower(a.action || ' ' || a.target || ' ' ||
      COALESCE(u.username,'') || ' ' || COALESCE(r.slug,''))
      LIKE '%%' || lower(%s) || '%%' ESCAPE '\'} \
      [::fossilhub::platform::textLiteral $pattern]]
  }
  if {$outcome in {success denied failure}} {
    append where " AND a.outcome=[::fossilhub::platform::textLiteral $outcome]"
  }
  set action [string trim [string range $action 0 100]]
  if {$action ne "" && [regexp {^[a-z0-9._-]+$} $action]} {
    append where " AND a.action=[::fossilhub::platform::textLiteral $action]"
  }
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(a.id),hex(a.action),hex(a.outcome),
           hex(CAST(a.created_epoch AS TEXT)),hex(COALESCE(u.username,'')),
           hex(COALESCE(r.slug,''))
      FROM audit_events AS a
      LEFT JOIN users AS u ON u.id=a.actor_user_id
      LEFT JOIN repositories AS r ON r.id=a.repository_id
     WHERE %s ORDER BY a.created_epoch DESC,a.id DESC LIMIT %d;
  } $where $limit] 6]
  set result {}
  foreach row $rows {
    lassign $row id eventAction eventOutcome epoch username slug
    lappend result [dict create id $id action $eventAction \
      outcome $eventOutcome epoch $epoch actor $username \
      repository_slug $slug]
  }
  return $result
}

proc ::fossilhub::admin::settings {} {
  return [dict create \
    registration [::fossilhub::platform::setting registration closed] \
    default_visibility [::fossilhub::platform::setting \
      default_visibility public] \
    repositories_per_user [::fossilhub::platform::setting \
      repositories_per_user 100] \
    repository_quota_mb [::fossilhub::platform::setting \
      repository_quota_mb 512] \
    maintenance_banner [::fossilhub::platform::setting maintenance_banner ""]]
}

proc ::fossilhub::admin::updateSettings {actorId values} {
  set registration [dict get $values registration]
  set visibility [dict get $values default_visibility]
  set repositoryLimit [dict get $values repositories_per_user]
  set quota [dict get $values repository_quota_mb]
  set banner [string trim [dict get $values maintenance_banner]]
  if {$registration ni {open closed}} {
    error "Registration policy is invalid."
  }
  if {$visibility ni {public private}} {
    error "Default visibility is invalid."
  }
  if {![string is integer -strict $repositoryLimit] ||
      $repositoryLimit < 1 || $repositoryLimit > 10000} {
    error "Repository account limit must be between 1 and 10,000."
  }
  if {![string is integer -strict $quota] || $quota < 16 || $quota > 1048576} {
    error "Repository quota must be between 16 and 1,048,576 MiB."
  }
  if {[string length $banner] > 240 || [string first \u0000 $banner] >= 0} {
    error "Maintenance banner must be no longer than 240 characters."
  }
  set now [clock seconds]
  set sql "PRAGMA foreign_keys=ON;\nBEGIN IMMEDIATE;\n"
  foreach {key value} [list registration $registration \
      default_visibility $visibility repositories_per_user $repositoryLimit \
      repository_quota_mb $quota maintenance_banner $banner] {
    append sql [format {INSERT INTO settings VALUES(%s,%s,%d)
      ON CONFLICT(key) DO UPDATE SET value=excluded.value,
        updated_epoch=excluded.updated_epoch;
} [::fossilhub::platform::textLiteral $key] \
      [::fossilhub::platform::textLiteral $value] $now]
  }
  append sql [format {
    INSERT INTO audit_events VALUES(%s,%s,NULL,'admin.settings','',
      'success','','',%d);
    COMMIT;
  } [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
    [::fossilhub::platform::textLiteral $actorId] $now]
  ::fossilhub::platform::execute [::fossilhub::platform::databasePath] $sql
  return [::fossilhub::admin::settings]
}

proc ::fossilhub::admin::databaseHealth {path sqlite} {
  if {![file isfile $path]} {
    return missing
  }
  if {[catch {set result [exec $sqlite -readonly -batch -noheader \
      $path {PRAGMA quick_check;}]}] || [string trim $result] ne "ok"} {
    return failure
  }
  return ok
}

proc ::fossilhub::admin::health {} {
  set platformPath [::fossilhub::platform::databasePath]
  set catalogPath [::fossilhub::catalog::databasePath]
  set platformStatus [::fossilhub::admin::databaseHealth $platformPath \
    [::fossilhub::platform::sqliteBinary]]
  set catalogStatus [::fossilhub::admin::databaseHealth $catalogPath \
    [::fossilhub::catalog::sqliteBinary]]
  set total 0
  set readable 0
  set modeOk 1
  set ownershipOk 1
  set storageBytes 0
  foreach repository [::fossilhub::admin::repositories "" active all 10000] {
    incr total
    set path [::fossilhub::model::repositoryPath [dict get $repository name]]
    if {[file isfile $path] && [file readable $path]} {
      incr readable
      incr storageBytes [file size $path]
      if {([file attributes $path -permissions] & 0o777) != 0o600} {
        set modeOk 0
      }
      if {[file attributes $path -owner] ni {fossilhub 10001}} {
        set ownershipOk 0
      }
    } else {
      set modeOk 0
      set ownershipOk 0
    }
  }
  foreach path [list $platformPath $catalogPath] {
    if {[file isfile $path]} {
      if {([file attributes $path -permissions] & 0o777) != 0o600} {
        set modeOk 0
      }
      if {[file attributes $path -owner] ni {fossilhub 10001}} {
        set ownershipOk 0
      }
    }
  }
  set indexedEpoch 0
  if {$catalogStatus eq "ok"} {
    set rows [::fossilhub::catalog::sqlRows {
      SELECT hex(CAST(COALESCE(MAX(indexed_epoch),0) AS TEXT))
        FROM repositories;
    } 1]
    if {[llength $rows]} {
      set indexedEpoch [lindex [lindex $rows 0] 0]
    }
  }
  set revision unknown
  if {[info exists ::env(FOSSILHUB_REVISION)] &&
      [regexp {^[A-Za-z0-9._-]{1,80}$} $::env(FOSSILHUB_REVISION)]} {
    set revision $::env(FOSSILHUB_REVISION)
  }
  set quotaMb [::fossilhub::platform::setting repository_quota_mb 512]
  if {![string is wideinteger -strict $quotaMb] || $quotaMb < 1} {
    set quotaMb 512
  }
  set capacityBytes [expr {max(1,$total) * $quotaMb * 1048576}]
  set storageStatus [expr {$storageBytes * 100 >= $capacityBytes * 80 ?
    "warning" : "ok"}]
  return [dict create platform_database $platformStatus \
    catalogue_database $catalogStatus repository_count $total \
    readable_repositories $readable file_modes_ok $modeOk \
    file_ownership_ok $ownershipOk catalogue_indexed_epoch $indexedEpoch \
    storage_bytes $storageBytes storage_capacity_bytes $capacityBytes \
    storage_status $storageStatus revision $revision]
}

proc ::fossilhub::admin::rebuildCatalogue {actorId} {
  if {[catch {set count [::fossilhub::catalog::rebuild]}]} {
    ::fossilhub::auth::audit admin.catalogue-reindex failure $actorId
    error "Catalogue reindex failed."
  }
  ::fossilhub::auth::audit admin.catalogue-reindex success $actorId
  return $count
}

proc ::fossilhub::admin::checkRepositoryIntegrity {repository actorId} {
  if {[dict get $repository state] ne "active"} {
    error "Only an active repository can be checked."
  }
  set path [::fossilhub::model::repositoryPath [dict get $repository name]]
  if {![file isfile $path]} {
    ::fossilhub::auth::audit admin.repository-integrity failure $actorId \
      [dict get $repository slug] [dict get $repository id]
    error "Repository file is unavailable."
  }
  if {[catch {exec [::fossilhub::model::fossilBinary] --nocgi \
      test-integrity --quick $path}]} {
    ::fossilhub::auth::audit admin.repository-integrity failure $actorId \
      [dict get $repository slug] [dict get $repository id]
    ::fossilhub::repositories::quarantine $repository $actorId integrity
    error "Repository integrity failed and the repository was quarantined."
  }
  ::fossilhub::auth::audit admin.repository-integrity success $actorId \
    [dict get $repository slug] [dict get $repository id]
  return 1
}
