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

assertTrue [::fossilhub::model::validRepositoryName dig.fossil] \
  "simple repository name"
assertTrue [::fossilhub::model::validRepositoryName core-v2.fossil] \
  "hyphenated repository name"
assertTrue [expr {![::fossilhub::model::validRepositoryName ../dig.fossil]}] \
  "parent traversal rejected"
assertTrue [expr {![::fossilhub::model::validRepositoryName dig.db]}] \
  "non-Fossil suffix rejected"
assertTrue [expr {![::fossilhub::model::validRepositoryName {bad name.fossil}]}] \
  "whitespace rejected"

set encoded "6469672E666F7373696C\tE59CB0E8B4A8E5B182\n"
assertEqual [::fossilhub::model::decodeRows $encoded 2] \
  [list [list dig.fossil 地质层]] \
  "UTF-8 hexadecimal rows"

set malformedResult [catch {
  ::fossilhub::model::decodeRows "41\t42\t43\n" 2
}]
assertEqual $malformedResult 1 "malformed row rejected"

set timelineSql [::fossilhub::model::timelineSql 17]
assertTrue [expr {[string first "LIMIT 17" $timelineSql] >= 0}] \
  "timeline limit embedded as integer"
assertEqual [catch {::fossilhub::model::timelineSql {1; DROP TABLE event}}] 1 \
  "timeline SQL injection rejected"
assertTrue [::fossilhub::model::validArtifactId abcdef1234567890] \
  "artifact id accepted"
assertTrue [expr {![::fossilhub::model::validArtifactId \
  {abc'; DROP TABLE blob; --}]}] "artifact injection rejected"
assertEqual [catch {::fossilhub::model::validatedLimit \
  {10; DELETE FROM event}}] 1 "result limit injection rejected"
assertTrue [expr {[string first {files_of_checkin('trunk')} \
  [::fossilhub::model::filesSql]] >= 0}] "trunk file query"

set fixture [file normalize [info script]]
set model [::fossilhub::model::repositoryFromRows \
  dig.fossil \
  $fixture \
  [list \
    [list project_name {FossilHub Demo Dig}] \
    [list description {A live repository}] \
    [list artifacts 12] \
    [list contributors 2] \
    [list latest_epoch 1787788800]] \
  [list [list ci 1787788800 a1b2c3d4e5 fossilhub {Initial check-in}]]]

assertEqual [dict get $model project_name] {FossilHub Demo Dig} \
  "metadata projected"
assertEqual [dict get $model artifacts] 12 "numeric metadata projected"
assertEqual [dict get [lindex [dict get $model events] 0] comment] \
  {Initial check-in} "timeline projected"
assertTrue [expr {[dict get $model bytes] > 0}] "repository size projected"

puts "model tests passed"
