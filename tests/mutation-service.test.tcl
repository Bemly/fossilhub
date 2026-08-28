set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib repository-manifest.tcl]
source [file join $projectRoot app lib platform-model.tcl]
source [file join $projectRoot app lib fossil-model.tcl]
source [file join $projectRoot app lib catalog-model.tcl]
source [file join $projectRoot app lib auth-model.tcl]
source [file join $projectRoot app lib repository-service.tcl]
source [file join $projectRoot app lib mutation-service.tcl]

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

proc latestCheckinUser {repository} {
  set rows [::fossilhub::model::sqlRows $repository {
    SELECT hex(COALESCE(euser,user,'')) FROM event
     WHERE type='ci' ORDER BY mtime DESC,objid DESC LIMIT 1;
  } 1]
  return [lindex [lindex $rows 0] 0]
}

set handle [file tempfile temporaryMarker fossilhub-mutation-service-test]
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
if {![info exists ::env(FOSSILHUB_FOSSIL)] ||
    $::env(FOSSILHUB_FOSSIL) eq ""} {
  set ::env(FOSSILHUB_FOSSIL) /usr/local/bin/fossil
}
set ::env(FOSSILHUB_SQLITE) /usr/bin/sqlite3
set ::env(FOSSILHUB_OPENSSL) /usr/bin/openssl
set ::env(FOSSILHUB_ARGON2) \
  [file join $projectRoot tests fixtures fake-argon2]

try {
  if {![file executable $::env(FOSSILHUB_FOSSIL)]} {
    fail "real Fossil binary unavailable at $::env(FOSSILHUB_FOSSIL)"
  }
  ::fossilhub::platform::initialize
  set user [::fossilhub::auth::createUser alice alice@example.test \
    {mutation fixture password} {Alice Example}]
  set repository [::fossilhub::repositories::create $user mutation-lab \
    {Mutation Lab} {Real Fossil mutation integration} public]
  set repositoryPath [::fossilhub::model::repositoryPath \
    [dict get $repository name]]

  assertEqual [catch {::fossilhub::mutations::validateFilename ../escape}] 1 \
    "file traversal rejected"
  assertEqual [catch {::fossilhub::mutations::validateFilename --option}] 1 \
    "command-like filename rejected"
  assertEqual [catch {::fossilhub::mutations::validateFilename \
    .fossil-settings/hooks/commit-command}] 1 \
    "checkout control files rejected"
  assertEqual [catch {::fossilhub::mutations::validateRevision stale}] 1 \
    "short revision rejected"

  set head [::fossilhub::mutations::branchHead $repositoryPath trunk]
  assertTrue [regexp {^[[:xdigit:]]{40,64}$} $head] \
    "initial trunk head"
  ::fossilhub::repositories::runFossil {branch fixture creation} [list \
    --user fossilhub branch new feature $head --repository $repositoryPath \
    --nosync --nosign]
  assertEqual [::fossilhub::mutations::branchNames $repositoryPath] \
    {feature trunk} "repository branch selection"
  set headAfterCreate [::fossilhub::mutations::fileChange $repository $user \
    create README.md {} "# Mutation Lab\n\n中文内容。\n" \
    {Create README} trunk $head request-file-create]
  assertTrue [expr {![string equal -nocase $head $headAfterCreate]}] \
    "file creation advances trunk"
  assertEqual [latestCheckinUser $repositoryPath] alice \
    "central author reconciled for commits"
  set files [::fossilhub::model::files [dict get $repository name]]
  assertEqual [dict get [lindex $files 0] filename] README.md \
    "created file listed"
  set fileRecord [::fossilhub::model::fileRecord [dict get $repository name] \
    [dict get [lindex $files 0] uuid]]
  assertEqual [dict get $fileRecord content] "# Mutation Lab\n\n中文内容。\n" \
    "UTF-8 file content preserved"
  set audit [::fossilhub::platform::sqlRows {
    SELECT hex(request_id),hex(detail) FROM audit_events
     WHERE action='repository.file-create' AND outcome='success'
     ORDER BY created_epoch DESC LIMIT 1;
  } 2]
  assertEqual [lindex [lindex $audit 0] 0] request-file-create \
    "mutation request identifier audited"
  assertEqual [lindex [lindex $audit 0] 1] "" \
    "submitted content absent from audit detail"

  assertEqual [catch {::fossilhub::mutations::fileChange $repository $user \
    edit README.md {} {stale content} {Stale edit} trunk $head}] 1 \
    "stale file form rejected"
  assertEqual [::fossilhub::mutations::branchHead $repositoryPath trunk] \
    $headAfterCreate "stale edit leaves trunk unchanged"

  set headAfterEdit [::fossilhub::mutations::fileChange $repository $user \
    edit README.md {} "# Updated\n" {Update README} trunk $headAfterCreate]
  set headAfterRename [::fossilhub::mutations::fileChange $repository $user \
    rename README.md docs/guide.md {} {Move guide} trunk $headAfterEdit]
  set files [::fossilhub::model::files [dict get $repository name]]
  assertEqual [dict get [lindex $files 0] filename] docs/guide.md \
    "file rename published"
  set headAfterDelete [::fossilhub::mutations::fileChange $repository $user \
    delete docs/guide.md {} {} {Remove guide} trunk $headAfterRename]
  assertTrue [expr {$headAfterDelete ne $headAfterRename}] \
    "file deletion advances trunk"
  assertEqual [llength [::fossilhub::model::files \
    [dict get $repository name]]] 0 "file deletion published"

  set wiki [::fossilhub::mutations::wikiChange $repository $user Home \
    "# Home\n\nWelcome.\n" markdown {}]
  assertEqual [dict get $wiki user] alice "Wiki author reconciled"
  set wikiContent [::fossilhub::model::wikiContent \
    [dict get $repository name] [dict get $wiki uuid]]
  assertEqual [dict get $wikiContent content] "# Home\n\nWelcome.\n" \
    "Wiki content published"
  set wikiNext [::fossilhub::mutations::wikiChange $repository $user Home \
    "# Home\n\nUpdated.\n" markdown [dict get $wiki uuid]]
  assertTrue [expr {[dict get $wikiNext uuid] ne [dict get $wiki uuid]}] \
    "Wiki update advances revision"
  assertEqual [catch {::fossilhub::mutations::wikiChange $repository $user Home \
    stale plain [dict get $wiki uuid]}] 1 "stale Wiki form rejected"

  set ticket [::fossilhub::mutations::ticketCreate $repository $user \
    {Path with spaces and \slashes} Code_Defect \
    "Line one.\nLine two with 中文."]
  set ticketId [dict get $ticket uuid]
  set ticketRevision [dict get $ticket revision]
  assertTrue [regexp {^[[:xdigit:]]{40,64}$} $ticketRevision] \
    "Ticket creation revision"
  set tickets [::fossilhub::model::tickets [dict get $repository name]]
  assertEqual [dict get [lindex $tickets 0] title] \
    {Path with spaces and \slashes} "Ticket quoting preserved"
  set ticketRevision [::fossilhub::mutations::ticketChange $repository $user \
    $ticketId update {} $ticketRevision request-ticket-update \
    [dict create title {Updated ticket title} type Task]]
  set tickets [::fossilhub::model::tickets [dict get $repository name]]
  assertEqual [dict get [lindex $tickets 0] title] {Updated ticket title} \
    "Ticket title update published"
  assertEqual [dict get [lindex $tickets 0] type] Task \
    "Ticket type update published"
  set ticketRevision [::fossilhub::mutations::ticketChange $repository $user \
    $ticketId comment {A follow-up comment.} $ticketRevision]
  set ticketRevision [::fossilhub::mutations::ticketChange $repository $user \
    $ticketId close {Closing after verification.} $ticketRevision]
  set tickets [::fossilhub::model::tickets [dict get $repository name]]
  assertEqual [dict get [lindex $tickets 0] status] Closed \
    "Ticket close published"
  set ticketRevision [::fossilhub::mutations::ticketChange $repository $user \
    $ticketId reopen {} $ticketRevision]
  set tickets [::fossilhub::model::tickets [dict get $repository name]]
  assertEqual [dict get [lindex $tickets 0] status] Open \
    "Ticket reopen published"

  set threadId [::fossilhub::mutations::forumChange $repository $user thread \
    {First discussion} {Opening the discussion.} markdown {}]
  assertTrue [regexp {^[[:xdigit:]]{40,64}$} $threadId] \
    "Forum thread identifier"
  set replyId [::fossilhub::mutations::forumChange $repository $user reply \
    {} {Reply from the same central identity.} markdown $threadId]
  assertTrue [expr {$replyId ne $threadId}] "Forum reply published"
  set forum [::fossilhub::model::forumPosts [dict get $repository name]]
  assertEqual [llength $forum] 2 "Forum events indexed"
  assertEqual [dict get [lindex $forum 0] user] alice \
    "Forum author reconciled"

  set ::env(FOSSILHUB_REPOSITORY_QUOTA_BYTES) \
    [expr {[file size $repositoryPath] + 1048576}]
  assertEqual [catch {::fossilhub::mutations::wikiChange $repository $user \
    Quota {This mutation must be rejected.} plain {}}] 1 \
    "repository quota enforced before mutation"
  unset ::env(FOSSILHUB_REPOSITORY_QUOTA_BYTES)
  assertEqual [::fossilhub::mutations::wikiPage $repository Quota] "" \
    "quota failure leaves repository unchanged"

  set failureRepository [::fossilhub::repositories::create $user \
    mutation-index-failure {Mutation Index Failure} \
    {Post-mutation quarantine fixture} public]
  set failurePath [::fossilhub::model::repositoryPath \
    [dict get $failureRepository name]]
  set failureHead [::fossilhub::mutations::branchHead $failurePath trunk]
  rename ::fossilhub::catalog::rebuild \
    ::fossilhub::catalog::mutationTestRealRebuild
  proc ::fossilhub::catalog::rebuild {} {
    error "fixture post-mutation catalogue failure"
  }
  set failureResult [catch {::fossilhub::mutations::fileChange \
    $failureRepository $user create README.md {} {published artifact} \
    {Trigger index failure} trunk $failureHead request-index-failure}]
  rename ::fossilhub::catalog::rebuild {}
  rename ::fossilhub::catalog::mutationTestRealRebuild \
    ::fossilhub::catalog::rebuild
  assertEqual $failureResult 1 "post-mutation index failure reported"
  set failureRepository [::fossilhub::repositories::bySlug \
    mutation-index-failure]
  assertEqual [dict get $failureRepository state] quarantined \
    "unindexed mutation quarantines repository"
  assertTrue [expr {[::fossilhub::mutations::branchHead $failurePath trunk] ne \
    $failureHead}] "successful Fossil artifact retained for recovery"
  ::fossilhub::catalog::rebuild

  assertTrue [file isfile $::env(FOSSILHUB_CATALOG_DB)] \
    "catalogue rebuilt after mutations"
  assertEqual [llength [glob -nocomplain -directory \
    $::env(FOSSILHUB_LOCK_DIR) *.lock]] 0 "write locks released"
  assertEqual [llength [glob -nocomplain -directory \
    $temporaryMarker {*.new.*}]] 0 "mutation temporary files removed"
  assertEqual [string trim [exec /usr/bin/sqlite3 -batch -noheader \
    $::env(FOSSILHUB_PLATFORM_DB) {PRAGMA quick_check;}]] ok \
    "platform integrity after mutations"
} finally {
  file delete -force $temporaryMarker
}

puts "mutation service tests passed"
