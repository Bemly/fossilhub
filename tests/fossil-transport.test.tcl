set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib repository-manifest.tcl]
source [file join $projectRoot app lib platform-model.tcl]

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

set handle [file tempfile temporaryMarker fossilhub-transport-test]
close $handle
file delete $temporaryMarker
file mkdir $temporaryMarker
set database [file join $temporaryMarker platform.sqlite]
set repositories [file join $temporaryMarker repositories]
set tempRoot [file join $temporaryMarker temporary]
file mkdir $repositories $tempRoot

set ::env(FOSSILHUB_PLATFORM_DB) $database
set ::env(FOSSILHUB_REPOSITORY_DIR) $repositories
set ::env(FOSSILHUB_SQLITE) /usr/bin/sqlite3
set ::env(FOSSILHUB_FOSSIL) \
  [file join $projectRoot tests fixtures fake-fossil]
set ::env(TMPDIR) $tempRoot

proc repositoryFile {path} {
  set channel [open $path w]
  puts $channel fixture
  close $channel
  file attributes $path -permissions 0600
}

proc transportRequest {projectRoot pathInfo} {
  exec env \
    PATH_INFO=$pathInfo \
    SCRIPT_NAME=/fossil \
    REQUEST_METHOD=GET \
    REQUEST_URI=/fossil$pathInfo \
    GATEWAY_INTERFACE=CGI/1.0 \
    FOSSILHUB_PLATFORM_DB=$::env(FOSSILHUB_PLATFORM_DB) \
    FOSSILHUB_REPOSITORY_DIR=$::env(FOSSILHUB_REPOSITORY_DIR) \
    FOSSILHUB_SQLITE=$::env(FOSSILHUB_SQLITE) \
    FOSSILHUB_FOSSIL=$::env(FOSSILHUB_FOSSIL) \
    TMPDIR=$::env(TMPDIR) \
    [info nameofexecutable] [file join $projectRoot app cgi fossil]
}

try {
  ::fossilhub::platform::initialize
  repositoryFile [file join $repositories bedrock.fossil]
  repositoryFile [file join $repositories secret-layer.fossil]
  set now [clock seconds]
  ::fossilhub::platform::execute $database [format {
    INSERT INTO repositories VALUES(
      'private-fixture','secret-layer','secret-layer.fossil','Secret Layer','',
      '','project','Not set','private','active',NULL,'trunk',0,%d,%d,0
    );
  } $now $now]

  set root [transportRequest $projectRoot /]
  assertContains $root {Status: 404 Not Found} \
    "transport root has no repository listing"
  assertNotContains $root bedrock "transport root hides public names"
  assertNotContains $root secret "transport root hides private names"

  set private [transportRequest $projectRoot /secret-layer/]
  assertContains $private {Status: 404 Not Found} \
    "private repository transport denied"
  assertNotContains $private secret-layer \
    "private transport response hides repository identity"

  set traversal [transportRequest $projectRoot /../secret-layer]
  assertContains $traversal {Status: 404 Not Found} \
    "transport traversal rejected"

  set public [transportRequest $projectRoot /bedrock/timeline]
  assertContains $public {Status: 200 OK} "public transport admitted"
  assertContains $public {fake public transport /fossil/bedrock /timeline} \
    "public transport rewrites Fossil path"
  assertNotContains $public secret-layer \
    "public transport does not expose private identity"
  if {[llength [glob -nocomplain -directory $tempRoot \
      fossilhub-public-cgi*]] != 0} {
    fail "transport temporary configuration was not removed"
  }
} finally {
  file delete -force $temporaryMarker
}

puts "Fossil transport tests passed"
