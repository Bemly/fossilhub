set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib repository-manifest.tcl]
source [file join $projectRoot app lib fossil-model.tcl]
source [file join $projectRoot app lib catalog-model.tcl]

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

assertEqual [llength [::fossilhub::manifest::all]] 10 \
  "blank repository manifest count"
assertEqual [dict get [lindex [::fossilhub::manifest::all] 0] name] \
  bedrock.fossil "featured blank repository"

set handle [file tempfile temporaryMarker fossilhub-catalog-test]
close $handle
file delete $temporaryMarker
file mkdir $temporaryMarker
set database [file join $temporaryMarker catalogue.sqlite]
set ::env(FOSSILHUB_CATALOG_DB) $database
if {![info exists ::env(FOSSILHUB_SQLITE)]} {
  set ::env(FOSSILHUB_SQLITE) /usr/bin/sqlite3
}

set base [dict create \
  available 1 path "" source_url https://sqlite.org/src \
  project_code abcdef0123456789 artifacts 100 contributors 4 \
  open_tickets 0 opened_epoch 100 latest_epoch 300 indexed_epoch 0]
set sqlite [dict merge $base [dict create \
  name sqlite.fossil slug sqlite project_name SQLite \
  description {Canonical database engine} category database language C \
  featured 1 bytes 32000000 checkins 90 wiki_events 2 ticket_events 8 \
  forum_events 0 events [list [dict create \
    type ci epoch 300 uuid abcdef1234 user drh comment {Improve planner}]]]]
set wapp [dict merge $base [dict create \
  name wapp.fossil slug wapp project_name Wapp \
  description {Tcl web framework} source_url https://sqlite.org/wapp \
  category framework language Tcl featured 0 bytes 200000 checkins 20 \
  wiki_events 0 ticket_events 0 forum_events 1 latest_epoch 200 \
  events [list [dict create \
    type f epoch 200 uuid fedcba4321 user tester comment {Release notes}]]]]

try {
  assertEqual [::fossilhub::catalog::writeDatabase \
    [list $sqlite $wapp] $database] 2 "catalogue row count"
  assertTrue [file isfile $database] "catalogue database created"

  set all [::fossilhub::catalog::repositories]
  assertEqual [llength $all] 2 "all repositories returned"
  assertEqual [dict get [lindex $all 0] name] sqlite.fossil \
    "recent ordering"
  assertEqual [dict get [lindex [dict get [lindex $all 0] events] 0] comment] \
    {Improve planner} "event round trip"

  set byName [::fossilhub::catalog::repositories \
    [dict create q {TCL web} sort name]]
  assertEqual [llength $byName] 1 "literal text search"
  assertEqual [dict get [lindex $byName 0] name] wapp.fossil \
    "case-insensitive search"

  assertEqual [llength [::fossilhub::catalog::repositories \
    [dict create kind forum]]] 1 "forum filter"
  assertEqual [llength [::fossilhub::catalog::repositories \
    [dict create kind wiki]]] 1 "wiki filter"
  assertEqual [dict get [lindex [::fossilhub::catalog::repositories \
    [dict create sort size]] 0] name] sqlite.fossil "size ordering"

  assertEqual [llength [::fossilhub::catalog::repositories \
    [dict create q {%'}]]] 0 "wildcards treated literally"
  assertEqual [llength [::fossilhub::catalog::repositories \
    [dict create q {' OR 1=1 --}]]] 0 "SQL injection remains data"

  set normalized [::fossilhub::catalog::searchOptions \
    [dict create kind invalid sort invalid limit {1; DROP TABLE repositories}]]
  assertEqual [dict get $normalized kind] all "invalid kind normalized"
  assertEqual [dict get $normalized sort] recent "invalid sort normalized"
  assertEqual [dict get $normalized limit] 100 "invalid limit normalized"

  set integrity [exec [::fossilhub::catalog::sqliteBinary] \
    -batch -noheader $database {PRAGMA quick_check;}]
  assertEqual [string trim $integrity] ok "catalogue integrity"
} finally {
  file delete -force $temporaryMarker
}

puts "catalog tests passed"
