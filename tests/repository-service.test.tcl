set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib repository-manifest.tcl]
source [file join $projectRoot app lib platform-model.tcl]
source [file join $projectRoot app lib fossil-model.tcl]
source [file join $projectRoot app lib catalog-model.tcl]
source [file join $projectRoot app lib auth-model.tcl]
source [file join $projectRoot app lib repository-service.tcl]

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

set handle [file tempfile temporaryMarker fossilhub-repository-service-test]
close $handle
file delete $temporaryMarker
file mkdir $temporaryMarker

set ::env(FOSSILHUB_PLATFORM_DB) \
  [file join $temporaryMarker platform.sqlite]
set ::env(FOSSILHUB_CATALOG_DB) \
  [file join $temporaryMarker catalog.sqlite]
set ::env(FOSSILHUB_REPOSITORY_DIR) \
  [file join $temporaryMarker repositories]
set ::env(FOSSILHUB_LOCK_DIR) [file join $temporaryMarker locks]
set ::env(FOSSILHUB_QUARANTINE_DIR) \
  [file join $temporaryMarker quarantine]
set ::env(FOSSILHUB_FOSSIL) \
  [file join $projectRoot tests fixtures fake-fossil]
set ::env(FOSSILHUB_SQLITE) /usr/bin/sqlite3
set ::env(FOSSILHUB_OPENSSL) /usr/bin/openssl
set ::env(FOSSILHUB_ARGON2) \
  [file join $projectRoot tests fixtures fake-argon2]

rename ::fossilhub::catalog::rebuild ::fossilhub::catalog::realRebuild
set catalogRebuilds 0
set catalogFailure 0
proc ::fossilhub::catalog::rebuild {} {
  incr ::catalogRebuilds
  if {$::catalogFailure} {
    error "fixture catalogue failure"
  }
  return 1
}

try {
  ::fossilhub::platform::initialize
  set owner [::fossilhub::auth::createUser owner owner@example.test \
    {owner password fixture} {Repository Owner}]
  set collaborator [::fossilhub::auth::createUser helper helper@example.test \
    {helper password fixture} {Repository Helper}]

  assertEqual [::fossilhub::repositories::validateSlug Fossil-Tools] \
    fossil-tools "repository slug normalization"
  assertEqual [catch {::fossilhub::repositories::validateSlug admin}] 1 \
    "reserved repository slug"
  assertEqual [catch {::fossilhub::repositories::validateSlug bad--name}] 1 \
    "repeated hyphen rejected"
  assertEqual [catch {::fossilhub::repositories::validateSlug ../escape}] 1 \
    "repository path traversal rejected"

  set firstLock [::fossilhub::repositories::acquireLock create-lock-test]
  assertEqual [catch {::fossilhub::repositories::acquireLock \
    create-lock-test}] 1 "repository lock is exclusive"
  ::fossilhub::repositories::releaseLock $firstLock

  set repository [::fossilhub::repositories::create $owner fossil-tools \
    {Fossil Tools} {Shared repository tooling} public]
  assertEqual [dict get $repository slug] fossil-tools \
    "repository registry entry"
  assertEqual [dict get $repository owner_user_id] [dict get $owner id] \
    "repository owner recorded"
  set repositoryPath [file join $::env(FOSSILHUB_REPOSITORY_DIR) \
    fossil-tools.fossil]
  assertTrue [file isfile $repositoryPath] "repository file published"
  assertEqual [format %04o [expr {
    [file attributes $repositoryPath -permissions] & 0o777}]] 0600 \
    "repository file permissions"
  assertEqual [llength [::fossilhub::repositories::forUser \
    [dict get $owner id]]] 1 "owner repository listing"

  set visitor [dict create authenticated 0]
  set ownerContext [dict create authenticated 1 user $owner]
  set collaboratorContext [dict create authenticated 1 user $collaborator]
  assertTrue [::fossilhub::repositories::allows $repository $visitor read] \
    "public repository visitor read"
  assertTrue [::fossilhub::repositories::allows $repository $ownerContext owner] \
    "owner permission"
  assertTrue [expr {![::fossilhub::repositories::allows $repository \
    $collaboratorContext write]}] "non-member write denied"

  ::fossilhub::repositories::addMember $repository $collaborator reader \
    [dict get $owner id]
  assertTrue [expr {![::fossilhub::repositories::allows $repository \
    $collaboratorContext write]}] "reader write denied"
  ::fossilhub::repositories::addMember $repository $collaborator writer \
    [dict get $owner id]
  assertEqual [::fossilhub::repositories::membershipRole \
    [dict get $repository id] [dict get $collaborator id]] writer \
    "collaborator role"
  assertTrue [::fossilhub::repositories::allows $repository \
    $collaboratorContext write] "writer permission"

  set repository [::fossilhub::repositories::updateSettings $repository \
    {Private Fossil Tools} {Private collaboration} private stable \
    [dict get $owner id]]
  assertEqual [dict get $repository visibility] private \
    "repository visibility update"
  assertEqual [dict get $repository default_branch] stable \
    "default branch update"
  assertTrue [expr {![::fossilhub::repositories::allows $repository \
    $visitor read]}] "private visitor read denied"
  assertTrue [::fossilhub::repositories::allows $repository \
    $collaboratorContext read] "private collaborator read"

  set catalogFailure 1
  assertEqual [catch {::fossilhub::repositories::updateSettings $repository \
    {Should Roll Back} {Should Roll Back} public trunk \
    [dict get $owner id]}] 1 "settings failure is reported"
  set catalogFailure 0
  set repository [::fossilhub::repositories::bySlug fossil-tools]
  assertEqual [dict get $repository title] {Private Fossil Tools} \
    "settings database rollback"
  assertEqual [dict get $repository visibility] private \
    "visibility database rollback"

  ::fossilhub::repositories::archive $repository [dict get $owner id]
  set repository [::fossilhub::repositories::bySlug fossil-tools]
  assertEqual [dict get $repository state] archived "repository archived"
  assertEqual [catch {::fossilhub::repositories::addMember $repository \
    $collaborator reader [dict get $owner id]}] 1 \
    "archived repository collaborator mutation denied"
  assertTrue [expr {![file exists $repositoryPath]}] \
    "archived repository removed from live root"
  ::fossilhub::repositories::restore $repository [dict get $owner id]
  set repository [::fossilhub::repositories::bySlug fossil-tools]
  assertEqual [dict get $repository state] active "repository restored"
  assertTrue [file isfile $repositoryPath] "restored repository published"

  set catalogFailure 1
  assertEqual [catch {::fossilhub::repositories::archive $repository \
    [dict get $owner id]}] 1 "archive failure is reported"
  set catalogFailure 0
  set repository [::fossilhub::repositories::bySlug fossil-tools]
  assertEqual [dict get $repository state] active \
    "archive database rollback"
  assertTrue [file isfile $repositoryPath] "archive file rollback"

  set repository [::fossilhub::repositories::transfer $repository \
    $collaborator [dict get $owner id]]
  assertEqual [dict get $repository owner_user_id] \
    [dict get $collaborator id] "ownership transfer"
  assertEqual [::fossilhub::repositories::membershipRole \
    [dict get $repository id] [dict get $owner id]] maintainer \
    "former owner becomes maintainer"
  assertTrue [::fossilhub::repositories::removeMember $repository \
    [dict get $owner id] [dict get $collaborator id]] \
    "collaborator removed"
  assertTrue [expr {![::fossilhub::repositories::removeMember $repository \
    [dict get $owner id] [dict get $collaborator id]]}] \
    "missing collaborator removal is idempotent"

  set catalogFailure 1
  assertEqual [catch {::fossilhub::repositories::create $owner broken-index \
    {Broken Index} {Failure fixture} public}] 1 \
    "creation index failure is reported"
  set catalogFailure 0
  assertEqual [::fossilhub::repositories::bySlug broken-index] "" \
    "failed creation registry rollback"
  assertEqual [llength [glob -nocomplain [file join \
    $::env(FOSSILHUB_QUARANTINE_DIR) *-broken-index.fossil]]] 1 \
    "failed creation quarantined"

  assertEqual [catch {::fossilhub::repositories::create $owner FOSSIL-TOOLS \
    Duplicate Duplicate public}] 1 "duplicate repository rejected"
  assertTrue [expr {$catalogRebuilds >= 7}] "catalogue rebuild integration"
  assertEqual [string trim [exec /usr/bin/sqlite3 -batch -noheader \
    $::env(FOSSILHUB_PLATFORM_DB) {PRAGMA quick_check;}]] ok \
    "platform integrity after lifecycle operations"
} finally {
  file delete -force $temporaryMarker
}

puts "repository service tests passed"
