set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib repository-manifest.tcl]
source [file join $projectRoot app lib platform-model.tcl]
source [file join $projectRoot app lib fossil-model.tcl]
source [file join $projectRoot app lib catalog-model.tcl]
source [file join $projectRoot app lib auth-model.tcl]
source [file join $projectRoot app lib repository-service.tcl]
source [file join $projectRoot app lib workspace-model.tcl]
source [file join $projectRoot app lib admin-model.tcl]
source [file join $projectRoot app lib mutation-service.tcl]
source [file join $projectRoot app lib account-controller.tcl]

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

set handle [file tempfile temporaryMarker fossilhub-admin-test]
close $handle
file delete $temporaryMarker
file mkdir $temporaryMarker
set database [file join $temporaryMarker platform.sqlite]
set repositoryRoot [file join $temporaryMarker repositories]
file mkdir $repositoryRoot
set ::env(FOSSILHUB_PLATFORM_DB) $database
set ::env(FOSSILHUB_CATALOG_DB) [file join $temporaryMarker catalog.sqlite]
set ::env(FOSSILHUB_REPOSITORY_DIR) $repositoryRoot
set ::env(FOSSILHUB_LOCK_DIR) [file join $temporaryMarker locks]
set ::env(FOSSILHUB_QUARANTINE_DIR) [file join $temporaryMarker quarantine]
set ::env(FOSSILHUB_SQLITE) /usr/bin/sqlite3
set ::env(FOSSILHUB_OPENSSL) /usr/bin/openssl
set ::env(FOSSILHUB_ARGON2) [file join $projectRoot tests fixtures fake-argon2]
set ::env(FOSSILHUB_FOSSIL) [file join $projectRoot tests fixtures fake-fossil]

try {
  ::fossilhub::platform::initialize
  assertEqual [::fossilhub::platform::setting repositories_per_user] 100 \
    "administrator repository limit default"
  assertEqual [::fossilhub::platform::setting repository_quota_mb] 512 \
    "administrator quota default"

  set admin [::fossilhub::auth::createUser warden warden@example.test \
    {warden password fixture} Warden administrator]
  set user [::fossilhub::auth::createUser alice alice@example.test \
    {alice password fixture} Alice]
  set session [::fossilhub::auth::createSession [dict get $admin id] \
    browser 192.0.2.30]
  set staleContext [dict create authenticated 1 user $admin \
    session_hash [dict get $session token_hash] reauthenticated_epoch 0]
  assertTrue [expr {![::fossilhub::account::recentlyAuthenticated \
    $staleContext]}] "stale administrator session requires reauth"
  assertTrue [expr {![::fossilhub::auth::reauthenticate [dict get $admin id] \
    wrong [dict get $session token_hash]]}] "administrator reauth rejects password"
  assertTrue [::fossilhub::auth::reauthenticate [dict get $admin id] \
    {warden password fixture} [dict get $session token_hash]] \
    "administrator reauth accepts password"
  set refreshed [::fossilhub::auth::sessionByToken [dict get $session token]]
  assertTrue [expr {[dict get $refreshed reauthenticated_epoch] > 0}] \
    "administrator reauth refreshes session epoch"
  set scoped [::fossilhub::auth::issueChallenge admin-settings \
    [dict get $refreshed session_hash]]
  assertTrue [expr {![::fossilhub::auth::consumeChallenge $scoped \
    admin-user-role:0123456789abcdef0123456789abcdef \
    [dict get $refreshed session_hash]]}] \
    "administrator CSRF challenge is action scoped"

  assertEqual [llength [::fossilhub::admin::users alice all all]] 1 \
    "administrator user search"
  assertEqual [catch {::fossilhub::admin::changeUserRole \
    [dict get $admin id] [dict get $admin id] user}] 1 \
    "last administrator demotion blocked"
  ::fossilhub::admin::changeUserRole [dict get $admin id] \
    [dict get $user id] administrator
  assertEqual [dict get [::fossilhub::auth::userById [dict get $user id]] role] \
    administrator "administrator promotion"

  set userSession [::fossilhub::auth::createSession [dict get $user id]]
  ::fossilhub::admin::changeUserStatus [dict get $admin id] \
    [dict get $user id] disabled
  assertEqual [::fossilhub::auth::sessionByToken [dict get $userSession token]] \
    "" "administrator disable revokes sessions"
  ::fossilhub::admin::changeUserStatus [dict get $admin id] \
    [dict get $user id] active

  set settings [::fossilhub::admin::updateSettings [dict get $admin id] \
    [dict create registration closed default_visibility private \
      repositories_per_user 7 repository_quota_mb 64 \
      maintenance_banner {Maintenance at 02:00 UTC.}]]
  assertEqual [dict get $settings registration] closed \
    "administrator registration setting"
  assertEqual [dict get $settings default_visibility] private \
    "administrator visibility setting"
  assertEqual [::fossilhub::mutations::repositoryQuotaBytes] 67108864 \
    "administrator quota setting enforced"

  set repositoryPath [file join $repositoryRoot bedrock.fossil]
  set channel [open $repositoryPath w]
  puts $channel {fixture repository}
  close $channel
  file attributes $repositoryPath -permissions 0600
  ::fossilhub::platform::execute $database [format {
    UPDATE repositories SET owner_user_id=%s WHERE slug='bedrock';
  } [::fossilhub::platform::textLiteral [dict get $user id]]]
  set repository [::fossilhub::admin::repositoryDetail bedrock]
  assertEqual [dict get $repository owner_username] alice \
    "administrator repository ownership inspection"
  assertTrue [::fossilhub::admin::checkRepositoryIntegrity $repository \
    [dict get $admin id]] "repository integrity success"
  set ::env(FOSSILHUB_FAKE_INTEGRITY_FAIL) 1
  assertEqual [catch {::fossilhub::admin::checkRepositoryIntegrity $repository \
    [dict get $admin id]}] 1 "repository integrity failure reported"
  unset ::env(FOSSILHUB_FAKE_INTEGRITY_FAIL)
  assertEqual [dict get [::fossilhub::repositories::bySlug bedrock] state] \
    quarantined "integrity failure quarantines registry"
  assertTrue [expr {![file exists $repositoryPath]}] \
    "integrity failure removes repository from publication"

  set events [::fossilhub::admin::auditEvents "" all "" 100]
  assertTrue [expr {[llength $events] >= 6}] "administrator audit listing"
  assertTrue [expr {![dict exists [lindex $events 0] detail]}] \
    "administrator audit detail redacted"
  assertTrue [expr {![dict exists [lindex $events 0] request_id]}] \
    "administrator request identifier redacted"
  set overview [::fossilhub::admin::overview]
  assertEqual [dict get $overview users] 2 "administrator overview users"
  assertEqual [dict get $overview repositories] 10 \
    "administrator overview repositories"
  set health [::fossilhub::admin::health]
  assertEqual [dict get $health platform_database] ok \
    "administrator platform health"
} finally {
  catch {unset ::env(FOSSILHUB_FAKE_INTEGRITY_FAIL)}
  file delete -force $temporaryMarker
}

puts "administrator tests passed"
