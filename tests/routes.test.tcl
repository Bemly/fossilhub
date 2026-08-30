set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app fossilhub.tcl]

proc assertEqual {actual expected label} {
  if {$actual ne $expected} {
    puts stderr "$label: expected '$expected', got '$actual'"
    exit 1
  }
}

proc assertContains {document needle label} {
  if {[string first $needle $document] < 0} {
    puts stderr "$label: missing '$needle'"
    exit 1
  }
}

set mutationRequestId [::fossilhub::mutationController::requestId]
assertEqual [string length $mutationRequestId] 32 \
  "mutation request identifier length"
assertEqual [regexp {^[[:xdigit:]]{32}$} $mutationRequestId] 1 \
  "mutation request identifier format"

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
  {repository-ticket sqlite.fossil abcdef1234567890abcdef1234567890abcdef12} \
  "Ticket detail route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/ticket/abcdef1234567890abcdef1234567890abcdef12/manage] \
  {repository-mutation sqlite.fossil ticket abcdef1234567890abcdef1234567890abcdef12} \
  "Ticket workbench route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/checkin/abcdef1234567890] \
  {repository sqlite.fossil checkin abcdef1234567890} \
  "check-in detail route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/tree/abcdef1234567890] \
  {repository sqlite.fossil tree abcdef1234567890} \
  "versioned tree route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/blob/abcdef1234567890/1234567890abcdef] \
  {repository sqlite.fossil blob abcdef1234567890 1234567890abcdef} \
  "versioned file route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/archive/abcdef1234567890.zip] \
  {repository sqlite.fossil archive abcdef1234567890} \
  "repository archive route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/wiki-revision/abcdef1234567890/history] \
  {repository sqlite.fossil wiki-history abcdef1234567890} \
  "Wiki history route"
assertEqual [::fossilhub::routeForPath \
  /repo/sqlite.fossil/discussion/abcdef1234567890] \
  {repository sqlite.fossil discussion abcdef1234567890} \
  "Forum thread route"
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
assertEqual [::fossilhub::routeForPath /locale] locale "locale route"
assertEqual [::fossilhub::routeForPath \
  /bemly-moe/app/fossilhub/locale] locale "mounted locale route"
assertEqual [::fossilhub::routeForPath /login] login "login route"
assertEqual [::fossilhub::routeForPath /register] register "register route"
assertEqual [::fossilhub::routeForPath /logout] logout "logout route"
assertEqual [::fossilhub::routeForPath /dashboard] dashboard \
  "dashboard route"
assertEqual [::fossilhub::routeForPath /users/alice] \
  {public-profile alice} "public profile route"
assertEqual [::fossilhub::routeForPath /settings] account-settings \
  "account settings route"
assertEqual [::fossilhub::routeForPath /settings/security] account-security \
  "account security alias route"
assertEqual [::fossilhub::routeForPath /settings/session/revoke] \
  account-session-revoke "settings session revoke route"
assertEqual [::fossilhub::routeForPath /settings/deactivate] \
  account-deactivate "account deactivation route"
assertEqual [::fossilhub::routeForPath /admin] admin-overview \
  "administrator overview route"
assertEqual [::fossilhub::routeForPath /admin/users] admin-users \
  "administrator users route"
assertEqual [::fossilhub::routeForPath \
  /admin/users/0123456789abcdef0123456789abcdef] \
  {admin-user 0123456789abcdef0123456789abcdef} \
  "administrator user detail route"
assertEqual [::fossilhub::routeForPath \
  /admin/users/0123456789abcdef0123456789abcdef/status] \
  {admin-user-action 0123456789abcdef0123456789abcdef status} \
  "administrator user status route"
assertEqual [::fossilhub::routeForPath /admin/repositories] \
  admin-repositories "administrator repositories route"
assertEqual [::fossilhub::routeForPath /admin/repositories/bedrock/integrity] \
  {admin-repository-action bedrock integrity} \
  "administrator repository integrity route"
assertEqual [::fossilhub::routeForPath /admin/audit] admin-audit \
  "administrator audit route"
assertEqual [::fossilhub::routeForPath /admin/audit.csv] admin-audit-export \
  "administrator audit export route"
assertEqual [::fossilhub::routeForPath /admin/health] admin-health \
  "administrator health route"
assertEqual [::fossilhub::routeForPath /admin/health/reindex] admin-reindex \
  "administrator catalogue rebuild route"
assertEqual [::fossilhub::routeForPath /admin/settings] admin-settings \
  "administrator settings route"
assertEqual [::fossilhub::routeForPath /admin/reauth] admin-reauth \
  "administrator reauthentication route"
foreach page {manual hosting upstream releases rules status privacy security contact} {
  assertEqual [::fossilhub::routeForPath "/$page"] \
    [list public-information $page] "public $page route"
  assertEqual [::fossilhub::routeForPath \
    "/bemly-moe/app/fossilhub/$page"] [list public-information $page] \
    "mounted public $page route"
}
assertEqual [::fossilhub::routeForPath \
  /bemly-moe/app/fossilhub/admin/repositories/bedrock] \
  {admin-repository bedrock} "mounted administrator repository route"
assertEqual [::fossilhub::routeForPath \
  /bemly-moe/app/fossilhub/admin/settings] admin-settings \
  "mounted administrator settings route"
assertEqual [::fossilhub::routeForPath /account/security] \
  account-security "account security route"
assertEqual [::fossilhub::routeForPath /account/session/revoke] \
  account-session-revoke "session revoke route"
assertEqual [::fossilhub::routeForPath /account/repositories] \
  repository-workspace "repository workspace route"
assertEqual [::fossilhub::routeForPath /account/repositories/new] \
  repository-new "new repository route"
assertEqual [::fossilhub::routeForPath /repositories/new] \
  repository-new "new repository shortcut route"
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
  /bemly-moe/app/fossilhub/users/alice] {public-profile alice} \
  "mounted public profile route"
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
assertEqual [::fossilhub::routeForPath /fossilhub-hub-lockup-v1.png] \
  brand-lockup "brand lockup route"
assertEqual [::fossilhub::routeForPath \
  /bemly-moe/app/fossilhub/repo/fossilhub-hub-lockup-v1.png] \
  brand-lockup "mounted nested brand lockup route"

rename ::fossilhub::maintenanceBanner ::fossilhub::realMaintenanceBanner
proc ::fossilhub::maintenanceBanner {} { return {Window <unsafe>} }
set decorated [::fossilhub::decoratePage \
  {<!doctype html><html><body><main>safe</main></body></html>}]
assertContains $decorated {Window &lt;unsafe&gt;} \
  "maintenance banner escaped"
assertContains $decorated {role="status"} "maintenance banner landmark"
rename ::fossilhub::maintenanceBanner {}
rename ::fossilhub::realMaintenanceBanner ::fossilhub::maintenanceBanner
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
