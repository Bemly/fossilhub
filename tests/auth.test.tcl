set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib repository-manifest.tcl]
source [file join $projectRoot app lib platform-model.tcl]
source [file join $projectRoot app lib auth-model.tcl]

proc fail {message} {
  puts stderr $message
  exit 1
}

proc assertEqual {actual expected label} {
  if {$actual ne $expected} {
    fail "$label: expected '$expected', got '$actual'"
  }
}

proc assertTrue {value label} {
  if {!$value} {
    fail "$label: assertion failed"
  }
}

set handle [file tempfile temporaryMarker fossilhub-auth-test]
close $handle
file delete $temporaryMarker
file mkdir $temporaryMarker
set database [file join $temporaryMarker platform.sqlite]
set ::env(FOSSILHUB_PLATFORM_DB) $database
set ::env(FOSSILHUB_SQLITE) /usr/bin/sqlite3
set ::env(FOSSILHUB_OPENSSL) /usr/bin/openssl
if {![info exists ::env(FOSSILHUB_ARGON2)]} {
  set ::env(FOSSILHUB_ARGON2) \
    [file join $projectRoot tests fixtures fake-argon2]
}

try {
  ::fossilhub::platform::initialize
  set user [::fossilhub::auth::createUser \
    Alice alice@example.test {correct horse fixture} {Alice Example}]
  assertEqual [dict get $user username] alice "username normalized"
  assertEqual [dict get $user role] user "ordinary registration role"
  assertEqual [::fossilhub::auth::administratorCount] 0 \
    "ordinary user is not administrator"

  set stored [::fossilhub::auth::userWithCredential alice]
  assertTrue [string match {$argon2id$*} [dict get $stored password_hash]] \
    "password stored as encoded Argon2id"
  assertTrue [expr {[dict get $stored password_hash] ne \
    {correct horse fixture}}] "password is not stored directly"
  assertEqual [dict get [::fossilhub::auth::authenticate \
    ALICE {correct horse fixture}] id] [dict get $user id] \
    "valid login"
  assertEqual [::fossilhub::auth::authenticate alice {wrong password fixture}] \
    "" "invalid password"
  assertEqual [::fossilhub::auth::authenticate missing {wrong password fixture}] \
    "" "missing account"
  assertEqual [catch {::fossilhub::auth::createUser \
    alice second@example.test {another password fixture}}] 1 \
    "duplicate username rejected"
  assertEqual [catch {::fossilhub::auth::createUser \
    {bad/name} bad@example.test {another password fixture}}] 1 \
    "hostile username rejected"

  set first [::fossilhub::auth::createSession \
    [dict get $user id] {Fixture Browser} 192.0.2.10]
  set loaded [::fossilhub::auth::sessionByToken [dict get $first token]]
  assertEqual [dict get [dict get $loaded user] username] alice \
    "session resolves active user"
  assertTrue [expr {[dict get $loaded session_hash] ne [dict get $first token]}] \
    "session stores token hash"

  set challenge [::fossilhub::auth::issueChallenge account-password \
    [dict get $loaded session_hash]]
  assertTrue [::fossilhub::auth::consumeChallenge $challenge account-password \
    [dict get $loaded session_hash]] "form challenge accepted once"
  assertTrue [expr {![::fossilhub::auth::consumeChallenge \
    $challenge account-password [dict get $loaded session_hash]]}] \
    "form challenge cannot be replayed"

  set second [::fossilhub::auth::createSession \
    [dict get $user id] {Other Browser} 192.0.2.11]
  assertEqual [llength [::fossilhub::auth::sessionsForUser \
    [dict get $user id]]] 2 "session listing"
  ::fossilhub::auth::changePassword [dict get $user id] \
    {correct horse fixture} {correct horse changed fixture} \
    [dict get $first token_hash]
  assertEqual [::fossilhub::auth::sessionByToken [dict get $first token]] "" \
    "password change rotates the current session"
  assertEqual [::fossilhub::auth::sessionByToken [dict get $second token]] "" \
    "password change revokes other sessions"
  assertEqual [dict get [::fossilhub::auth::authenticate \
    alice {correct horse changed fixture}] id] [dict get $user id] \
    "changed password authenticates"

  for {set attempt 1} {$attempt <= 5} {incr attempt} {
    ::fossilhub::auth::recordLoginFailure alice 192.0.2.12
  }
  assertTrue [expr {![::fossilhub::auth::loginAllowed alice 192.0.2.12]}] \
    "login throttling blocks repeated failures"
  assertTrue [::fossilhub::auth::loginAllowed alice 192.0.2.13] \
    "login throttling key includes address"

  set databaseBytes [open $database rb]
  fconfigure $databaseBytes -translation binary
  set raw [read $databaseBytes]
  close $databaseBytes
  assertTrue [expr {[string first [dict get $first token] $raw] < 0}] \
    "raw session token absent from database"
  assertTrue [expr {[string first {correct horse changed fixture} $raw] < 0}] \
    "raw password absent from database"
} finally {
  file delete -force $temporaryMarker
}

puts "auth tests passed"
