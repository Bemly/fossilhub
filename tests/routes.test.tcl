set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app fossilhub.tcl]

proc assertEqual {actual expected label} {
  if {$actual ne $expected} {
    puts stderr "$label: expected '$expected', got '$actual'"
    exit 1
  }
}

assertEqual [::fossilhub::routeForPath /] home "root route"
assertEqual [::fossilhub::routeForPath /explore] explore "explore route"
assertEqual [::fossilhub::routeForPath /explore.html] explore "legacy explore route"
assertEqual [::fossilhub::routeForPath /repo/dig.fossil] \
  {repository dig.fossil timeline} "repository route"
assertEqual [::fossilhub::routeForPath /repo/sqlite.fossil/files] \
  {repository sqlite.fossil files} "repository files route"
assertEqual [::fossilhub::routeForPath /repo/sqlite.fossil/docs] \
  {repository sqlite.fossil docs} "repository docs route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/file/abcdef1234567890] \
  {repository sqlite.fossil file abcdef1234567890} \
  "repository artifact route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/wiki-page/abcdef1234567890] \
  {repository sqlite.fossil wiki-page abcdef1234567890} \
  "repository wiki artifact route"
assertEqual [::fossilhub::routeForPath /repo/sqlite.fossil/files/new] \
  {repository-mutation sqlite.fossil file-new} \
  "new file workbench route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/file/abcdef1234567890/edit] \
  {repository-mutation sqlite.fossil file-edit abcdef1234567890} \
  "file edit workbench route"
assertEqual [::fossilhub::routeForPath /repo/sqlite.fossil/wiki/new] \
  {repository-mutation sqlite.fossil wiki-new} \
  "new Wiki workbench route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/wiki-page/abcdef1234567890/edit] \
  {repository-mutation sqlite.fossil wiki-edit abcdef1234567890} \
  "Wiki edit workbench route"
assertEqual [::fossilhub::routeForPath /repo/sqlite.fossil/tickets/new] \
  {repository-mutation sqlite.fossil ticket-new} \
  "new Ticket workbench route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/ticket/abcdef1234567890abcdef1234567890abcdef12] \
  {repository-mutation sqlite.fossil ticket abcdef1234567890abcdef1234567890abcdef12} \
  "Ticket workbench route"
assertEqual [::fossilhub::routeForPath /repo/sqlite.fossil/forum/new] \
  {repository-mutation sqlite.fossil forum-new} \
  "new Forum discussion route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/forum/abcdef1234/reply] \
  {repository-mutation sqlite.fossil forum-reply abcdef1234} \
  "Forum reply route"
assertEqual [::fossilhub::routeForPath \
  /bemly-moe/app/fossilhub/repo/sqlite.fossil/files/new] \
  {repository-mutation sqlite.fossil file-new} \
  "mounted new file route"
assertEqual [::fossilhub::routeForPath /repo.html] \
  {repository bedrock.fossil timeline} "legacy repository route"
assertEqual [::fossilhub::routeForPath /catalog-fragment] \
  catalog-fragment "catalog fragment route"
assertEqual [::fossilhub::routeForPath /login] login "login route"
assertEqual [::fossilhub::routeForPath /register] register "register route"
assertEqual [::fossilhub::routeForPath /logout] logout "logout route"
assertEqual [::fossilhub::routeForPath /account/security] \
  account-security "account security route"
assertEqual [::fossilhub::routeForPath /account/session/revoke] \
  account-session-revoke "session revoke route"
assertEqual [::fossilhub::routeForPath /account/repositories] \
  repository-workspace "repository workspace route"
assertEqual [::fossilhub::routeForPath /account/repositories/new] \
  repository-new "new repository route"
assertEqual [::fossilhub::routeForPath \
  /account/repositories/fossil-tools/settings] \
  {repository-settings fossil-tools} "repository settings route"
assertEqual [::fossilhub::routeForPath \
  /account/repositories/fossil-tools/member-remove] \
  {repository-management-action fossil-tools member-remove} \
  "repository member removal route"
assertEqual [::fossilhub::routeForPath \
  /account/repositories/fossil-tools/transfer] \
  {repository-management-action fossil-tools transfer} \
  "repository transfer route"
assertEqual [::fossilhub::routeForPath \
  /bemly-moe/app/fossilhub/account/security] account-security \
  "mounted account security route"
assertEqual [::fossilhub::routeForPath \
  /bemly-moe/app/fossilhub/account/repositories/fossil-tools/archive] \
  {repository-management-action fossil-tools archive} \
  "mounted repository archive route"
assertEqual [::fossilhub::routeForPath /bemly-moe/app/fossilhub/login] \
  login "mounted login route"
assertEqual [::fossilhub::routeForPath /healthz] health "health route"
assertEqual [::fossilhub::routeForPath /fh.css] stylesheet "stylesheet route"
assertEqual [::fossilhub::routeForPath /fossilhub-live.js] \
  live-script "live integration script route"
assertEqual [::fossilhub::routeForPath /repo/fossilhub-live.js] \
  live-script "nested live integration script route"
assertEqual [::fossilhub::routeForPath /repo/catalog-search.js] \
  catalog-script "nested catalog script route"
assertEqual [::fossilhub::routeForPath /missing] not-found "not-found route"
assertEqual [::fossilhub::routeForPath /bemly-moe/app/fossilhub/explore] \
  explore "mounted explore route"
assertEqual [::fossilhub::routeForPath /bemly-moe/app/fossilhub/] \
  home "mounted home route"

rename ::fossilhub::requestPath ::fossilhub::realRequestPath
proc ::fossilhub::requestPath {} {
  return /bemly-moe/app/fossilhub/repo/sqlite.fossil/files/new
}
assertEqual [::fossilhub::mutationController::relativeHubPath login] \
  ../../../login "mounted mutation sign-in redirect"
assertEqual [::fossilhub::mutationController::relativeRepositoryPath files] \
  ../files "mounted mutation repository redirect"
rename ::fossilhub::requestPath {}
rename ::fossilhub::realRequestPath ::fossilhub::requestPath

puts "route tests passed"
