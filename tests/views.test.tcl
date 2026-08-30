set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib view.tcl]
source [file join $projectRoot app lib markup.tcl]
source [file join $projectRoot app lib i18n.tcl]
source [file join $projectRoot app lib catalog-model.tcl]
source [file join $projectRoot app lib repository-service.tcl]
source [file join $projectRoot app views home.tcl]
source [file join $projectRoot app views explore.tcl]
source [file join $projectRoot app views repository-sections.tcl]
source [file join $projectRoot app views repository.tcl]
source [file join $projectRoot app views account.tcl]
source [file join $projectRoot app views admin.tcl]
source [file join $projectRoot app views public.tcl]
source [file join $projectRoot app views repository-management.tcl]
source [file join $projectRoot app views mutations.tcl]

proc fail {message} {
  puts stderr $message
  exit 1
}

proc assertContains {document needle label} {
  if {[string first $needle $document] < 0} {
    fail "$label: missing '$needle'"
  }
}

proc assertNotContains {document needle label} {
  if {[string first $needle $document] >= 0} {
    fail "$label: unexpectedly contained '$needle'"
  }
}

set fixture [file normalize [info script]]
set events [list \
  [dict create \
    type ci epoch 1787788800 uuid a1b2c3d4e5 \
    user {alice <admin>} comment {Ship <script>alert("x")</script>}] \
  [dict create \
    type w epoch 1787702400 uuid b2c3d4e5f6 \
    user bob comment {Write the field guide}] \
  [dict create \
    type t epoch 1787616000 uuid c3d4e5f6a7 \
    user carol comment {Open the first ticket}]]
set repository [dict create \
  available 1 \
  name dig.fossil \
  slug dig \
  path $fixture \
  bytes 3250585 \
  project_name {FossilHub <Demo>} \
  description {A live & durable repository} \
  project_code 8f3a21c4deadbeef \
  artifacts 1284 \
  checkins 2 \
  wiki_events 1 \
  ticket_events 1 \
  forum_events 0 \
  contributors 3 \
  open_tickets 1 \
  opened_epoch 1787616000 \
  latest_epoch 1787788800 \
  events $events]

set home [::fossilhub::views::renderHome $repository]
assertContains $home {dig.fossil — recent activity} "home repository identity"
assertContains $home {Ship &lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;} \
  "home event escaped"
assertContains $home {1,284 artifacts · 3.1 MB received} "home live metrics"
assertNotContains $home {Add delta compression to bundle writer} \
  "home prototype event removed"
assertNotContains $home {@@} "home placeholders resolved"

set explore [::fossilhub::views::renderExplore [list $repository]]
assertContains $explore {1 match} "Explore live count"
assertContains $explore {SHOWING 1 — INDEXED IN SQLITE} \
  "Explore SQLite source"
assertContains $explore {A live &amp; durable repository} \
  "Explore description escaped"
assertContains $explore {repo/dig.fossil} "Explore repository route"
assertNotContains $explore {12,408} "Explore prototype count removed"
assertNotContains $explore {amber.fossil} "Explore prototype repository removed"
assertNotContains $explore {@@} "Explore placeholders resolved"

set emptyExplore [::fossilhub::views::renderExplore {}]
assertContains $emptyExplore {No repositories match this survey.} \
  "Explore empty state"
assertContains $emptyExplore {0 matches} "Explore empty count"

set searchedExplore [::fossilhub::views::renderExplore [list $repository] \
  [dict create q {Tcl & SQLite} kind wiki sort name]]
assertContains $searchedExplore {value="Tcl &amp; SQLite"} \
  "Explore query escaped"
assertContains $searchedExplore {name="kind" value="wiki"} \
  "Explore filter rendered"
assertContains $searchedExplore {value="name" selected} \
  "Explore sort rendered"

set page [::fossilhub::views::renderRepository $repository]
assertContains $page {<h1>dig.fossil</h1>} "repository heading"
assertContains $page {A live &amp; durable repository} \
  "repository description escaped"
assertContains $page {FossilHub &lt;Demo&gt;} "project name escaped"
assertContains $page {Ship &lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;} \
  "repository event escaped"
assertContains $page {<b>1,284</b><span>artifacts in one file</span>} \
  "repository artifact count"
assertContains $page {Fossil read-only SQL} "repository source label"
assertContains $page {data-hub-path="/repo/dig.fossil/files"} \
  "repository internal file navigation"
assertNotContains $page {data-fossil-path} \
  "repository browser navigation avoids native Fossil"
assertNotContains $page {href="/fossil/} \
  "repository has no native Fossil hyperlink"
assertNotContains $page {<script>alert("x")</script>} \
  "repository event cannot inject markup"
assertNotContains $page {c-a17f3b} "repository prototype hash removed"
assertNotContains $page {SSR_TIMELINE} "SSR implementation markers removed"
assertNotContains $page {@@REPOSITORY_NAME@@} "SSR placeholders resolved"
assertNotContains $page {@@VISIBILITY@@} "repository visibility placeholder resolved"
assertNotContains $page {@@} "repository placeholders resolved"

set safeMarkup [::fossilhub::markup::render \
  {# Heading

<script>alert(1)</script>

[safe](https://example.test) [unsafe](javascript:alert(1))} \
  text/x-markdown]
assertContains $safeMarkup {<h1>Heading</h1>} "Markdown heading rendered"
assertContains $safeMarkup {href="https://example.test"} "safe markup link"
assertContains $safeMarkup {&lt;script&gt;alert(1)&lt;/script&gt;} \
  "raw markup escaped"
assertNotContains $safeMarkup {href="javascript:} "unsafe markup scheme rejected"

set timelineEvent [dict create rid 7 type ci epoch 1787788800 \
  uuid [string repeat a 64] user alice comment {Check <safe>} branch trunk \
  sort_milliseconds 1787788800000]
set richTimeline [::fossilhub::views::renderRepository $repository timeline \
  [dict create timeline [dict create events [list $timelineEvent] \
      next_cursor 1787788800000:7 options {}] \
    request_options [dict create q {<query>} type ci author alice branch trunk \
      tag v1 from 0 to 0 from_date 2026-08-26 to_date 2026-08-27 cursor {} limit 30] \
    branches [list [dict create name trunk uuid [string repeat a 64] \
      epoch 1787788800 checkins 2]] \
    tags [list [dict create name v1 uuid [string repeat a 64] \
      epoch 1787788800 user alice comment release]]]]
assertContains $richTimeline {name="q" value="&lt;query&gt;"} \
  "timeline search escaped"
assertContains $richTimeline {/repo/dig.fossil/checkin/aaaaaaaa} \
  "timeline check-in link"

set checkinFixture [dict create rid 7 uuid [string repeat a 64] \
  epoch 1787788800 user alice comment {Merge <feature>} branch trunk tags {v1} \
  additions 3 deletions 1 parents [list [dict create uuid [string repeat b 64] \
    epoch 1 comment parent user alice primary 1]] children {} \
  changes [list [dict create change modified filename README.md \
    previous_filename {} uuid [string repeat c 64] previous_uuid [string repeat d 64] \
    size 12 previous_size 8 permissions 0 additions 3 deletions 1]]]
set treePage [::fossilhub::views::renderRepository $repository tree \
  [dict create tree [dict create checkin $checkinFixture directory {} entries \
      [list [dict create type directory name docs path docs uuid {} size 0] \
        [dict create type file name README.md path README.md \
          uuid [string repeat c 64] size 12]]] \
    branches {} can_write 1]]
assertContains $treePage {/repo/dig.fossil/tree/aaaaaaaa} \
  "versioned tree route rendered"
assertContains $treePage {Download ZIP} "tree archive action"
assertContains $treePage {class="tab active" href="#" data-hub-path="/repo/dig.fossil/files"} \
  "tree keeps Files tab active"

set checkinPage [::fossilhub::views::renderRepository $repository checkin \
  [dict create checkin $checkinFixture diff [dict create \
    content "--- README.md\n+++ README.md\n+<safe>\n" truncated 0 reason {}]]]
assertContains $checkinPage {Merge &lt;feature&gt;} "check-in comment escaped"
assertContains $checkinPage {+3 −1} "check-in line statistics"
assertContains $checkinPage {+&lt;safe&gt;} "unified diff escaped"

set privateRepository [dict merge $repository [dict create visibility private]]
set privatePage [::fossilhub::views::renderRepository $privateRepository]
assertContains $privatePage {PRIVATE · LIVE FOSSIL 2.29} \
  "private repository visibility label"
assertContains $privatePage {Private repository · browser members only} \
  "private repository transport notice"
assertNotContains $privatePage {data-clone-command} \
  "private repository hides clone transport"

set files [list [dict create \
  filename {docs/<guide>.md} uuid abcdef1234567890 size 2048 extension .md]]
set filesPage [::fossilhub::views::renderRepository $repository files \
  [dict create files $files can_write 1]]
assertContains $filesPage {docs/&lt;guide&gt;.md} "file name escaped"
assertContains $filesPage {/repo/dig.fossil/file/abcdef1234567890} \
  "file artifact route"
assertContains $filesPage {class="tab active" href="#" data-hub-path="/repo/dig.fossil/files"} \
  "files tab active"
assertContains $filesPage {data-hub-path="/repo/dig.fossil/files/new"} \
  "file write action"

set wikiPage [::fossilhub::views::renderRepository $repository wiki-page \
  [dict create page [dict create title {Welcome <all>} uuid abcdef1234567890 \
    epoch 1787788800 content {# Hello <script>alert(1)</script>}] \
    can_write 1]]
assertContains $wikiPage {Welcome &lt;all&gt;} "wiki title escaped"
assertContains $wikiPage {&lt;script&gt;alert(1)&lt;/script&gt;} \
  "wiki content escaped"
assertContains $wikiPage {class="tab active" href="#" data-hub-path="/repo/dig.fossil/wiki"} \
  "wiki tab active"
assertContains $wikiPage \
  {data-hub-path="/repo/dig.fossil/wiki-page/abcdef1234567890/edit"} \
  "Wiki edit action"

set fileCompose [::fossilhub::views::renderRepository $repository \
  file-compose [dict create operation create file "" message {Bad <path>} \
    values [dict create filename {docs/<guide>.md} content {<script>x</script>} \
      message {Add <guide>} branch trunk] head [string repeat a 40] \
    branch trunk branches {feature trunk} \
    csrf [string repeat b 64]]]
assertContains $fileCompose {Bad &lt;path&gt;} \
  "file workbench notice escaped"
assertContains $fileCompose {docs/&lt;guide&gt;.md} \
  "file workbench path escaped"
assertContains $fileCompose {&lt;script&gt;x&lt;/script&gt;} \
  "file workbench content escaped"
assertContains $fileCompose {name="expected" value="aaaaaaaa} \
  "file workbench optimistic revision"
assertContains $fileCompose {<option value="trunk" selected>trunk</option>} \
  "file workbench branch selection"
assertContains $fileCompose \
  {class="tab active" href="#" data-hub-path="/repo/dig.fossil/files"} \
  "file workbench tab active"

set binaryCompose [::fossilhub::views::renderRepository $repository \
  file-compose [dict create operation edit message "" head [string repeat c 40] \
    branch trunk branches {trunk} \
    file [dict create filename specimen.bin uuid [string repeat d 40] text 0] \
    values [dict create content "" message {Update binary} \
      next_filename specimen.bin branch trunk] \
    csrf_save [string repeat 1 64] csrf_rename [string repeat 2 64] \
    csrf_delete [string repeat 3 64]]]
assertContains $binaryCompose {Binary content cannot be edited in the browser} \
  "binary artifact edit guard"
assertNotContains $binaryCompose {name="operation" value="save"} \
  "binary artifact has no save form"

set ticketRecord [dict create uuid [string repeat c 40] \
  title {Ticket <one>} status Open type Code_Defect severity Important \
  epoch 1787788800 comment {Unsafe <comment>}]
set ticketWorkbench [::fossilhub::views::renderRepository $repository \
  ticket-workbench [dict create ticket $ticketRecord revision \
    [string repeat d 40] message "" comment "" \
    csrf_comment [string repeat e 64] csrf_status [string repeat f 64] \
    csrf_update [string repeat 1 64]]]
assertContains $ticketWorkbench {Ticket &lt;one&gt;} \
  "Ticket workbench title escaped"
assertContains $ticketWorkbench {Unsafe &lt;comment&gt;} \
  "Ticket workbench comment escaped"
assertContains $ticketWorkbench {name="action" value="comment"} \
  "Ticket comment action"
assertContains $ticketWorkbench {name="action" value="update"} \
  "Ticket field update action"

set anonymousContext [dict create \
  authenticated 0 user "" session_hash "" token "" logout_token ""]
set loginPage [::fossilhub::views::renderLogin \
  $anonymousContext [string repeat a 64] {Invalid <account>} {alice&admin}]
assertContains $loginPage {action="login" method="post" data-hub-action="/login"} \
  "login mount-safe form action"
assertContains $loginPage {Invalid &lt;account&gt;} "login error escaped"
assertContains $loginPage {value="alice&amp;admin"} "login identity escaped"
assertContains $loginPage {autocomplete="current-password"} \
  "login password autocomplete"

set registerPage [::fossilhub::views::renderRegister \
  $anonymousContext [string repeat b 64] "" \
  [dict create username alice email alice@example.test display_name Alice]]
assertContains $registerPage \
  {src="fossilhub-hub-lockup-v1.png?v=20260829-1"} \
  "account pages use the selected brand lockup"
assertContains $registerPage {minlength="12"} "registration password policy"
assertContains $registerPage {Passwords are stored with Argon2id.} \
  "registration password storage notice"

set owner [dict create id user-1 username alice email alice@example.test \
  display_name Alice biography "" website "" location "" role user \
  status active created_epoch 1 updated_epoch 1 last_login_epoch 1 \
  must_change_password 0]
set ownerContext [dict create authenticated 1 user $owner session_hash \
  [string repeat c 64] token [string repeat d 64] logout_token \
  [string repeat e 64] reauthenticated_epoch 1787788800]
set managedRepository [dict create id repository-1 slug fossil-tools \
  name fossil-tools.fossil title {Fossil <Tools>} \
  description {Collaboration & source} source_url "" category project \
  language Tcl visibility private state active owner_user_id user-1 \
  default_branch trunk featured 0 created_epoch 1 updated_epoch 1 \
  archived_epoch 0]
set member [dict create id user-1 username alice display_name Alice \
  role owner created_epoch 1]
set challenges [dict create settings [string repeat f 64] \
  member [string repeat 1 64] transfer [string repeat 2 64] \
  archive [string repeat 3 64] restore [string repeat 4 64] \
  remove:user-1 [string repeat 5 64]]
set workspace [::fossilhub::views::renderRepositoryWorkspace \
  $ownerContext [list $managedRepository]]
assertContains $workspace {Fossil &lt;Tools&gt;} \
  "repository workspace title escaped"
assertContains $workspace {data-hub-path="/account/repositories/new"} \
  "repository workspace new route"
set settings [::fossilhub::views::renderRepositorySettings $ownerContext \
  $managedRepository [list $member] $challenges {Saved <now>} {}]
assertContains $settings {Saved &lt;now&gt;} \
  "repository settings notice escaped"
assertContains $settings {class="permission-layer permission-owner"} \
  "stratigraphic permission layer"
assertContains $settings {data-hub-action="/account/repositories/fossil-tools/archive"} \
  "repository archive form route"
assertNotContains $settings {Fossil <Tools>} \
  "repository settings title cannot inject markup"

set dashboardData [dict create owned [list $managedRepository] \
  collaborations {} tickets [list [dict create uuid [string repeat 6 40] \
    title {Fix <unsafe>} status Open epoch 1787788800 \
    repository_slug fossil-tools repository_title {Fossil <Tools>}]] \
  activity [list [dict create action repository.file-edit outcome success \
    target README.md epoch 1787788800 repository_slug fossil-tools \
    repository_title {Fossil <Tools>}]]]
set dashboardPage [::fossilhub::views::renderDashboard $ownerContext \
  $dashboardData]
assertContains $dashboardPage {data-hub-path="/repositories/new"} \
  "dashboard new repository action"
assertContains $dashboardPage {Fix &lt;unsafe&gt;} \
  "dashboard Ticket title escaped"
assertNotContains $dashboardPage {Fossil <Tools>} \
  "dashboard repository content escaped"

set profilePage [::fossilhub::views::renderPublicProfile $ownerContext \
  [dict create user [dict replace $owner biography {Bio <unsafe>} \
    website https://example.test location Ridge] \
    repositories [list $managedRepository] activity {}]]
assertContains $profilePage {Bio &lt;unsafe&gt;} \
  "public profile biography escaped"
assertContains $profilePage {rel="nofollow me"} \
  "public profile website relationship"

set settingsPage [::fossilhub::views::renderSettings $ownerContext \
  [string repeat 7 64] [string repeat 8 64] {Saved <now>} \
  [dict replace $owner biography {Bio <unsafe>} website {} location {}]]
assertContains $settingsPage {Saved &lt;now&gt;} \
  "profile settings notice escaped"
assertContains $settingsPage {data-hub-action="/settings/deactivate"} \
  "account deactivation action"
assertContains $settingsPage {data-theme-choice="system"} \
  "account theme preference"
assertContains $settingsPage {prefers-color-scheme: dark} \
  "account system theme follows browser preference"

set adminUser [dict replace $owner role administrator \
  email {admin@example.test}]
set adminContext [dict replace $ownerContext user $adminUser]
set auditEvent [dict create id [string repeat 9 32] \
  action admin.settings outcome success target {} epoch 1787788800 \
  actor alice repository_slug {}]
set overviewPage [::fossilhub::views::renderAdminOverview $adminContext \
  [dict create users 2 active_users 2 inactive_users 0 repositories 10 \
    active_repositories 9 inactive_repositories 1 activity_24h 4 \
    failures_24h 0 storage_bytes 4096 readable_repositories 9] \
  [list $auditEvent]]
assertContains $overviewPage {data-hub-path="/admin/users"} \
  "administrator navigation"
assertContains $overviewPage {Safe platform totals} \
  "administrator overview summary"

set listedAdmin [dict replace $adminUser repository_count 2 session_count 1]
set usersPage [::fossilhub::views::renderAdminUsers $adminContext \
  [list $listedAdmin] [dict create q {alice<script>} status all role all]]
assertContains $usersPage {alice&lt;script&gt;} \
  "administrator user query escaped"
assertContains $usersPage {data-hub-path="/admin/users/user-1"} \
  "administrator user detail link"

set detailedAdmin [dict replace $adminUser repositories \
  [list $managedRepository] sessions {} activity [list $auditEvent]]
set adminUserPage [::fossilhub::views::renderAdminUser $adminContext \
  $detailedAdmin [dict create role [string repeat a 64] \
    status [string repeat b 64] sessions [string repeat c 64]]]
assertContains $adminUserPage {data-hub-action="/admin/users/user-1/role"} \
  "administrator user role action"
assertContains $adminUserPage {Revoke all sessions} \
  "administrator session revocation action"

set adminRepository [dict replace $managedRepository owner_username alice \
  owner_display_name Alice]
set repositoriesPage [::fossilhub::views::renderAdminRepositories \
  $adminContext [list $adminRepository] \
  [dict create q {} state all visibility all]]
assertContains $repositoriesPage {data-hub-path="/admin/repositories/fossil-tools"} \
  "administrator repository detail link"
set adminRepositoryPage [::fossilhub::views::renderAdminRepository \
  $adminContext $adminRepository [dict create archive [string repeat d 64] \
    restore [string repeat e 64] integrity [string repeat f 64]]]
assertContains $adminRepositoryPage \
  {data-hub-action="/admin/repositories/fossil-tools/integrity"} \
  "administrator integrity action"

set auditPage [::fossilhub::views::renderAdminAudit $adminContext \
  [list $auditEvent] [dict create q {} outcome all action {}]]
assertContains $auditPage {data-hub-path="/admin/audit.csv?} \
  "administrator audit export route"
assertNotContains $auditPage {request_id} \
  "administrator audit request identifier hidden"

set healthPage [::fossilhub::views::renderAdminHealth $adminContext \
  [dict create platform_database ok catalogue_database ok repository_count 10 \
    readable_repositories 10 file_modes_ok 1 file_ownership_ok 1 \
    storage_bytes 1024 storage_capacity_bytes 2048 storage_status ok \
    catalogue_indexed_epoch 1787788800 revision abc123] [string repeat 1 64]]
assertContains $healthPage {data-hub-action="/admin/health/reindex"} \
  "administrator catalogue rebuild action"

set adminSettingsPage [::fossilhub::views::renderAdminSettings $adminContext \
  [dict create registration open default_visibility public \
    repositories_per_user 100 repository_quota_mb 512 \
    maintenance_banner {Notice <unsafe>}] [string repeat 2 64]]
assertContains $adminSettingsPage {Notice &lt;unsafe&gt;} \
  "administrator maintenance banner escaped"
assertNotContains $adminSettingsPage {password_hash} \
  "administrator settings omit secrets"

set reauthPage [::fossilhub::views::renderAdminReauth $adminContext \
  [string repeat 3 64] users/user-1]
assertContains $reauthPage {autocomplete="current-password"} \
  "administrator reauthentication password field"

set manualPage [::fossilhub::views::renderPublicInformation $anonymousContext \
  manual [::fossilhub::views::publicDefinition manual]]
assertContains $manualPage {data-hub-path="/status"} \
  "public information navigation"
assertContains $manualPage {Read the strata} "field manual heading"

set releasesPage [::fossilhub::views::renderReleases $anonymousContext \
  {# Release <unsafe>

- Fixed **safe** rendering.} 2026.08.27-test]
assertContains $releasesPage {Release &lt;unsafe&gt;} \
  "release notes markup escaped"
assertNotContains $releasesPage {Release <unsafe>} \
  "release notes raw markup hidden"

set publicStatusPage [::fossilhub::views::renderPublicStatus $anonymousContext \
  [dict create platform_database ok catalogue_database ok repository_count 10 \
    readable_repositories 10 file_modes_ok 1 storage_status ok \
    catalogue_indexed_epoch 1787788800] 2026.08.27-test {Notice <unsafe>}]
assertContains $publicStatusPage {Notice &lt;unsafe&gt;} \
  "public status maintenance notice escaped"
assertNotContains $publicStatusPage {/data/} \
  "public status omits filesystem paths"
assertNotContains $publicStatusPage {repository_slug} \
  "public status omits repository identities"

::fossilhub::i18n::use zh-CN
set chineseHome [::fossilhub::views::renderHome $repository $anonymousContext]
assertContains $chineseHome {<html lang="zh-CN">} \
  "Chinese home language marker"
assertContains $chineseHome {整个项目，凝结在一块<em>岩石</em>中。} \
  "Chinese home hero"
assertContains $chineseHome {data-hub-path="/login">登录</a>} \
  "Chinese anonymous sign-in entry"
assertContains $chineseHome {data-hub-action="/locale"} \
  "home language switch form"

set chineseLogin [::fossilhub::views::renderLogin \
  $anonymousContext [string repeat a 64]]
assertContains $chineseLogin {<html lang="zh-CN">} \
  "Chinese account language marker"
assertContains $chineseLogin {用户名或邮箱<input} \
  "Chinese login field"
assertContains $chineseLogin {type="submit">登录</button>} \
  "Chinese login action"

set chineseAdmin [::fossilhub::views::siteTools $adminContext]
assertContains $chineseAdmin {data-hub-path="/admin">管理</a>} \
  "Chinese administrator entry"
assertContains $chineseAdmin \
  {data-hub-path="/account/repositories">我的仓库</a>} \
  "Chinese repository management entry"
::fossilhub::i18n::use en

puts "view tests passed"
