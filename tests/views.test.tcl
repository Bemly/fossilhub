set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib view.tcl]
source [file join $projectRoot app lib catalog-model.tcl]
source [file join $projectRoot app lib repository-service.tcl]
source [file join $projectRoot app views home.tcl]
source [file join $projectRoot app views explore.tcl]
source [file join $projectRoot app views repository-sections.tcl]
source [file join $projectRoot app views repository.tcl]
source [file join $projectRoot app views account.tcl]
source [file join $projectRoot app views repository-management.tcl]

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

set explore [::fossilhub::views::renderExplore [list $repository]]
assertContains $explore {1 match} "Explore live count"
assertContains $explore {SHOWING 1 — INDEXED IN SQLITE} \
  "Explore SQLite source"
assertContains $explore {A live &amp; durable repository} \
  "Explore description escaped"
assertContains $explore {repo/dig.fossil} "Explore repository route"
assertNotContains $explore {12,408} "Explore prototype count removed"
assertNotContains $explore {amber.fossil} "Explore prototype repository removed"

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
  [dict create files $files]]
assertContains $filesPage {docs/&lt;guide&gt;.md} "file name escaped"
assertContains $filesPage {/repo/dig.fossil/file/abcdef1234567890} \
  "file artifact route"
assertContains $filesPage {class="tab active" href="#" data-hub-path="/repo/dig.fossil/files"} \
  "files tab active"

set wikiPage [::fossilhub::views::renderRepository $repository wiki-page \
  [dict create page [dict create title {Welcome <all>} uuid abcdef1234567890 \
    epoch 1787788800 content {# Hello <script>alert(1)</script>}]]]
assertContains $wikiPage {Welcome &lt;all&gt;} "wiki title escaped"
assertContains $wikiPage {&lt;script&gt;alert(1)&lt;/script&gt;} \
  "wiki content escaped"
assertContains $wikiPage {class="tab active" href="#" data-hub-path="/repo/dig.fossil/wiki"} \
  "wiki tab active"

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

puts "view tests passed"
