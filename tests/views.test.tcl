set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib view.tcl]
source [file join $projectRoot app views home.tcl]
source [file join $projectRoot app views explore.tcl]
source [file join $projectRoot app views repository.tcl]

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
assertContains $explore {1 live digs — queried from Fossil at request time} \
  "Explore live count"
assertContains $explore {A live &amp; durable repository} \
  "Explore description escaped"
assertContains $explore {repo/dig.fossil} "Explore repository route"
assertNotContains $explore {12,408} "Explore prototype count removed"
assertNotContains $explore {amber.fossil} "Explore prototype repository removed"

set emptyExplore [::fossilhub::views::renderExplore {}]
assertContains $emptyExplore {No Fossil repositories are available yet.} \
  "Explore empty state"
assertContains $emptyExplore {0 live digs} "Explore empty count"

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
assertNotContains $page {<script>alert("x")</script>} \
  "repository event cannot inject markup"
assertNotContains $page {c-a17f3b} "repository prototype hash removed"
assertNotContains $page {SSR_TIMELINE} "SSR implementation markers removed"
assertNotContains $page {@@REPOSITORY_NAME@@} "SSR placeholders resolved"

puts "view tests passed"
