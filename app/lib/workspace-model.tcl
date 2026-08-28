namespace eval ::fossilhub::workspace {}

proc ::fossilhub::workspace::validateBiography {value} {
  set value [string trim $value]
  if {[string length $value] > 1000 ||
      [string first "\u0000" $value] >= 0} {
    error "Biography must be no longer than 1,000 characters."
  }
  return $value
}

proc ::fossilhub::workspace::validateLocation {value} {
  set value [string trim $value]
  if {[string length $value] > 100 ||
      [string first "\u0000" $value] >= 0} {
    error "Location must be no longer than 100 characters."
  }
  return $value
}

proc ::fossilhub::workspace::validateWebsite {value} {
  set value [string trim $value]
  if {$value eq ""} {
    return ""
  }
  if {[string length $value] > 240 ||
      ![regexp -nocase {^https://[^[:space:]]+$} $value]} {
    error "Website must be a valid HTTPS address."
  }
  return $value
}

proc ::fossilhub::workspace::updateProfile {userId values} {
  set displayName [::fossilhub::auth::validateDisplayName \
    [dict get $values display_name]]
  if {$displayName eq ""} {
    error "Display name is required."
  }
  set email [::fossilhub::auth::normalizeEmail [dict get $values email]]
  set biography [::fossilhub::workspace::validateBiography \
    [dict get $values biography]]
  set website [::fossilhub::workspace::validateWebsite \
    [dict get $values website]]
  set location [::fossilhub::workspace::validateLocation \
    [dict get $values location]]
  set now [clock seconds]
  set database [::fossilhub::platform::databasePath]
  set sql [format {
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;
    UPDATE users SET display_name=%s,email=%s,biography=%s,website=%s,
      location=%s,updated_epoch=%d WHERE id=%s AND status='active';
    INSERT INTO audit_events VALUES(%s,%s,NULL,'user.profile-update','',
      'success','','',%d);
    COMMIT;
  } \
    [::fossilhub::platform::textLiteral $displayName] \
    [::fossilhub::platform::textLiteral $email] \
    [::fossilhub::platform::textLiteral $biography] \
    [::fossilhub::platform::textLiteral $website] \
    [::fossilhub::platform::textLiteral $location] $now \
    [::fossilhub::platform::textLiteral $userId] \
    [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
    [::fossilhub::platform::textLiteral $userId] $now]
  ::fossilhub::platform::execute $database $sql
  return [::fossilhub::auth::userById $userId]
}

proc ::fossilhub::workspace::activityRows {whereSql {limit 20}} {
  set limit [expr {max(1,min(50,int($limit)))}]
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(a.action),hex(a.outcome),hex(a.target),
           hex(CAST(a.created_epoch AS TEXT)),hex(COALESCE(r.slug,'')),
           hex(COALESCE(r.title,''))
      FROM audit_events AS a
      LEFT JOIN repositories AS r ON r.id=a.repository_id
     WHERE %s
     ORDER BY a.created_epoch DESC,a.id DESC LIMIT %d;
  } $whereSql $limit] 6]
  set result {}
  foreach row $rows {
    lassign $row action outcome target epoch slug title
    lappend result [dict create action $action outcome $outcome target $target \
      epoch $epoch repository_slug $slug repository_title $title]
  }
  return $result
}

proc ::fossilhub::workspace::dashboard {userId} {
  set owned {}
  set collaborations {}
  set tickets {}
  foreach repository [::fossilhub::repositories::forUser $userId] {
    if {[dict get $repository owner_user_id] eq $userId} {
      lappend owned $repository
    } else {
      dict set repository membership_role \
        [::fossilhub::repositories::membershipRole \
          [dict get $repository id] $userId]
      lappend collaborations $repository
    }
    if {[dict get $repository state] ne "active"} {
      continue
    }
    if {[catch {set repositoryTickets [::fossilhub::model::tickets \
        [dict get $repository name] 25]}]} {
      continue
    }
    foreach ticket $repositoryTickets {
      if {[string tolower [dict get $ticket status]] in \
          {closed fixed resolved rejected}} {
        continue
      }
      dict set ticket repository_slug [dict get $repository slug]
      dict set ticket repository_title [dict get $repository title]
      lappend tickets $ticket
      if {[llength $tickets] >= 30} {
        break
      }
    }
  }
  set userLiteral [::fossilhub::platform::textLiteral $userId]
  set activity [::fossilhub::workspace::activityRows \
    "a.actor_user_id=$userLiteral" 20]
  return [dict create owned $owned collaborations $collaborations \
    activity $activity tickets $tickets]
}

proc ::fossilhub::workspace::publicProfile {username} {
  set user [::fossilhub::auth::userByUsername $username]
  if {$user eq ""} {
    return ""
  }
  set userId [dict get $user id]
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s FROM repositories
     WHERE owner_user_id=%s AND visibility='public' AND state='active'
     ORDER BY updated_epoch DESC,slug COLLATE NOCASE LIMIT 100;
  } [::fossilhub::repositories::selectColumns] \
    [::fossilhub::platform::textLiteral $userId]] 16]
  set repositories {}
  foreach row $rows {
    lappend repositories [::fossilhub::repositories::fromRow $row]
  }
  set activity [::fossilhub::workspace::activityRows [format {
    a.actor_user_id=%s AND r.visibility='public' AND r.state='active'
  } [::fossilhub::platform::textLiteral $userId]] 20]
  return [dict create user $user repositories $repositories activity $activity]
}

proc ::fossilhub::workspace::deactivate {userId password} {
  set user [::fossilhub::auth::userById $userId]
  if {$user eq "" || [dict get $user status] ne "active"} {
    error "Account is unavailable."
  }
  set credential [::fossilhub::auth::userWithCredential \
    [dict get $user username]]
  if {$credential eq "" || ![::fossilhub::auth::verifyPassword \
      $password [dict get $credential password_hash]]} {
    error "Current password is incorrect."
  }
  if {[dict get $user role] eq "administrator" &&
      [::fossilhub::auth::administratorCount] <= 1} {
    error "The last active administrator cannot deactivate their account."
  }
  set now [clock seconds]
  set sql [format {
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;
    DELETE FROM sessions WHERE user_id=%s;
    UPDATE users SET status='deactivated',updated_epoch=%d WHERE id=%s;
    INSERT INTO audit_events VALUES(%s,%s,NULL,'user.deactivate','',
      'success','','',%d);
    COMMIT;
  } \
    [::fossilhub::platform::textLiteral $userId] $now \
    [::fossilhub::platform::textLiteral $userId] \
    [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
    [::fossilhub::platform::textLiteral $userId] $now]
  ::fossilhub::platform::execute [::fossilhub::platform::databasePath] $sql
  return 1
}
