namespace eval ::fossilhub::mutations {
  variable maximumFileBytes 1048576
  variable maximumTextBytes 262144
  variable maximumCommitBytes 4194304
  variable defaultRepositoryQuotaBytes 536870912
  variable authorCapabilities i23fmncrw
}

proc ::fossilhub::mutations::repositoryQuotaBytes {} {
  variable defaultRepositoryQuotaBytes
  set quota $defaultRepositoryQuotaBytes
  if {[info exists ::env(FOSSILHUB_REPOSITORY_QUOTA_BYTES)] &&
      $::env(FOSSILHUB_REPOSITORY_QUOTA_BYTES) ne ""} {
    set quota $::env(FOSSILHUB_REPOSITORY_QUOTA_BYTES)
  }
  if {![string is wideinteger -strict $quota] ||
      $quota < 1048576 || $quota > 1099511627776} {
    error "Repository storage quota configuration is invalid."
  }
  return $quota
}

proc ::fossilhub::mutations::enforceQuota {repository requestedBytes} {
  variable maximumCommitBytes
  if {![string is wideinteger -strict $requestedBytes] ||
      $requestedBytes < 0 || $requestedBytes > $maximumCommitBytes} {
    error "Mutation size exceeds the repository write budget."
  }
  set projected [expr {[file size $repository] + $requestedBytes + 1048576}]
  if {$projected > [::fossilhub::mutations::repositoryQuotaBytes]} {
    error "Repository storage quota would be exceeded."
  }
}

proc ::fossilhub::mutations::utf8Length {value} {
  string length [encoding convertto utf-8 $value]
}

proc ::fossilhub::mutations::validateRevision {revision {allowEmpty 0}} {
  set revision [string tolower [string trim $revision]]
  if {$allowEmpty && $revision eq ""} {
    return ""
  }
  if {![regexp {^[[:xdigit:]]{40,64}$} $revision]} {
    error "A valid revision marker is required."
  }
  return $revision
}

proc ::fossilhub::mutations::validateMessage {message} {
  set message [string trim $message]
  if {$message eq "" || [::fossilhub::mutations::utf8Length $message] > 4096 ||
      [string first "\u0000" $message] >= 0} {
    error "Commit message must use 1–4096 UTF-8 bytes."
  }
  return $message
}

proc ::fossilhub::mutations::validateText {content maximum label} {
  if {[string first "\u0000" $content] >= 0 ||
      [::fossilhub::mutations::utf8Length $content] > $maximum} {
    error "$label exceeds the allowed UTF-8 size."
  }
  return $content
}

proc ::fossilhub::mutations::validateFilename {filename} {
  set filename [string trim $filename]
  if {$filename eq "" || [::fossilhub::mutations::utf8Length $filename] > 512 ||
      [string first "\u0000" $filename] >= 0 ||
      [string first "\\" $filename] >= 0 ||
      [string index $filename 0] in {/ -} ||
      [string index $filename end] eq "/"} {
    error "Repository filename is invalid."
  }
  foreach segment [split $filename /] {
    set normalizedSegment [string tolower $segment]
    if {$normalizedSegment in {
        {} . .. .fslckout _fossil_ .fossil .fossil-settings} ||
        [::fossilhub::mutations::utf8Length $segment] > 255 ||
        [regexp {[[:cntrl:]]} $segment]} {
      error "Repository filename is invalid."
    }
  }
  return $filename
}

proc ::fossilhub::mutations::validateWikiName {name} {
  set name [string trim $name]
  if {$name eq "" || [::fossilhub::mutations::utf8Length $name] > 160 ||
      [string first "\u0000" $name] >= 0 || [regexp {[[:cntrl:]]} $name]} {
    error "Wiki page name must use 1–160 UTF-8 bytes."
  }
  return $name
}

proc ::fossilhub::mutations::validateMimetype {mimetype} {
  set aliases [dict create \
    markdown text/x-markdown \
    fossil text/x-fossil-wiki \
    plain text/plain \
    text/x-markdown text/x-markdown \
    text/x-fossil-wiki text/x-fossil-wiki \
    text/plain text/plain]
  if {![dict exists $aliases $mimetype]} {
    error "Markup type is invalid."
  }
  return [dict get $aliases $mimetype]
}

proc ::fossilhub::mutations::validateTicketType {type} {
  if {$type ni {Code_Defect Feature_Request Incident Task}} {
    error "Ticket type is invalid."
  }
  return $type
}

proc ::fossilhub::mutations::validateTitle {title label {maximum 160}} {
  set title [string trim $title]
  if {$title eq "" || [::fossilhub::mutations::utf8Length $title] > $maximum ||
      [string first "\u0000" $title] >= 0 || [regexp {[[:cntrl:]]} $title]} {
    error "$label must use 1–$maximum UTF-8 bytes."
  }
  return $title
}

proc ::fossilhub::mutations::temporaryFile {prefix content} {
  if {![regexp {^[a-z0-9-]+$} $prefix]} {
    error "invalid temporary file prefix"
  }
  set channel [file tempfile path "fossilhub-${prefix}"]
  try {
    fconfigure $channel -encoding utf-8 -translation lf
    puts -nonewline $channel $content
  } finally {
    close $channel
  }
  file attributes $path -permissions 0600
  return $path
}

proc ::fossilhub::mutations::deleteTemporaryFile {path prefix} {
  if {[file exists $path] &&
      [string match "fossilhub-${prefix}*" [file tail $path]]} {
    file delete -force $path
  }
}

proc ::fossilhub::mutations::runArguments {label arguments} {
  set argumentFile [::fossilhub::mutations::temporaryFile \
    arguments "[join $arguments \n]\n"]
  try {
    if {[catch {set output [exec [::fossilhub::model::fossilBinary] \
        --nocgi --args $argumentFile]}]} {
      error "FossilHub: $label failed; captured Fossil output was suppressed"
    }
    return $output
  } finally {
    ::fossilhub::mutations::deleteTemporaryFile $argumentFile arguments
  }
}

proc ::fossilhub::mutations::fossilUserExists {repository username} {
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(login) FROM user WHERE login=%s COLLATE NOCASE LIMIT 1;
  } [::fossilhub::model::textLiteral $username]] 1]
  expr {[llength $rows] == 1}
}

proc ::fossilhub::mutations::ensureAuthor {repository user {freshPassword 0}} {
  variable authorCapabilities
  set username [dict get $user username]
  set password ""
  if {![::fossilhub::mutations::fossilUserExists $repository $username]} {
    set password [::fossilhub::auth::randomToken 24]
    ::fossilhub::mutations::runArguments {Fossil author creation} [list \
      user new $username fossilhub-managed $password \
      --repository $repository]
  } elseif {$freshPassword} {
    set password [::fossilhub::auth::randomToken 24]
    ::fossilhub::mutations::runArguments {Fossil author credential rotation} \
      [list user password $username $password --repository $repository]
  }
  ::fossilhub::repositories::runFossil {Fossil author capability update} \
    [list user capabilities $username $authorCapabilities \
      --repository $repository]
  return $password
}

proc ::fossilhub::mutations::branchHead {repository branch} {
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(b.uuid)
      FROM tag AS t
      JOIN tagxref AS tx ON tx.tagid=t.tagid AND tx.tagtype>0
      JOIN blob AS b ON b.rid=tx.rid
      JOIN event AS e ON e.objid=tx.rid AND e.type='ci'
     WHERE t.tagname=('sym-' || %s)
     ORDER BY e.mtime DESC,e.objid DESC
     LIMIT 1;
  } [::fossilhub::model::textLiteral $branch]] 1]
  if {[llength $rows] == 0} {
    return ""
  }
  return [lindex [lindex $rows 0] 0]
}

proc ::fossilhub::mutations::branchNames {repository} {
  set rows [::fossilhub::model::sqlRows $repository {
    SELECT hex(CAST(name AS TEXT)) FROM (
      SELECT 'trunk' AS name
      UNION
      SELECT COALESCE(NULLIF(tx.value,''),'trunk') AS name
        FROM tag AS t JOIN tagxref AS tx ON tx.tagid=t.tagid
       WHERE t.tagname='branch' AND tx.tagtype>0
    ) ORDER BY name COLLATE NOCASE;
  } 1]
  set result {}
  foreach row $rows {
    set branch [lindex $row 0]
    if {![catch {::fossilhub::repositories::validateBranch $branch}] &&
        [::fossilhub::mutations::branchHead $repository $branch] ne ""} {
      lappend result $branch
    }
  }
  return [lsort -unique -dictionary $result]
}

proc ::fossilhub::mutations::checkExpected {actual expected} {
  set expected [::fossilhub::mutations::validateRevision $expected]
  if {![string equal -nocase $actual $expected]} {
    error "Repository changed since this form was loaded. Reload and try again."
  }
}

proc ::fossilhub::mutations::temporaryCheckout {repository revision} {
  set channel [file tempfile checkout fossilhub-checkout]
  close $channel
  file delete $checkout
  file mkdir $checkout
  file attributes $checkout -permissions 0700
  if {[catch {::fossilhub::repositories::runFossil {temporary checkout} [list \
      open $repository $revision --nosync --workdir $checkout]} message options]} {
    file delete -force $checkout
    return -options $options $message
  }
  return $checkout
}

proc ::fossilhub::mutations::deleteCheckout {checkout} {
  if {[file isdirectory $checkout] &&
      [string match fossilhub-checkout* [file tail $checkout]]} {
    file delete -force $checkout
  }
}

proc ::fossilhub::mutations::checkoutPath {checkout filename {createParents 0}} {
  set filename [::fossilhub::mutations::validateFilename $filename]
  set checkout [file normalize $checkout]
  set path [file normalize [file join $checkout $filename]]
  if {![string match "${checkout}/*" $path]} {
    error "Repository filename escaped the checkout."
  }
  set current $checkout
  set segments [split $filename /]
  foreach segment [lrange $segments 0 end-1] {
    set current [file join $current $segment]
    if {[file exists $current] && [file type $current] eq "link"} {
      error "Repository filename crosses a symbolic link."
    }
  }
  if {[file exists $path] && [file type $path] eq "link"} {
    error "Repository filename identifies a symbolic link."
  }
  if {$createParents} {
    file mkdir [file dirname $path]
  }
  return $path
}

proc ::fossilhub::mutations::atomicWrite {path content} {
  set temporary [file join [file dirname $path] \
    ".fossilhub-write-[pid]-[clock clicks]"]
  set channel [open $temporary {WRONLY CREAT EXCL}]
  try {
    fconfigure $channel -encoding iso8859-1 -translation binary
    puts -nonewline $channel [encoding convertto utf-8 $content]
  } finally {
    close $channel
  }
  file attributes $temporary -permissions 0600
  file rename -force $temporary $path
}

proc ::fossilhub::mutations::markUpdated {repository actorId action target \
    {requestId ""}} {
  set now [clock seconds]
  ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
    [format {UPDATE repositories SET updated_epoch=%d WHERE id=%s;} \
      $now [::fossilhub::platform::textLiteral [dict get $repository id]]]
  ::fossilhub::auth::audit $action success $actorId $target \
    [dict get $repository id] $requestId
  if {[catch {::fossilhub::catalog::rebuild}]} {
    ::fossilhub::platform::execute [::fossilhub::platform::databasePath] \
      [format {UPDATE repositories SET state='quarantined',updated_epoch=%d
        WHERE id=%s;} $now \
        [::fossilhub::platform::textLiteral [dict get $repository id]]]
    catch {::fossilhub::auth::audit repository.index failure $actorId \
      [dict get $repository slug] [dict get $repository id] $requestId \
      {post-mutation catalogue rebuild failed}}
    catch {::fossilhub::catalog::rebuild}
    error "Mutation completed but the repository was quarantined because indexing failed."
  }
}

proc ::fossilhub::mutations::fileChange {repository user action filename \
    nextFilename content message branch expected {requestId ""}} {
  variable maximumFileBytes
  set actorId [dict get $user id]
  if {$action ni {create edit delete rename}} {
    error "File operation is invalid."
  }
  set filename [::fossilhub::mutations::validateFilename $filename]
  if {$action eq "rename"} {
    set nextFilename [::fossilhub::mutations::validateFilename $nextFilename]
    if {$nextFilename eq $filename} {
      error "Choose a different filename for the rename."
    }
  } else {
    set nextFilename ""
  }
  if {$action in {create edit}} {
    set content [::fossilhub::mutations::validateText \
      $content $maximumFileBytes {File content}]
  } else {
    set content ""
  }
  set message [::fossilhub::mutations::validateMessage $message]
  set branch [::fossilhub::repositories::validateBranch $branch]
  set repositoryPath [::fossilhub::model::repositoryPath \
    [dict get $repository name]]
  set lock [::fossilhub::repositories::acquireLock \
    "write-[dict get $repository slug]"]
  set checkout ""
  set messageFile ""
  try {
    set head [::fossilhub::mutations::branchHead $repositoryPath $branch]
    if {$head eq ""} {
      error "The selected branch does not exist."
    }
    ::fossilhub::mutations::checkExpected $head $expected
    if {$action in {create edit rename}} {
      set requestedBytes [expr {
        [::fossilhub::mutations::utf8Length $content] +
        [::fossilhub::mutations::utf8Length $message] +
        [::fossilhub::mutations::utf8Length $filename] +
        [::fossilhub::mutations::utf8Length $nextFilename]}]
      ::fossilhub::mutations::enforceQuota $repositoryPath $requestedBytes
    }
    ::fossilhub::mutations::ensureAuthor $repositoryPath $user
    set checkout [::fossilhub::mutations::temporaryCheckout \
      $repositoryPath $head]
    set path [::fossilhub::mutations::checkoutPath $checkout $filename \
      [expr {$action eq "create"}]]
    switch -- $action {
      create {
        if {[file exists $path]} {
          error "A file already exists at that path."
        }
        ::fossilhub::mutations::atomicWrite $path $content
        ::fossilhub::repositories::runFossil {file add} [list \
          --chdir $checkout add -f $filename]
      }
      edit {
        if {![file isfile $path]} {
          error "The file no longer exists."
        }
        ::fossilhub::mutations::atomicWrite $path $content
      }
      delete {
        if {![file isfile $path]} {
          error "The file no longer exists."
        }
        ::fossilhub::repositories::runFossil {file delete} [list \
          --chdir $checkout rm --hard $filename]
      }
      rename {
        if {![file isfile $path]} {
          error "The file no longer exists."
        }
        set destination [::fossilhub::mutations::checkoutPath \
          $checkout $nextFilename 1]
        if {[file exists $destination]} {
          error "A file already exists at the destination path."
        }
        ::fossilhub::repositories::runFossil {file rename} [list \
          --chdir $checkout mv --hard $filename $nextFilename]
      }
    }
    set messageFile [::fossilhub::mutations::temporaryFile message $message]
    ::fossilhub::repositories::runFossil {file commit} [list \
      --chdir $checkout commit --no-prompt --no-warnings --nosign --nosync \
      --no-verify --user [dict get $user username] -M $messageFile]
    set nextHead [::fossilhub::mutations::branchHead $repositoryPath $branch]
    if {$nextHead eq "" || [string equal -nocase $nextHead $head]} {
      error "Fossil did not publish a new check-in."
    }
    ::fossilhub::mutations::markUpdated $repository $actorId \
      "repository.file-$action" $filename $requestId
    return $nextHead
  } on error {message options} {
    catch {::fossilhub::auth::audit "repository.file-$action" failure \
      $actorId $filename [dict get $repository id] $requestId}
    return -options $options $message
  } finally {
    if {$messageFile ne ""} {
      ::fossilhub::mutations::deleteTemporaryFile $messageFile message
    }
    if {$checkout ne ""} {
      ::fossilhub::mutations::deleteCheckout $checkout
    }
    ::fossilhub::repositories::releaseLock $lock
  }
}

proc ::fossilhub::mutations::wikiPage {repository title} {
  foreach page [::fossilhub::model::wikiPages [dict get $repository name] 500] {
    if {[string equal -nocase [dict get $page title] $title]} {
      return $page
    }
  }
  return ""
}

proc ::fossilhub::mutations::wikiChange {repository user title content \
    mimetype expected {requestId ""}} {
  variable maximumTextBytes
  set title [::fossilhub::mutations::validateWikiName $title]
  set content [::fossilhub::mutations::validateText \
    $content $maximumTextBytes {Wiki content}]
  set mimetype [::fossilhub::mutations::validateMimetype $mimetype]
  set expected [::fossilhub::mutations::validateRevision $expected 1]
  set actorId [dict get $user id]
  set repositoryPath [::fossilhub::model::repositoryPath \
    [dict get $repository name]]
  set lock [::fossilhub::repositories::acquireLock \
    "write-[dict get $repository slug]"]
  set contentFile ""
  try {
    set current [::fossilhub::mutations::wikiPage $repository $title]
    set currentRevision [expr {$current eq "" ? "" : [dict get $current uuid]}]
    if {![string equal -nocase $currentRevision $expected]} {
      error "Wiki page changed since this form was loaded. Reload and try again."
    }
    ::fossilhub::mutations::enforceQuota $repositoryPath [expr {
      [::fossilhub::mutations::utf8Length $title] +
      [::fossilhub::mutations::utf8Length $content]}]
    ::fossilhub::mutations::ensureAuthor $repositoryPath $user
    set contentFile [::fossilhub::mutations::temporaryFile wiki $content]
    set command [expr {$current eq "" ? "create" : "commit"}]
    ::fossilhub::repositories::runFossil {Wiki update} [list \
      wiki $command $title $contentFile --mimetype $mimetype \
      --repository $repositoryPath --user [dict get $user username]]
    set next [::fossilhub::mutations::wikiPage $repository $title]
    if {$next eq "" || [string equal -nocase [dict get $next uuid] \
        $currentRevision]} {
      error "Fossil did not publish a new Wiki revision."
    }
    ::fossilhub::mutations::markUpdated $repository $actorId \
      repository.wiki $title $requestId
    return $next
  } on error {message options} {
    catch {::fossilhub::auth::audit repository.wiki failure $actorId \
      $title [dict get $repository id] $requestId}
    return -options $options $message
  } finally {
    if {$contentFile ne ""} {
      ::fossilhub::mutations::deleteTemporaryFile $contentFile wiki
    }
    ::fossilhub::repositories::releaseLock $lock
  }
}

proc ::fossilhub::mutations::ticketQuote {value} {
  string map [list \
    "\\" {\\} " " {\s} "\t" {\t} "\n" {\n} "\r" {\r} \
    "\f" {\f} "\v" {\v} "\u0000" {\0}] $value
}

proc ::fossilhub::mutations::ticketRevision {repository ticketId} {
  set ticketId [::fossilhub::mutations::validateRevision $ticketId]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(b.uuid)
      FROM tag AS t
      JOIN tagxref AS tx ON tx.tagid=t.tagid AND tx.tagtype>0
      JOIN blob AS b ON b.rid=tx.rid
     WHERE t.tagname=('tkt-' || %s)
     ORDER BY tx.mtime DESC,tx.rid DESC LIMIT 1;
  } [::fossilhub::model::textLiteral $ticketId]] 1]
  if {[llength $rows] == 0} {
    return ""
  }
  return [lindex [lindex $rows 0] 0]
}

proc ::fossilhub::mutations::ticketCreate {repository user title type comment \
    {requestId ""}} {
  variable maximumTextBytes
  set title [::fossilhub::mutations::validateTitle $title {Ticket title}]
  set type [::fossilhub::mutations::validateTicketType $type]
  set comment [::fossilhub::mutations::validateText \
    $comment $maximumTextBytes {Ticket description}]
  set actorId [dict get $user id]
  set repositoryPath [::fossilhub::model::repositoryPath \
    [dict get $repository name]]
  set lock [::fossilhub::repositories::acquireLock \
    "write-[dict get $repository slug]"]
  try {
    ::fossilhub::mutations::enforceQuota $repositoryPath [expr {
      [::fossilhub::mutations::utf8Length $title] +
      [::fossilhub::mutations::utf8Length $comment]}]
    ::fossilhub::mutations::ensureAuthor $repositoryPath $user
    set output [::fossilhub::mutations::runArguments {Ticket creation} [list \
      ticket add title [::fossilhub::mutations::ticketQuote $title] \
      type $type status Open comment \
      [::fossilhub::mutations::ticketQuote $comment] --quote \
      --repository $repositoryPath --user [dict get $user username]]]
    if {![regexp {(?i)([[:xdigit:]]{40,64})} $output -> ticketId]} {
      error "Fossil did not return a new Ticket identifier."
    }
    set ticketId [string tolower $ticketId]
    ::fossilhub::mutations::markUpdated $repository $actorId \
      repository.ticket-create $ticketId $requestId
    return [dict create uuid $ticketId \
      revision [::fossilhub::mutations::ticketRevision \
        $repositoryPath $ticketId]]
  } on error {message options} {
    catch {::fossilhub::auth::audit repository.ticket-create failure \
      $actorId "" [dict get $repository id] $requestId}
    return -options $options $message
  } finally {
    ::fossilhub::repositories::releaseLock $lock
  }
}

proc ::fossilhub::mutations::ticketChange {repository user ticketId action \
    comment expected {requestId ""} {fields {}}} {
  variable maximumTextBytes
  set ticketId [::fossilhub::mutations::validateRevision $ticketId]
  if {$action ni {comment close reopen update}} {
    error "Ticket operation is invalid."
  }
  set comment [::fossilhub::mutations::validateText \
    $comment $maximumTextBytes {Ticket comment}]
  if {$action eq "comment" && [string trim $comment] eq ""} {
    error "Ticket comment cannot be empty."
  }
  set title ""
  set type ""
  if {$action eq "update"} {
    if {![dict exists $fields title] || ![dict exists $fields type]} {
      error "Ticket fields are incomplete."
    }
    set title [::fossilhub::mutations::validateTitle \
      [dict get $fields title] {Ticket title}]
    set type [::fossilhub::mutations::validateTicketType \
      [dict get $fields type]]
  }
  set expected [::fossilhub::mutations::validateRevision $expected]
  set actorId [dict get $user id]
  set repositoryPath [::fossilhub::model::repositoryPath \
    [dict get $repository name]]
  set lock [::fossilhub::repositories::acquireLock \
    "write-[dict get $repository slug]"]
  try {
    set current [::fossilhub::mutations::ticketRevision \
      $repositoryPath $ticketId]
    if {$current eq "" || ![string equal -nocase $current $expected]} {
      error "Ticket changed since this form was loaded. Reload and try again."
    }
    ::fossilhub::mutations::enforceQuota $repositoryPath \
      [expr {[::fossilhub::mutations::utf8Length $comment] +
        [::fossilhub::mutations::utf8Length $title] +
        [::fossilhub::mutations::utf8Length $type]}]
    ::fossilhub::mutations::ensureAuthor $repositoryPath $user
    set arguments [list ticket set $ticketId]
    if {$action eq "close"} {
      lappend arguments status Closed
    } elseif {$action eq "reopen"} {
      lappend arguments status Open
    } elseif {$action eq "update"} {
      lappend arguments title [::fossilhub::mutations::ticketQuote $title] \
        type $type
    }
    if {[string trim $comment] ne ""} {
      lappend arguments +comment [::fossilhub::mutations::ticketQuote \
        "\n\n$comment"]
    }
    lappend arguments --quote --repository $repositoryPath \
      --user [dict get $user username]
    ::fossilhub::mutations::runArguments {Ticket update} $arguments
    set next [::fossilhub::mutations::ticketRevision \
      $repositoryPath $ticketId]
    if {$next eq "" || [string equal -nocase $next $current]} {
      error "Fossil did not publish a new Ticket change."
    }
    ::fossilhub::mutations::markUpdated $repository $actorId \
      "repository.ticket-$action" $ticketId $requestId
    return $next
  } on error {message options} {
    catch {::fossilhub::auth::audit "repository.ticket-$action" failure \
      $actorId $ticketId [dict get $repository id] $requestId}
    return -options $options $message
  } finally {
    ::fossilhub::repositories::releaseLock $lock
  }
}

proc ::fossilhub::mutations::urlEncode {value} {
  binary scan [encoding convertto utf-8 $value] c* bytes
  set result ""
  foreach byte $bytes {
    set unsigned [expr {$byte & 0xff}]
    if {($unsigned >= 0x41 && $unsigned <= 0x5a) ||
        ($unsigned >= 0x61 && $unsigned <= 0x7a) ||
        ($unsigned >= 0x30 && $unsigned <= 0x39) ||
        $unsigned in {45 46 95 126}} {
      append result [format %c $unsigned]
    } else {
      append result %[format %02X $unsigned]
    }
  }
  return $result
}

proc ::fossilhub::mutations::formBody {parameters} {
  set fields {}
  dict for {name value} $parameters {
    lappend fields "[::fossilhub::mutations::urlEncode $name]=[::fossilhub::mutations::urlEncode $value]"
  }
  join $fields &
}

proc ::fossilhub::mutations::cgiRequest {repository path method parameters \
    {cookie ""} {query ""}} {
  set configuration [::fossilhub::mutations::temporaryFile cgi \
    "repository: $repository\nHOME: /data\n"]
  set body [expr {$method eq "POST" ?
    [::fossilhub::mutations::formBody $parameters] : ""}]
  set names {
    GATEWAY_INTERFACE REQUEST_METHOD REQUEST_URI SCRIPT_NAME PATH_INFO
    QUERY_STRING HTTP_HOST HTTP_REFERER REMOTE_ADDR CONTENT_TYPE CONTENT_LENGTH
    HTTP_COOKIE
  }
  set saved [dict create]
  set nullChannel ""
  foreach name $names {
    if {[info exists ::env($name)]} {
      dict set saved $name [list 1 $::env($name)]
    } else {
      dict set saved $name [list 0 ""]
    }
  }
  try {
    set ::env(GATEWAY_INTERFACE) CGI/1.0
    set ::env(REQUEST_METHOD) $method
    set ::env(REQUEST_URI) "$path[expr {$query eq "" ? "" : "?$query"}]"
    set ::env(SCRIPT_NAME) ""
    set ::env(PATH_INFO) $path
    set ::env(QUERY_STRING) $query
    set ::env(HTTP_HOST) localhost
    set ::env(HTTP_REFERER) http://localhost/
    set ::env(REMOTE_ADDR) 192.0.2.1
    if {$method eq "POST"} {
      set ::env(CONTENT_TYPE) application/x-www-form-urlencoded
      set ::env(CONTENT_LENGTH) [string length \
        [encoding convertto utf-8 $body]]
    } else {
      unset -nocomplain ::env(CONTENT_TYPE) ::env(CONTENT_LENGTH)
    }
    if {$cookie eq ""} {
      unset -nocomplain ::env(HTTP_COOKIE)
    } else {
      set ::env(HTTP_COOKIE) $cookie
    }
    set nullChannel [open /dev/null w]
    if {[catch {set response [exec \
        [::fossilhub::model::fossilBinary] --nocgi cgi $configuration \
        << $body 2>@ $nullChannel]}]} {
      error "FossilHub: internal Fossil request failed"
    }
    return $response
  } finally {
    if {$nullChannel ne ""} {
      close $nullChannel
    }
    dict for {name record} $saved {
      if {[lindex $record 0]} {
        set ::env($name) [lindex $record 1]
      } else {
        unset -nocomplain ::env($name)
      }
    }
    ::fossilhub::mutations::deleteTemporaryFile $configuration cgi
  }
}

proc ::fossilhub::mutations::forumPostId {repository prefix} {
  set prefix [string tolower [string trim $prefix]]
  if {![regexp {^[[:xdigit:]]{10,64}$} $prefix]} {
    return ""
  }
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(b.uuid) FROM event AS e JOIN blob AS b ON b.rid=e.objid
     WHERE e.type='f' AND lower(b.uuid) LIKE (%s || '%%')
     ORDER BY e.mtime DESC,e.objid DESC LIMIT 2;
  } [::fossilhub::model::textLiteral $prefix]] 1]
  if {[llength $rows] != 1} {
    return ""
  }
  return [lindex [lindex $rows 0] 0]
}

proc ::fossilhub::mutations::forumChange {repository user action title content \
    mimetype parent {requestId ""}} {
  variable maximumTextBytes
  if {$action ni {thread reply}} {
    error "Forum operation is invalid."
  }
  if {$action eq "thread"} {
    set title [::fossilhub::mutations::validateTitle $title \
      {Forum title} 125]
    set parent ""
  } else {
    set title ""
  }
  set content [::fossilhub::mutations::validateText \
    $content $maximumTextBytes {Forum content}]
  if {[string trim $content] eq ""} {
    error "Forum content cannot be empty."
  }
  set mimetype [::fossilhub::mutations::validateMimetype $mimetype]
  set actorId [dict get $user id]
  set repositoryPath [::fossilhub::model::repositoryPath \
    [dict get $repository name]]
  set lock [::fossilhub::repositories::acquireLock \
    "write-[dict get $repository slug]"]
  try {
    if {$action eq "reply"} {
      set parent [::fossilhub::mutations::forumPostId $repositoryPath $parent]
      if {$parent eq ""} {
        error "Forum parent post was not found."
      }
    }
    ::fossilhub::mutations::enforceQuota $repositoryPath [expr {
      [::fossilhub::mutations::utf8Length $title] +
      [::fossilhub::mutations::utf8Length $content]}]
    set password [::fossilhub::mutations::ensureAuthor \
      $repositoryPath $user 1]
    set login [::fossilhub::mutations::cgiRequest $repositoryPath /login POST \
      [dict create u [dict get $user username] p $password g forumnew]]
    if {![regexp -nocase -line {^Set-Cookie:[[:space:]]*([^;]+)} \
        $login -> cookie]} {
      error "FossilHub: internal Fossil login failed"
    }
    if {$action eq "thread"} {
      set formPath /forumnew
      set formQuery ""
      set submitPath /forume1
    } else {
      set formPath /forumedit
      set formQuery "fpid=[::fossilhub::mutations::urlEncode $parent]"
      set submitPath /forume2
    }
    set form [::fossilhub::mutations::cgiRequest $repositoryPath \
      $formPath GET {} $cookie $formQuery]
    if {![regexp {name="csrf" value="([^"]+)"} $form -> csrf]} {
      error "FossilHub: internal Fossil form challenge failed"
    }
    set parameters [dict create content $content mimetype $mimetype \
      submit Submit csrf $csrf]
    if {$action eq "thread"} {
      dict set parameters title $title
    } else {
      dict set parameters fpid $parent
      dict set parameters reply Reply
    }
    set response [::fossilhub::mutations::cgiRequest $repositoryPath \
      $submitPath POST $parameters $cookie]
    if {![regexp -nocase -line {^Location:[^\r\n]*/forumpost/([[:xdigit:]]{10,64})} \
        $response -> postPrefix]} {
      error "Fossil did not publish the Forum post."
    }
    set postId [::fossilhub::mutations::forumPostId \
      $repositoryPath $postPrefix]
    if {$postId eq ""} {
      error "Fossil did not return the Forum post identifier."
    }
    ::fossilhub::mutations::markUpdated $repository $actorId \
      "repository.forum-$action" $postId $requestId
    return $postId
  } on error {message options} {
    catch {::fossilhub::auth::audit "repository.forum-$action" failure \
      $actorId $parent [dict get $repository id] $requestId}
    return -options $options $message
  } finally {
    ::fossilhub::repositories::releaseLock $lock
  }
}
