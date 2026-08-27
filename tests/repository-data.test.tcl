set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib fossil-model.tcl]

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

set fossil [::fossilhub::model::fossilBinary]
if {![file executable $fossil]} {
  fail "Fossil binary is unavailable for repository data tests"
}

set handle [file tempfile marker fossilhub-repository-test]
close $handle
file delete $marker
file mkdir $marker
set repositoryDirectory [file join $marker repositories]
set checkout [file join $marker checkout]
set repository [file join $repositoryDirectory sqlite.fossil]
file mkdir $repositoryDirectory $checkout
set ::env(FOSSILHUB_REPOSITORY_DIR) $repositoryDirectory
set ::env(GATEWAY_INTERFACE) CGI/1.1

try {
  exec $fossil --nocgi init --admin-user fossilhub \
    --project-name {Repository data fixture} $repository
  assertEqual [::fossilhub::model::files sqlite.fossil] {} \
    "empty repository has no trunk files"

  set priorDirectory [pwd]
  try {
    cd $checkout
    exec $fossil --nocgi open $repository
    set readme [open README.md w]
    fconfigure $readme -encoding utf-8 -translation lf
    puts $readme "# Repository fixture\n\nA Tcl-owned read path."
    close $readme
    exec $fossil --nocgi add README.md
    exec $fossil --nocgi commit --no-warnings --user fossilhub \
      --comment {Seed repository data fixture}
  } finally {
    cd $priorDirectory
  }

  set wikiSource [file join $marker wiki.md]
  set wiki [open $wikiSource w]
  fconfigure $wiki -encoding utf-8 -translation lf
  puts $wiki "# Field notes\n\nRead through Tcl SSR."
  close $wiki
  exec $fossil --nocgi wiki create Welcome $wikiSource --mimetype markdown \
    --user fossilhub --repository $repository
  exec $fossil --nocgi ticket add title {Data-layer ticket} type Code_Defect \
    status Open severity Important comment {Stored in Fossil} \
    --user fossilhub --repository $repository

  set files [::fossilhub::model::files sqlite.fossil]
  assertEqual [llength $files] 1 "trunk file count"
  assertEqual [dict get [lindex $files 0] filename] README.md \
    "trunk filename"
  set file [::fossilhub::model::fileRecord sqlite.fossil \
    [dict get [lindex $files 0] uuid]]
  assertTrue [dict get $file text] "README classified as text"
  assertTrue [expr {[string first {Tcl-owned} [dict get $file content]] >= 0}] \
    "file artifact content"

  set docs [::fossilhub::model::documentationFiles sqlite.fossil]
  assertEqual [llength $docs] 1 "documentation index"

  set pages [::fossilhub::model::wikiPages sqlite.fossil]
  assertEqual [llength $pages] 1 "wiki page count"
  set page [::fossilhub::model::wikiContent sqlite.fossil \
    [dict get [lindex $pages 0] uuid]]
  assertEqual [dict get $page title] Welcome "wiki title"
  assertTrue [expr {[string first {Read through Tcl SSR.} \
    [dict get $page content]] >= 0}] "wiki artifact content"

  set tickets [::fossilhub::model::tickets sqlite.fossil]
  assertEqual [llength $tickets] 1 "ticket count"
  assertEqual [dict get [lindex $tickets 0] title] {Data-layer ticket} \
    "ticket title"

  assertEqual [catch {::fossilhub::model::fileRecord \
    sqlite.fossil {abc'; DROP TABLE blob; --}}] 1 \
    "artifact injection rejected"
} finally {
  file delete -force $marker
}

puts "repository data tests passed"
