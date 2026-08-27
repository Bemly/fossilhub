set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib repository-manifest.tcl]
source [file join $projectRoot app lib platform-model.tcl]

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

set handle [file tempfile temporaryMarker fossilhub-platform-test]
close $handle
file delete $temporaryMarker
file mkdir $temporaryMarker
set database [file join $temporaryMarker platform.sqlite]
set ::env(FOSSILHUB_PLATFORM_DB) $database
if {![info exists ::env(FOSSILHUB_SQLITE)]} {
  set ::env(FOSSILHUB_SQLITE) /usr/bin/sqlite3
}

try {
  assertEqual [::fossilhub::platform::initialize] 1 \
    "initial platform schema"
  assertTrue [file isfile $database] "platform database created"
  assertEqual [::fossilhub::platform::databaseVersion] 1 \
    "platform schema version"
  assertEqual [llength [::fossilhub::platform::publicRepositories]] 10 \
    "seed repository count"
  assertEqual [dict get [::fossilhub::platform::publicRepository \
    bedrock.fossil] slug] bedrock "seed repository lookup"
  assertTrue [::fossilhub::platform::publicContains BEDROCK.FOSSIL] \
    "case-insensitive repository lookup"
  assertTrue [expr {![::fossilhub::platform::publicContains dig.fossil]}] \
    "legacy repository remains unpublished"

  set before [file size $database]
  assertEqual [::fossilhub::platform::initialize] 1 \
    "idempotent platform initialization"
  assertEqual [llength [::fossilhub::platform::publicRepositories]] 10 \
    "idempotent repository seed"
  assertEqual [file size $database] $before \
    "idempotent database size"

  set malicious [::fossilhub::platform::publicRepository \
    {bedrock.fossil' OR 1=1 --}]
  assertEqual $malicious "" "repository lookup treats SQL as data"

  set integrity [exec [::fossilhub::platform::sqliteBinary] \
    -batch -noheader $database {PRAGMA quick_check;}]
  assertEqual [string trim $integrity] ok "platform integrity"
  assertEqual [format %04o [expr {
    [file attributes $database -permissions] & 0o777}]] 0600 \
    "platform database permissions"
} finally {
  file delete -force $temporaryMarker
}

puts "platform tests passed"
