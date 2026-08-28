set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib repository-manifest.tcl]
source [file join $projectRoot app lib platform-model.tcl]
source [file join $projectRoot app lib fossil-model.tcl]
source [file join $projectRoot app lib catalog-model.tcl]
source [file join $projectRoot app lib auth-model.tcl]
source [file join $projectRoot app lib repository-service.tcl]
source [file join $projectRoot app lib workspace-model.tcl]

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

set handle [file tempfile temporaryMarker fossilhub-workspace-test]
close $handle
file delete $temporaryMarker
file mkdir $temporaryMarker
set database [file join $temporaryMarker platform.sqlite]
set ::env(FOSSILHUB_PLATFORM_DB) $database
set ::env(FOSSILHUB_REPOSITORY_DIR) [file join $temporaryMarker repositories]
set ::env(FOSSILHUB_SQLITE) /usr/bin/sqlite3
set ::env(FOSSILHUB_OPENSSL) /usr/bin/openssl
set ::env(FOSSILHUB_ARGON2) \
  [file join $projectRoot tests fixtures fake-argon2]
set ::env(FOSSILHUB_FOSSIL) [file join $projectRoot tests fixtures fake-fossil]

try {
  ::fossilhub::platform::initialize
  set user [::fossilhub::auth::createUser alice alice@example.test \
    {profile password fixture} Alice]
  set helper [::fossilhub::auth::createUser helper helper@example.test \
    {helper password fixture} Helper]
  set admin [::fossilhub::auth::createUser warden warden@example.test \
    {warden password fixture} Warden administrator]

  assertEqual [catch {::fossilhub::workspace::validateWebsite \
    http://insecure.example}] 1 "profile website requires HTTPS"
  assertEqual [::fossilhub::workspace::validateWebsite \
    https://example.test/alice] https://example.test/alice \
    "profile website accepts HTTPS"

  set updated [::fossilhub::workspace::updateProfile [dict get $user id] \
    [dict create display_name {Alice Field} email alice@new.example.test \
      biography {Maps old strata.} website https://example.test/alice \
      location {North ridge}]]
  assertEqual [dict get $updated display_name] {Alice Field} \
    "profile display name saved"
  assertEqual [dict get $updated biography] {Maps old strata.} \
    "profile biography saved"
  assertEqual [catch {::fossilhub::workspace::updateProfile \
    [dict get $user id] [dict create display_name Alice \
      email helper@example.test biography {} website {} location {}]}] 1 \
    "duplicate profile email rejected"

  set now [clock seconds]
  ::fossilhub::platform::execute $database [format {
    BEGIN IMMEDIATE;
    UPDATE repositories SET owner_user_id=%s,updated_epoch=%d
      WHERE slug='bedrock';
    INSERT INTO memberships VALUES(
      (SELECT id FROM repositories WHERE slug='ammonite'),%s,'writer',%d,%d);
    INSERT INTO audit_events VALUES(%s,%s,
      (SELECT id FROM repositories WHERE slug='bedrock'),
      'repository.file-edit','README.md','success','','',%d);
    COMMIT;
  } [::fossilhub::platform::textLiteral [dict get $user id]] $now \
    [::fossilhub::platform::textLiteral [dict get $user id]] $now $now \
    [::fossilhub::platform::textLiteral [::fossilhub::auth::randomToken 16]] \
    [::fossilhub::platform::textLiteral [dict get $user id]] $now]

  set dashboard [::fossilhub::workspace::dashboard [dict get $user id]]
  assertEqual [llength [dict get $dashboard owned]] 1 \
    "dashboard owned repository"
  assertEqual [llength [dict get $dashboard collaborations]] 1 \
    "dashboard collaboration repository"
  assertEqual [dict get [lindex [dict get $dashboard collaborations] 0] \
    membership_role] writer "dashboard collaboration role"

  set profile [::fossilhub::workspace::publicProfile ALICE]
  assertEqual [dict get [dict get $profile user] display_name] {Alice Field} \
    "public profile lookup"
  assertEqual [llength [dict get $profile repositories]] 1 \
    "public owned repository summary"
  assertEqual [llength [dict get $profile activity]] 1 \
    "public activity excludes private account events"

  assertEqual [catch {::fossilhub::workspace::deactivate \
    [dict get $admin id] {warden password fixture}}] 1 \
    "last administrator cannot deactivate"
  assertEqual [catch {::fossilhub::workspace::deactivate \
    [dict get $user id] wrong}] 1 "deactivation verifies password"
  assertTrue [::fossilhub::workspace::deactivate [dict get $user id] \
    {profile password fixture}] "ordinary account deactivated"
  assertEqual [dict get [::fossilhub::auth::userById \
    [dict get $user id]] status] deactivated "deactivated state stored"
  assertEqual [::fossilhub::workspace::publicProfile alice] "" \
    "deactivated public profile hidden"
} finally {
  file delete -force $temporaryMarker
}

puts "workspace tests passed"
