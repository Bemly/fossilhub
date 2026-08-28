set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib fossil-model.tcl]
source [file join $projectRoot app lib history-model.tcl]

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

proc writeText {path content} {
  file mkdir [file dirname $path]
  set channel [open $path w]
  try {
    fconfigure $channel -encoding utf-8 -translation lf
    puts -nonewline $channel $content
  } finally {
    close $channel
  }
}

proc writeBinary {path bytes} {
  file mkdir [file dirname $path]
  set channel [open $path w]
  try {
    fconfigure $channel -encoding iso8859-1 -translation binary
    puts -nonewline $channel $bytes
  } finally {
    close $channel
  }
}

proc commitFixture {fossil checkout comment} {
  exec $fossil --nocgi --chdir $checkout commit --no-warnings --nosign \
    --nosync --user reader --comment $comment
}

set fossil [::fossilhub::model::fossilBinary]
if {![file executable $fossil]} {
  fail "Fossil binary is unavailable for history model tests"
}

set handle [file tempfile marker fossilhub-history-model-test]
close $handle
file delete $marker
file mkdir $marker
set repositoryDirectory [file join $marker repositories]
set checkout [file join $marker checkout]
set repository [file join $repositoryDirectory history.fossil]
set emptyRepository [file join $repositoryDirectory empty.fossil]
file mkdir $repositoryDirectory $checkout
set ::env(FOSSILHUB_REPOSITORY_DIR) $repositoryDirectory
set ::env(GATEWAY_INTERFACE) CGI/1.1

try {
  exec $fossil --nocgi init --admin-user reader \
    --project-name {History fixture} $repository
  exec $fossil --nocgi init --admin-user reader \
    --project-name {Empty history fixture} $emptyRepository
  exec $fossil --nocgi open $repository --workdir $checkout

  writeText [file join $checkout README.md] \
    "# History fixture\n\nFirst line.\n"
  writeText [file join $checkout old.txt] "rename origin\n"
  writeText [file join $checkout docs guide.md] \
    "# Guide\n\n<script>alert('hostile')</script>\n"
  writeText [file join $checkout 资料 说明.txt] "地层记录\n"
  exec $fossil --nocgi --chdir $checkout add README.md old.txt \
    docs/guide.md 资料/说明.txt
  commitFixture $fossil $checkout {Seed history fixture}

  writeText [file join $checkout README.md] \
    "# History fixture\n\nSecond line.\nA third line.\n"
  exec $fossil --nocgi --chdir $checkout mv --hard old.txt renamed.txt
  writeBinary [file join $checkout image.bin] [binary format H* 0001ff8042]
  exec $fossil --nocgi --chdir $checkout add image.bin
  commitFixture $fossil $checkout {Update, rename, and add binary}

  exec $fossil --nocgi --user reader branch new feature trunk \
    --repository $repository --nosync --nosign
  exec $fossil --nocgi --chdir $checkout update feature --user reader
  writeText [file join $checkout FEATURE.md] "feature branch\n"
  exec $fossil --nocgi --chdir $checkout add FEATURE.md
  commitFixture $fossil $checkout {Feature work}

  exec $fossil --nocgi --chdir $checkout update trunk --user reader
  writeText [file join $checkout TRUNK.md] "trunk work\n"
  exec $fossil --nocgi --chdir $checkout add TRUNK.md
  commitFixture $fossil $checkout {Trunk work}
  exec $fossil --nocgi --chdir $checkout merge feature --user reader
  commitFixture $fossil $checkout {Merge feature}
  exec $fossil --nocgi tag add v1 trunk --repository $repository \
    --user reader

  set wikiPath [file join $marker wiki.md]
  writeText $wikiPath "# Home\n\n<script>alert('wiki')</script>\n"
  exec $fossil --nocgi wiki create Home $wikiPath --mimetype markdown \
    --user reader --repository $repository
  writeText $wikiPath "# Home\n\nSafe second revision.\n"
  exec $fossil --nocgi wiki commit Home $wikiPath --mimetype markdown \
    --user reader --repository $repository

  exec $fossil --nocgi ticket add title {History ticket} type Task \
    status Open severity Important comment {Initial ticket body} \
    --user reader --repository $repository
  set ticketId [dict get [lindex \
    [::fossilhub::model::tickets history.fossil] 0] uuid]
  exec $fossil --nocgi ticket set $ticketId +comment {Second ticket note} \
    --user reader --repository $repository

  set emptyTree [::fossilhub::history::tree empty.fossil \
    [dict get [lindex [dict get [::fossilhub::history::timeline \
      empty.fossil [dict create type ci]] events] 0] uuid]]
  assertEqual [dict get $emptyTree entries] {} "empty repository tree"

  set allPage [::fossilhub::history::timeline history.fossil \
    [dict create limit 100]]
  set expectedCount [llength [dict get $allPage events]]
  set pagedIds {}
  set cursor ""
  for {set pageNumber 0} {$pageNumber < 100} {incr pageNumber} {
    set page [::fossilhub::history::timeline history.fossil \
      [dict create limit 2 cursor $cursor]]
    foreach event [dict get $page events] {
      lappend pagedIds [dict get $event uuid]
    }
    set cursor [dict get $page next_cursor]
    if {$cursor eq ""} {
      break
    }
  }
  assertEqual [llength $pagedIds] $expectedCount \
    "cursor pagination returns every event"
  assertEqual [llength [lsort -unique $pagedIds]] $expectedCount \
    "cursor pagination has no duplicates"
  assertTrue [expr {[llength [dict get [::fossilhub::history::timeline \
    history.fossil [dict create type w]] events]] == 2}] \
    "timeline event type filter"
  assertTrue [expr {[llength [dict get [::fossilhub::history::timeline \
    history.fossil [dict create author reader]] events]] > 0}] \
    "timeline author filter"
  assertTrue [expr {[llength [dict get [::fossilhub::history::timeline \
    history.fossil [dict create branch feature]] events]] > 0}] \
    "timeline branch filter"
  assertTrue [expr {[llength [dict get [::fossilhub::history::timeline \
    history.fossil [dict create tag v1]] events]] == 1}] \
    "timeline tag filter"
  assertEqual [llength [dict get [::fossilhub::history::timeline \
    history.fossil [dict create q %]] events]] 0 \
    "timeline search treats wildcard literally"

  set branches [::fossilhub::history::branches history.fossil]
  assertEqual [lmap branch $branches {dict get $branch name}] \
    {feature trunk} "branch index"
  set tags [::fossilhub::history::tags history.fossil]
  assertTrue [expr {[lsearch -exact \
    [lmap tag $tags {dict get $tag name}] v1] >= 0}] "tag index"

  set mergeEvent [lindex [dict get [::fossilhub::history::timeline \
    history.fossil [dict create q {Merge feature} type ci]] events] 0]
  set merge [::fossilhub::history::checkin history.fossil \
    [dict get $mergeEvent uuid]]
  assertEqual [llength [dict get $merge parents]] 2 \
    "merge check-in parents"
  assertTrue [expr {[llength [dict get $merge changes]] > 0}] \
    "merge changed files"
  set diff [::fossilhub::history::checkinDiff history.fossil \
    [dict get $merge uuid]]
  assertTrue [expr {[string first {FEATURE.md} [dict get $diff content]] >= 0}] \
    "safe unified merge diff"

  set tree [::fossilhub::history::tree history.fossil [dict get $merge uuid]]
  assertTrue [expr {[lsearch -exact [lmap entry [dict get $tree entries] {
    dict get $entry name
  }] docs] >= 0}] "root directory entry"
  set docsTree [::fossilhub::history::tree history.fossil \
    [dict get $merge uuid] docs]
  set guide [lindex [dict get $docsTree entries] 0]
  assertEqual [dict get $guide path] docs/guide.md "nested tree path"
  set guideFile [::fossilhub::history::fileAtRevision history.fossil \
    [dict get $merge uuid] [dict get $guide uuid]]
  assertTrue [expr {[string first {<script>} [dict get $guideFile content]] >= 0}] \
    "hostile source preserved for escaped rendering"
  set rootFiles [dict get $tree entries]
  set binaryEntry ""
  set renamedEntry ""
  foreach entry $rootFiles {
    if {[dict get $entry name] eq "image.bin"} { set binaryEntry $entry }
    if {[dict get $entry name] eq "renamed.txt"} { set renamedEntry $entry }
  }
  set binaryFile [::fossilhub::history::fileAtRevision history.fossil \
    [dict get $merge uuid] [dict get $binaryEntry uuid]]
  assertEqual [dict get $binaryFile text] 0 "binary file classification"
  set renamedHistory [::fossilhub::history::fileHistory history.fossil \
    [dict get $merge uuid] [dict get $renamedEntry uuid]]
  assertTrue [expr {[lsearch -exact [lmap item [dict get $renamedHistory history] {
    dict get $item change
  }] renamed] >= 0}] "file rename history"
  set blame [::fossilhub::history::blame history.fossil \
    [dict get $merge uuid] [dict get $renamedEntry uuid]]
  assertTrue [expr {[string first reader [dict get $blame content]] >= 0}] \
    "file blame author"

  set wikiHistory [::fossilhub::history::wikiHistory history.fossil Home]
  assertEqual [llength $wikiHistory] 2 "Wiki revision history"
  set wikiRevision [::fossilhub::history::wikiRevision history.fossil Home \
    [dict get [lindex $wikiHistory 0] uuid]]
  assertTrue [expr {[string first {Safe second revision} \
    [dict get $wikiRevision content]] >= 0}] "Wiki revision body"
  set ticket [::fossilhub::history::ticket history.fossil $ticketId]
  assertEqual [dict get $ticket title] {History ticket} "Ticket detail"
  assertEqual [llength [dict get $ticket history]] 2 "Ticket history"

  set stats [::fossilhub::history::statistics history.fossil]
  assertTrue [expr {[dict get $stats checkins] >= 6}] \
    "repository check-in statistics"
  assertEqual [dict get $stats tickets] 1 "repository Ticket statistics"
  set archive [::fossilhub::history::createArchive history.fossil \
    [dict get $merge uuid]]
  set archiveChannel [open [dict get $archive path] r]
  try {
    fconfigure $archiveChannel -encoding iso8859-1 -translation binary
    set signature [read $archiveChannel 2]
  } finally {
    close $archiveChannel
  }
  assertEqual $signature PK "repository ZIP signature"
  set archivePath [dict get $archive path]
  ::fossilhub::history::deleteArchive $archivePath
  assertTrue [expr {![file exists $archivePath]}] "archive cleanup"

  assertEqual [catch {::fossilhub::history::tree history.fossil \
    [dict get $merge uuid] ../escape}] 1 "tree traversal rejected"
  assertEqual [catch {::fossilhub::history::timeline history.fossil \
    [dict create cursor bad]}] 1 "invalid cursor rejected"
  assertEqual [catch {::fossilhub::history::resolveCheckin history.fossil \
    {abc'; DROP TABLE blob; --}}] 1 "revision injection rejected"
} finally {
  file delete -force $marker
}

puts "history model tests passed"
