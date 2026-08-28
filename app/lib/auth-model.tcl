namespace eval ::fossilhub::auth {
  variable defaultArgon2 /usr/bin/argon2
  variable defaultOpenSsl /usr/bin/openssl
  variable idleSeconds 1800
  variable absoluteSeconds 604800
  variable challengeSeconds 900
  variable loginWindowSeconds 900
  variable loginLimit 5
}

proc ::fossilhub::auth::argon2Binary {} {
  variable defaultArgon2
  if {[info exists ::env(FOSSILHUB_ARGON2)] &&
      $::env(FOSSILHUB_ARGON2) ne ""} {
    return $::env(FOSSILHUB_ARGON2)
  }
  return $defaultArgon2
}

proc ::fossilhub::auth::opensslBinary {} {
  variable defaultOpenSsl
  if {[info exists ::env(FOSSILHUB_OPENSSL)] &&
      $::env(FOSSILHUB_OPENSSL) ne ""} {
    return $::env(FOSSILHUB_OPENSSL)
  }
  return $defaultOpenSsl
}

proc ::fossilhub::auth::randomBytes {count} {
  if {![string is integer -strict $count] || $count < 16 || $count > 128} {
    error "invalid random byte count"
  }
  set channel [open /dev/urandom rb]
  fconfigure $channel -translation binary
  try {
    set bytes [read $channel $count]
  } finally {
    close $channel
  }
  if {[string length $bytes] != $count} {
    error "secure random source returned too few bytes"
  }
  return $bytes
}

proc ::fossilhub::auth::randomToken {{count 32}} {
  binary encode hex [::fossilhub::auth::randomBytes $count]
}

proc ::fossilhub::auth::sha256 {value} {
  set binary [::fossilhub::auth::opensslBinary]
  if {![file executable $binary]} {
    error "password support is unavailable"
  }
  set output [string trim [exec $binary dgst -sha256 -r << $value]]
  if {![regexp {^([[:xdigit:]]{64})(?:[[:space:]]|$)} $output -> digest]} {
    error "secure hash command returned an invalid result"
  }
  return [string tolower $digest]
}

proc ::fossilhub::auth::constantTimeEqual {left right} {
  set leftBytes [encoding convertto utf-8 $left]
  set rightBytes [encoding convertto utf-8 $right]
  binary scan $leftBytes cu* leftValues
  binary scan $rightBytes cu* rightValues
  set leftLength [llength $leftValues]
  set rightLength [llength $rightValues]
  set count [expr {max($leftLength,$rightLength)}]
  set difference [expr {$leftLength ^ $rightLength}]
  for {set index 0} {$index < $count} {incr index} {
    set leftValue 0
    set rightValue 0
    if {$index < $leftLength} {
      set leftValue [lindex $leftValues $index]
    }
    if {$index < $rightLength} {
      set rightValue [lindex $rightValues $index]
    }
    set difference [expr {$difference | ($leftValue ^ $rightValue)}]
  }
  expr {$difference == 0}
}

proc ::fossilhub::auth::validatePassword {password} {
  set length [string length [encoding convertto utf-8 $password]]
  if {$length < 12} {
    error "Password must be at least 12 characters."
  }
  if {$length > 1024} {
    error "Password must be no longer than 1,024 bytes."
  }
  if {[string first "\u0000" $password] >= 0} {
    error "Password contains an unsupported character."
  }
  return $password
}

proc ::fossilhub::auth::passwordHash {password} {
  ::fossilhub::auth::validatePassword $password
  set binary [::fossilhub::auth::argon2Binary]
  if {![file executable $binary]} {
    error "password support is unavailable"
  }
  set salt [::fossilhub::auth::randomToken 16]
  if {[catch {
    set encoded [string trim [exec $binary $salt \
      -id -t 2 -m 15 -p 1 -l 32 -e << $password]]
  }]} {
    error "password hashing failed"
  }
  if {![regexp {^\$argon2id\$v=19\$m=32768,t=2,p=1\$[A-Za-z0-9+/]+\$[A-Za-z0-9+/]+$} \
      $encoded]} {
    error "password hashing returned an invalid result"
  }
  return $encoded
}

proc ::fossilhub::auth::passwordParameters {encoded} {
  if {![regexp {^\$argon2id\$v=19\$m=([0-9]+),t=([0-9]+),p=([0-9]+)\$([A-Za-z0-9+/]+)\$([A-Za-z0-9+/]+)$} \
      $encoded -> memory iterations parallelism encodedSalt encodedDigest]} {
    error "unsupported password hash"
  }
  foreach value [list $memory $iterations $parallelism] {
    if {![string is integer -strict $value]} {
      error "invalid password hash parameters"
    }
  }
  if {$memory < 19456 || $memory > 262144 ||
      $iterations < 1 || $iterations > 10 ||
      $parallelism < 1 || $parallelism > 4} {
    error "password hash parameters are outside policy"
  }
  set exponent 0
  set memoryValue 1
  while {$memoryValue < $memory && $exponent < 30} {
    set memoryValue [expr {$memoryValue * 2}]
    incr exponent
  }
  if {$memoryValue != $memory} {
    error "password hash memory is unsupported"
  }
  if {[catch {set salt [binary decode base64 $encodedSalt]}] ||
      ![regexp {^[[:xdigit:]]{32}$} $salt]} {
    error "password hash salt is invalid"
  }
  if {[catch {set digest [binary decode base64 $encodedDigest]}] ||
      [string length $digest] < 16 || [string length $digest] > 64} {
    error "password hash digest is invalid"
  }
  return [dict create \
    memory_exponent $exponent iterations $iterations \
    parallelism $parallelism length [string length $digest] salt $salt]
}

proc ::fossilhub::auth::verifyPassword {password encoded} {
  if {[catch {
    set parameters [::fossilhub::auth::passwordParameters $encoded]
    set calculated [string trim [exec [::fossilhub::auth::argon2Binary] \
      [dict get $parameters salt] -id \
      -t [dict get $parameters iterations] \
      -m [dict get $parameters memory_exponent] \
      -p [dict get $parameters parallelism] \
      -l [dict get $parameters length] -e << $password]]
  }]} {
    return 0
  }
  return [::fossilhub::auth::constantTimeEqual $calculated $encoded]
}

proc ::fossilhub::auth::normalizeUsername {username} {
  set username [string tolower [string trim $username]]
  if {![regexp {^[a-z0-9](?:[a-z0-9-]{0,37}[a-z0-9])?$} $username] ||
      [string first -- $username] >= 0} {
    error "Username must use 1–39 letters, numbers, or single hyphens."
  }
  if {$username in {anonymous nobody fossilhub fossilhub-admin admin root}} {
    error "That username is reserved."
  }
  return $username
}

proc ::fossilhub::auth::normalizeEmail {email} {
  set email [string tolower [string trim $email]]
  if {[string length [encoding convertto utf-8 $email]] > 254 ||
      ![regexp {^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$} $email]} {
    error "Enter a valid email address."
  }
  return $email
}

proc ::fossilhub::auth::validateDisplayName {displayName} {
  set displayName [string trim $displayName]
  if {[string length $displayName] > 80 ||
      [string first "\u0000" $displayName] >= 0} {
    error "Display name must be no longer than 80 characters."
  }
  return $displayName
}

proc ::fossilhub::auth::userFromRow {row} {
  lassign $row id username email displayName biography website location \
    role status createdEpoch updatedEpoch lastLoginEpoch mustChangePassword
  return [dict create \
    id $id username $username email $email display_name $displayName \
    biography $biography website $website location $location role $role \
    status $status created_epoch $createdEpoch updated_epoch $updatedEpoch \
    last_login_epoch $lastLoginEpoch must_change_password $mustChangePassword]
}

proc ::fossilhub::auth::userSelect {} {
  return {
    hex(u.id),hex(u.username),hex(u.email),hex(u.display_name),hex(u.biography),
    hex(u.website),hex(u.location),hex(u.role),hex(u.status),
    hex(CAST(u.created_epoch AS TEXT)),hex(CAST(u.updated_epoch AS TEXT)),
    hex(CAST(u.last_login_epoch AS TEXT)),
    hex(CAST(u.must_change_password AS TEXT))
  }
}

proc ::fossilhub::auth::userById {id} {
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s FROM users AS u WHERE u.id=%s LIMIT 1;
  } [::fossilhub::auth::userSelect] \
    [::fossilhub::platform::textLiteral $id]] 13]
  if {[llength $rows] == 0} {
    return ""
  }
  return [::fossilhub::auth::userFromRow [lindex $rows 0]]
}

proc ::fossilhub::auth::userByUsername {username} {
  set username [string tolower [string trim $username]]
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s FROM users AS u
     WHERE u.username=%s COLLATE NOCASE AND u.status='active' LIMIT 1;
  } [::fossilhub::auth::userSelect] \
    [::fossilhub::platform::textLiteral $username]] 13]
  if {[llength $rows] == 0} {
    return ""
  }
  return [::fossilhub::auth::userFromRow [lindex $rows 0]]
}

proc ::fossilhub::auth::userWithCredential {login} {
  set login [string tolower [string trim $login]]
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT %s,hex(c.password_hash)
      FROM users AS u
      JOIN credentials AS c ON c.user_id=u.id
     WHERE u.username=%s COLLATE NOCASE OR u.email=%s COLLATE NOCASE
     LIMIT 1;
  } [::fossilhub::auth::userSelect] \
    [::fossilhub::platform::textLiteral $login] \
    [::fossilhub::platform::textLiteral $login]] 14]
  if {[llength $rows] == 0} {
    return ""
  }
  set row [lindex $rows 0]
  set user [::fossilhub::auth::userFromRow [lrange $row 0 12]]
  dict set user password_hash [lindex $row 13]
  return $user
}

proc ::fossilhub::auth::audit {action outcome {actorId ""} \
    {target ""} {repositoryId ""} {requestId ""} {detail ""}} {
  if {$outcome ni {success denied failure}} {
    error "invalid audit outcome"
  }
  set id [::fossilhub::auth::randomToken 16]
  set actor [expr {$actorId eq "" ? "NULL" :
    [::fossilhub::platform::textLiteral $actorId]}]
  set repository [expr {$repositoryId eq "" ? "NULL" :
    [::fossilhub::platform::textLiteral $repositoryId]}]
  set sql [format {
    PRAGMA foreign_keys=ON;
    INSERT INTO audit_events VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%d);
  } \
    [::fossilhub::platform::textLiteral $id] $actor $repository \
    [::fossilhub::platform::textLiteral $action] \
    [::fossilhub::platform::textLiteral $target] \
    [::fossilhub::platform::textLiteral $outcome] \
    [::fossilhub::platform::textLiteral $requestId] \
    [::fossilhub::platform::textLiteral $detail] [clock seconds]]
  ::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] $sql
  return $id
}

proc ::fossilhub::auth::createUser {username email password \
    {displayName ""} {role user} {mustChangePassword 0}} {
  set username [::fossilhub::auth::normalizeUsername $username]
  set email [::fossilhub::auth::normalizeEmail $email]
  set displayName [::fossilhub::auth::validateDisplayName $displayName]
  if {$displayName eq ""} {
    set displayName $username
  }
  if {$role ni {user administrator}} {
    error "invalid platform role"
  }
  if {$mustChangePassword ni {0 1}} {
    error "invalid forced password change state"
  }
  set passwordHash [::fossilhub::auth::passwordHash $password]
  set id [::fossilhub::auth::randomToken 16]
  set now [clock seconds]
  set sql [format {
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;
    INSERT INTO users(
      id,username,email,display_name,biography,website,location,role,status,
      created_epoch,updated_epoch,last_login_epoch,must_change_password
    ) VALUES(%s,%s,%s,%s,'','','',%s,'active',%d,%d,0,%d);
    INSERT INTO credentials VALUES(%s,%s,%d);
    INSERT INTO audit_events VALUES(%s,%s,NULL,'user.register',%s,'success','','',%d);
    COMMIT;
  } \
    [::fossilhub::platform::textLiteral $id] \
    [::fossilhub::platform::textLiteral $username] \
    [::fossilhub::platform::textLiteral $email] \
    [::fossilhub::platform::textLiteral $displayName] \
    [::fossilhub::platform::textLiteral $role] $now $now $mustChangePassword \
    [::fossilhub::platform::textLiteral $id] \
    [::fossilhub::platform::textLiteral $passwordHash] $now \
    [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
    [::fossilhub::platform::textLiteral $id] \
    [::fossilhub::platform::textLiteral $username] $now]
  ::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] $sql
  return [::fossilhub::auth::userById $id]
}

proc ::fossilhub::auth::authenticate {login password} {
  set user [::fossilhub::auth::userWithCredential $login]
  if {$user eq ""} {
    # Perform a real Argon2id operation so missing accounts do not take a
    # radically cheaper path than existing accounts.
    catch {::fossilhub::auth::passwordHash $password}
    return ""
  }
  if {[dict get $user status] ne "active" ||
      ![::fossilhub::auth::verifyPassword \
        $password [dict get $user password_hash]]} {
    return ""
  }
  dict unset user password_hash
  return $user
}

proc ::fossilhub::auth::administratorCount {} {
  set rows [::fossilhub::platform::sqlRows {
    SELECT hex(CAST(COUNT(*) AS TEXT))
      FROM users WHERE role='administrator' AND status='active';
  } 1]
  if {[llength $rows] == 0} {
    return 0
  }
  return [lindex [lindex $rows 0] 0]
}

proc ::fossilhub::auth::createSession {userId {userAgent ""} {address ""}} {
  variable idleSeconds
  variable absoluteSeconds
  set token [::fossilhub::auth::randomToken]
  set tokenHash [::fossilhub::auth::sha256 $token]
  set csrfSeed [::fossilhub::auth::randomToken]
  set now [clock seconds]
  set idleExpires [expr {$now + $idleSeconds}]
  set absoluteExpires [expr {$now + $absoluteSeconds}]
  set sql [format {
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;
    INSERT INTO sessions VALUES(%s,%s,%s,%d,%d,%d,%d,%d,%s,%s);
    UPDATE users SET last_login_epoch=%d,updated_epoch=%d WHERE id=%s;
    COMMIT;
  } \
    [::fossilhub::platform::textLiteral $tokenHash] \
    [::fossilhub::platform::textLiteral $userId] \
    [::fossilhub::platform::textLiteral \
      [::fossilhub::auth::sha256 $csrfSeed]] \
    $now $now $idleExpires $absoluteExpires $now \
    [::fossilhub::platform::textLiteral \
      [::fossilhub::auth::sha256 $userAgent]] \
    [::fossilhub::platform::textLiteral \
      [::fossilhub::auth::sha256 $address]] \
    $now $now [::fossilhub::platform::textLiteral $userId]]
  ::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] $sql
  return [dict create token $token token_hash $tokenHash \
    idle_expires_epoch $idleExpires absolute_expires_epoch $absoluteExpires]
}

proc ::fossilhub::auth::sessionByToken {token} {
  variable idleSeconds
  if {![regexp {^[[:xdigit:]]{64}$} $token]} {
    return ""
  }
  set tokenHash [::fossilhub::auth::sha256 [string tolower $token]]
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(s.id_hash),%s,
           hex(CAST(s.created_epoch AS TEXT)),
           hex(CAST(s.seen_epoch AS TEXT)),
           hex(CAST(s.idle_expires_epoch AS TEXT)),
           hex(CAST(s.absolute_expires_epoch AS TEXT)),
           hex(CAST(s.reauthenticated_epoch AS TEXT))
      FROM sessions AS s
      JOIN users AS u ON u.id=s.user_id
     WHERE s.id_hash=%s AND u.status='active'
     LIMIT 1;
  } [::fossilhub::auth::userSelect] \
    [::fossilhub::platform::textLiteral $tokenHash]] 19]
  if {[llength $rows] == 0} {
    return ""
  }
  set row [lindex $rows 0]
  set now [clock seconds]
  set idleExpires [lindex $row 16]
  set absoluteExpires [lindex $row 17]
  if {$idleExpires <= $now || $absoluteExpires <= $now} {
    ::fossilhub::auth::revokeSessionByHash $tokenHash
    return ""
  }
  set nextIdle [expr {min($absoluteExpires,$now + $idleSeconds)}]
  ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
    [format {UPDATE sessions SET seen_epoch=%d,idle_expires_epoch=%d
      WHERE id_hash=%s;} $now $nextIdle \
      [::fossilhub::platform::textLiteral $tokenHash]]
  return [dict create \
    session_hash [lindex $row 0] \
    user [::fossilhub::auth::userFromRow [lrange $row 1 13]] \
    created_epoch [lindex $row 14] seen_epoch $now \
    idle_expires_epoch $nextIdle absolute_expires_epoch $absoluteExpires \
    reauthenticated_epoch [lindex $row 18]]
}

proc ::fossilhub::auth::revokeSessionByHash {sessionHash} {
  if {![regexp {^[[:xdigit:]]{64}$} $sessionHash]} {
    return 0
  }
  set output [::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] [format {
      BEGIN IMMEDIATE;
      DELETE FROM sessions WHERE id_hash=%s;
      SELECT changes();
      COMMIT;
    } [::fossilhub::platform::textLiteral [string tolower $sessionHash]]]]
  expr {[string trim $output] eq "1"}
}

proc ::fossilhub::auth::revokeUserSession {userId sessionHash} {
  if {![regexp {^[[:xdigit:]]{64}$} $sessionHash]} {
    return 0
  }
  set output [::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] [format {
      BEGIN IMMEDIATE;
      DELETE FROM sessions WHERE id_hash=%s AND user_id=%s;
      SELECT changes();
      COMMIT;
    } [::fossilhub::platform::textLiteral [string tolower $sessionHash]] \
      [::fossilhub::platform::textLiteral $userId]]]
  expr {[string trim $output] eq "1"}
}

proc ::fossilhub::auth::sessionsForUser {userId} {
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(id_hash),hex(CAST(created_epoch AS TEXT)),
           hex(CAST(seen_epoch AS TEXT)),
           hex(CAST(idle_expires_epoch AS TEXT)),
           hex(CAST(absolute_expires_epoch AS TEXT)),
           hex(CAST(reauthenticated_epoch AS TEXT)),hex(user_agent_hash)
      FROM sessions WHERE user_id=%s
     ORDER BY seen_epoch DESC,id_hash;
  } [::fossilhub::platform::textLiteral $userId]] 7]
  set sessions {}
  foreach row $rows {
    lassign $row idHash created seen idleExpires absoluteExpires \
      reauthenticated userAgentHash
    lappend sessions [dict create id_hash $idHash created_epoch $created \
      seen_epoch $seen idle_expires_epoch $idleExpires \
      absolute_expires_epoch $absoluteExpires \
      reauthenticated_epoch $reauthenticated \
      user_agent_hash $userAgentHash]
  }
  return $sessions
}

proc ::fossilhub::auth::changePassword {userId currentPassword newPassword \
    keepSessionHash} {
  set currentUser [::fossilhub::auth::userById $userId]
  if {$currentUser eq ""} {
    error "Current password is incorrect."
  }
  set user [::fossilhub::auth::userWithCredential \
    [dict get $currentUser username]]
  if {$user eq "" || ![::fossilhub::auth::verifyPassword \
      $currentPassword [dict get $user password_hash]]} {
    error "Current password is incorrect."
  }
  set passwordHash [::fossilhub::auth::passwordHash $newPassword]
  set now [clock seconds]
  set sql [format {
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;
    UPDATE credentials SET password_hash=%s,password_changed_epoch=%d
      WHERE user_id=%s;
    DELETE FROM sessions WHERE user_id=%s;
    UPDATE users SET updated_epoch=%d,must_change_password=0 WHERE id=%s;
    INSERT INTO audit_events VALUES(%s,%s,NULL,'user.password-change','','success','','',%d);
    COMMIT;
  } \
    [::fossilhub::platform::textLiteral $passwordHash] $now \
    [::fossilhub::platform::textLiteral $userId] \
    [::fossilhub::platform::textLiteral $userId] $now \
    [::fossilhub::platform::textLiteral $userId] \
    [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
    [::fossilhub::platform::textLiteral $userId] $now]
  ::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] $sql
  return 1
}

proc ::fossilhub::auth::validPurpose {purpose} {
  expr {[string length $purpose] <= 120 &&
    [regexp {^[a-z0-9][a-z0-9:._-]*$} $purpose]}
}

proc ::fossilhub::auth::issueChallenge {purpose {sessionHash ""}} {
  variable challengeSeconds
  if {![::fossilhub::auth::validPurpose $purpose]} {
    error "invalid form purpose"
  }
  if {$sessionHash ne "" && ![regexp {^[[:xdigit:]]{64}$} $sessionHash]} {
    error "invalid challenge session"
  }
  set token [::fossilhub::auth::randomToken]
  set tokenHash [::fossilhub::auth::sha256 $token]
  set now [clock seconds]
  set session [expr {$sessionHash eq "" ? "NULL" :
    [::fossilhub::platform::textLiteral $sessionHash]}]
  set sql [format {
    PRAGMA foreign_keys=ON;
    BEGIN IMMEDIATE;
    DELETE FROM form_challenges WHERE expires_epoch<%d;
    INSERT INTO form_challenges VALUES(%s,%s,%s,%d,%d);
    COMMIT;
  } $now [::fossilhub::platform::textLiteral $tokenHash] $session \
    [::fossilhub::platform::textLiteral $purpose] $now \
    [expr {$now + $challengeSeconds}]]
  ::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] $sql
  return $token
}

proc ::fossilhub::auth::consumeChallenge {token purpose {sessionHash ""}} {
  if {![regexp {^[[:xdigit:]]{64}$} $token] ||
      ![::fossilhub::auth::validPurpose $purpose]} {
    return 0
  }
  if {$sessionHash ne "" && ![regexp {^[[:xdigit:]]{64}$} $sessionHash]} {
    return 0
  }
  set tokenHash [::fossilhub::auth::sha256 [string tolower $token]]
  if {$sessionHash eq ""} {
    set sessionClause {session_id_hash IS NULL}
  } else {
    set sessionClause "session_id_hash=[::fossilhub::platform::textLiteral $sessionHash]"
  }
  set now [clock seconds]
  set output [::fossilhub::platform::execute \
    [::fossilhub::platform::databasePath] [format {
      BEGIN IMMEDIATE;
      DELETE FROM form_challenges
       WHERE token_hash=%s AND purpose=%s AND %s AND expires_epoch>=%d;
      SELECT changes();
      COMMIT;
    } [::fossilhub::platform::textLiteral $tokenHash] \
      [::fossilhub::platform::textLiteral $purpose] $sessionClause $now]]
  expr {[string trim $output] eq "1"}
}

proc ::fossilhub::auth::loginAttemptKey {login address} {
  ::fossilhub::auth::sha256 \
    "login\u0000[string tolower [string trim $login]]\u0000$address"
}

proc ::fossilhub::auth::loginAllowed {login address} {
  variable loginWindowSeconds
  set key [::fossilhub::auth::loginAttemptKey $login $address]
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(CAST(attempts AS TEXT)),hex(CAST(window_epoch AS TEXT)),
           hex(CAST(blocked_until_epoch AS TEXT))
      FROM login_attempts WHERE key_hash=%s LIMIT 1;
  } [::fossilhub::platform::textLiteral $key]] 3]
  if {[llength $rows] == 0} {
    return 1
  }
  lassign [lindex $rows 0] attempts window blockedUntil
  set now [clock seconds]
  if {$blockedUntil > $now} {
    return 0
  }
  if {$window < $now - $loginWindowSeconds} {
    ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
      "DELETE FROM login_attempts WHERE key_hash=[::fossilhub::platform::textLiteral $key];"
  }
  return 1
}

proc ::fossilhub::auth::recordLoginFailure {login address} {
  variable loginWindowSeconds
  variable loginLimit
  set key [::fossilhub::auth::loginAttemptKey $login $address]
  set now [clock seconds]
  set rows [::fossilhub::platform::sqlRows [format {
    SELECT hex(CAST(attempts AS TEXT)),hex(CAST(window_epoch AS TEXT))
      FROM login_attempts WHERE key_hash=%s LIMIT 1;
  } [::fossilhub::platform::textLiteral $key]] 2]
  if {[llength $rows] == 0 ||
      [lindex [lindex $rows 0] 1] < $now - $loginWindowSeconds} {
    set attempts 1
    set window $now
  } else {
    lassign [lindex $rows 0] attempts window
    incr attempts
  }
  set blockedUntil 0
  if {$attempts >= $loginLimit} {
    set blockedUntil [expr {$now + $loginWindowSeconds}]
  }
  ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
    [format {
      INSERT INTO login_attempts VALUES(%s,%d,%d,%d)
      ON CONFLICT(key_hash) DO UPDATE SET
        attempts=excluded.attempts,
        window_epoch=excluded.window_epoch,
        blocked_until_epoch=excluded.blocked_until_epoch;
    } [::fossilhub::platform::textLiteral $key] $attempts $window $blockedUntil]
  return $attempts
}

proc ::fossilhub::auth::clearLoginFailures {login address} {
  set key [::fossilhub::auth::loginAttemptKey $login $address]
  ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
    "DELETE FROM login_attempts WHERE key_hash=[::fossilhub::platform::textLiteral $key];"
}

proc ::fossilhub::auth::registrationOpen {} {
  set rows [::fossilhub::platform::sqlRows {
    SELECT hex(value) FROM settings WHERE key='registration' LIMIT 1;
  } 1]
  expr {[llength $rows] == 1 && [lindex [lindex $rows 0] 0] eq "open"}
}
