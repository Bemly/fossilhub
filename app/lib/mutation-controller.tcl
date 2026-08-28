namespace eval ::fossilhub::mutationController {}

proc ::fossilhub::mutationController::requestId {} {
  return [::fossilhub::auth::randomToken 16]
}

proc ::fossilhub::mutationController::repositoryForName {name context capability} {
  if {![::fossilhub::model::validRepositoryName $name] ||
      [set repository [::fossilhub::repositories::byName $name]] eq "" ||
      ![::fossilhub::repositories::allows $repository $context $capability]} {
    wapp-reply-code "404 Not Found"
    catch {::fossilhub::auth::audit repository.mutation-access denied \
      [expr {[dict get $context authenticated] ? \
        [dict get [dict get $context user] id] : ""}] [file tail $name]}
    ::fossilhub::placeholder {Repository not found — FossilHub} \
      {That repository is not in this dig.}
    return ""
  }
  return $repository
}

proc ::fossilhub::mutationController::modelRepository {repository} {
  set result [::fossilhub::model::repository [dict get $repository name] 200]
  dict set result project_name [dict get $repository title]
  dict set result description [dict get $repository description]
  dict set result visibility [dict get $repository visibility]
  return $result
}

proc ::fossilhub::mutationController::render {repository section data} {
  ::fossilhub::account::renderPage [::fossilhub::views::renderRepository \
    [::fossilhub::mutationController::modelRepository $repository] \
    $section $data]
}

proc ::fossilhub::mutationController::purpose {repository operation {target ""}} {
  set result "mutation-$operation:[dict get $repository id]"
  if {$target ne ""} {
    append result ":[string tolower $target]"
  }
  return $result
}

proc ::fossilhub::mutationController::challenge {context repository operation \
    {target ""}} {
  ::fossilhub::auth::issueChallenge \
    [::fossilhub::mutationController::purpose \
      $repository $operation $target] [dict get $context session_hash]
}

proc ::fossilhub::mutationController::consume {context repository operation \
    {target ""}} {
  ::fossilhub::auth::consumeChallenge [wapp-param csrf ""] \
    [::fossilhub::mutationController::purpose \
      $repository $operation $target] [dict get $context session_hash]
}

proc ::fossilhub::mutationController::publicError {message fallback} {
  foreach pattern {
    {A valid revision marker is required.}
    {Commit message must use*}
    {File content exceeds*}
    {File operation is invalid.}
    {Repository filename is invalid.}
    {A file already exists*}
    {The file no longer exists.}
    {Choose a different filename*}
    {The selected branch does not exist.}
    {Repository changed since*}
    {Wiki page name must*}
    {Wiki content exceeds*}
    {Markup type is invalid.}
    {Wiki page changed since*}
    {Ticket title must*}
    {Ticket description exceeds*}
    {Ticket comment exceeds*}
    {Ticket comment cannot be empty.}
    {Ticket type is invalid.}
    {Ticket operation is invalid.}
    {Ticket fields are incomplete.}
    {Ticket changed since*}
    {Forum title must*}
    {Forum content exceeds*}
    {Forum content cannot be empty.}
    {Forum parent post was not found.}
    {Repository is busy.*}
    {Mutation completed but the repository was quarantined*}
    {Mutation size exceeds*}
    {Repository storage quota would be exceeded.}
  } {
    if {[string match $pattern $message]} {
      return $message
    }
  }
  return $fallback
}

proc ::fossilhub::mutationController::relativeRepositoryPath {suffix} {
  set segments [split [string trim [::fossilhub::requestPath] /] /]
  set repositoryIndex -1
  for {set index [expr {[llength $segments] - 1}]} {$index >= 0} \
      {incr index -1} {
    if {[lindex $segments $index] eq "repo"} {
      set repositoryIndex $index
      break
    }
  }
  if {$repositoryIndex < 0 || $repositoryIndex + 1 >= [llength $segments]} {
    return $suffix
  }
  set tailLength [expr {[llength $segments] - $repositoryIndex - 2}]
  set upward [expr {max(0,$tailLength - 1)}]
  return "[string repeat ../ $upward]$suffix"
}

proc ::fossilhub::mutationController::relativeHubPath {suffix} {
  set segments [split [string trim [::fossilhub::requestPath] /] /]
  set repositoryIndex -1
  for {set index [expr {[llength $segments] - 1}]} {$index >= 0} \
      {incr index -1} {
    if {[lindex $segments $index] eq "repo"} {
      set repositoryIndex $index
      break
    }
  }
  if {$repositoryIndex < 0} {
    return $suffix
  }
  set upward [expr {[llength $segments] - $repositoryIndex - 1}]
  return "[string repeat ../ $upward]$suffix"
}

proc ::fossilhub::mutationController::requireRequest {context method} {
  if {![dict get $context authenticated]} {
    wapp-redirect [::fossilhub::mutationController::relativeHubPath login]
    return 0
  }
  if {[dict get [dict get $context user] must_change_password]} {
    wapp-redirect [::fossilhub::mutationController::relativeHubPath \
      account/security]
    return 0
  }
  set actual [::fossilhub::account::method]
  if {$actual ni $method} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {This repository workbench accepts browser forms only.}
    return 0
  }
  return 1
}

proc ::fossilhub::mutationController::fileValues {operation record} {
  if {$operation eq "create"} {
    return [dict create filename [string range [wapp-param filename ""] 0 520] \
      content [string range [wapp-param content ""] 0 1048580] \
      message [string range [wapp-param message ""] 0 4100]]
  }
  set content [expr {$record ne "" && [dict get $record text] ? \
    [dict get $record content] : ""}]
  return [dict create content [string range \
      [wapp-param content $content] 0 1048580] \
    message [string range [wapp-param message \
      "Update [dict get $record filename]"] 0 4100] \
    next_filename [string range [wapp-param next_filename \
      [dict get $record filename]] 0 520]]
}

proc ::fossilhub::mutationController::renderFile {context repository operation \
    record message values} {
  set repositoryPath [::fossilhub::model::repositoryPath \
    [dict get $repository name]]
  set branches [::fossilhub::mutations::branchNames $repositoryPath]
  set branch [dict get $repository default_branch]
  if {$operation eq "create" && [dict exists $values branch] &&
      [dict get $values branch] in $branches} {
    set branch [dict get $values branch]
  }
  dict set values branch $branch
  set head [::fossilhub::mutations::branchHead $repositoryPath $branch]
  set data [dict create operation $operation file $record message $message \
    values $values head $head branch $branch branches $branches]
  if {$operation eq "create"} {
    dict set data csrf [::fossilhub::mutationController::challenge \
      $context $repository file-create]
  } else {
    set target [dict get $record uuid]
    foreach action {save rename delete} {
      dict set data csrf_$action [::fossilhub::mutationController::challenge \
        $context $repository "file-$action" $target]
    }
  }
  ::fossilhub::mutationController::render $repository file-compose $data
}

proc ::fossilhub::mutationController::handleFile {context repository operation \
    target} {
  set record ""
  if {$operation eq "edit"} {
    if {[catch {set record [::fossilhub::model::fileRecord \
        [dict get $repository name] $target]}]} {
      wapp-reply-code "404 Not Found"
      ::fossilhub::placeholder {Artifact not found — FossilHub} \
        {That artifact is no longer on the selected branch.}
      return
    }
  }
  set values [::fossilhub::mutationController::fileValues $operation $record]
  dict set values branch [expr {$operation eq "create" ?
    [string range [wapp-param branch [dict get $repository default_branch]] \
      0 110] : [dict get $repository default_branch]}]
  if {[::fossilhub::account::method] eq "GET"} {
    ::fossilhub::mutationController::renderFile \
      $context $repository $operation $record "" $values
    return
  }
  if {$operation eq "create"} {
    set action create
    set challenge file-create
    set filename [dict get $values filename]
    set nextFilename ""
  } else {
    set submitted [wapp-param operation ""]
    if {$submitted ni {save rename delete}} {
      wapp-reply-code "422 Unprocessable Content"
      ::fossilhub::mutationController::renderFile $context $repository \
        $operation $record {Choose a valid file operation.} $values
      return
    }
    set challenge "file-$submitted"
    set filename [dict get $record filename]
    set nextFilename [expr {$submitted eq "rename" ? \
      [dict get $values next_filename] : ""}]
    set action [dict get [dict create save edit rename rename delete delete] \
      $submitted]
    if {$submitted eq "save" && ![dict get $record text]} {
      wapp-reply-code "415 Unsupported Media Type"
      ::fossilhub::mutationController::renderFile $context $repository \
        $operation $record {Binary artifacts cannot be edited in the browser.} $values
      return
    }
  }
  set challengeTarget [expr {$operation eq "create" ? "" : \
    [dict get $record uuid]}]
  if {![::fossilhub::mutationController::consume $context $repository \
      $challenge $challengeTarget]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::mutationController::renderFile $context $repository \
      $operation $record {This file form expired. Reload and try again.} $values
    return
  }
  set content [expr {$action in {create edit} ? [dict get $values content] : ""}]
  set requestId [::fossilhub::mutationController::requestId]
  if {[catch {::fossilhub::mutations::fileChange $repository \
      [dict get $context user] $action $filename $nextFilename $content \
      [dict get $values message] [dict get $values branch] \
      [wapp-param expected ""] $requestId} message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::mutationController::renderFile $context $repository \
      $operation $record [::fossilhub::mutationController::publicError \
        $message {The file change could not be committed.}] $values
    return
  }
  wapp-redirect [::fossilhub::mutationController::relativeRepositoryPath files]
}

proc ::fossilhub::mutationController::wikiValues {operation page} {
  if {$operation eq "create"} {
    set title [wapp-param title ""]
    set content [wapp-param content ""]
  } else {
    set title [dict get $page title]
    set content [wapp-param content [dict get $page content]]
  }
  return [dict create title [string range $title 0 170] \
    content [string range $content 0 262148] \
    mimetype [string range [wapp-param mimetype markdown] 0 32]]
}

proc ::fossilhub::mutationController::renderWiki {context repository operation \
    page message values} {
  set expected [expr {$page eq "" ? "" : [dict get $page uuid]}]
  set data [dict create operation $operation values $values message $message \
    expected $expected csrf [::fossilhub::mutationController::challenge \
      $context $repository "wiki-$operation" $expected]]
  ::fossilhub::mutationController::render $repository wiki-compose $data
}

proc ::fossilhub::mutationController::handleWiki {context repository operation \
    target} {
  set page ""
  if {$operation eq "edit" &&
      [catch {set page [::fossilhub::model::wikiContent \
        [dict get $repository name] $target]}]} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {Wiki page not found — FossilHub} \
      {That Wiki revision is no longer current.}
    return
  }
  set values [::fossilhub::mutationController::wikiValues $operation $page]
  if {[::fossilhub::account::method] eq "GET"} {
    ::fossilhub::mutationController::renderWiki \
      $context $repository $operation $page "" $values
    return
  }
  set expected [expr {$page eq "" ? "" : [dict get $page uuid]}]
  if {![::fossilhub::mutationController::consume $context $repository \
      "wiki-$operation" $expected]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::mutationController::renderWiki $context $repository \
      $operation $page {This Wiki form expired. Reload and try again.} $values
    return
  }
  set requestId [::fossilhub::mutationController::requestId]
  if {[catch {set next [::fossilhub::mutations::wikiChange $repository \
      [dict get $context user] [dict get $values title] \
      [dict get $values content] [dict get $values mimetype] \
      [wapp-param expected ""] $requestId]} message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::mutationController::renderWiki $context $repository \
      $operation $page [::fossilhub::mutationController::publicError \
        $message {The Wiki revision could not be published.}] $values
    return
  }
  wapp-redirect [::fossilhub::mutationController::relativeRepositoryPath \
    "wiki-page/[dict get $next uuid]"]
}

proc ::fossilhub::mutationController::ticketRecord {repository ticketId} {
  foreach ticket [::fossilhub::model::tickets [dict get $repository name] 500] {
    if {[string equal -nocase [dict get $ticket uuid] $ticketId]} {
      return $ticket
    }
  }
  return ""
}

proc ::fossilhub::mutationController::renderTicketNew {context repository \
    message values} {
  set data [dict create message $message values $values \
    csrf [::fossilhub::mutationController::challenge \
      $context $repository ticket-create]]
  ::fossilhub::mutationController::render $repository ticket-compose $data
}

proc ::fossilhub::mutationController::handleTicketNew {context repository} {
  set values [dict create \
    title [string range [wapp-param title ""] 0 170] \
    type [string range [wapp-param type Code_Defect] 0 32] \
    comment [string range [wapp-param comment ""] 0 262148]]
  if {[::fossilhub::account::method] eq "GET"} {
    ::fossilhub::mutationController::renderTicketNew \
      $context $repository "" $values
    return
  }
  if {![::fossilhub::mutationController::consume \
      $context $repository ticket-create]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::mutationController::renderTicketNew $context $repository \
      {This Ticket form expired. Reload and try again.} $values
    return
  }
  set requestId [::fossilhub::mutationController::requestId]
  if {[catch {set ticket [::fossilhub::mutations::ticketCreate $repository \
      [dict get $context user] [dict get $values title] \
      [dict get $values type] [dict get $values comment] $requestId]} message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::mutationController::renderTicketNew $context $repository \
      [::fossilhub::mutationController::publicError \
        $message {The Ticket could not be opened.}] $values
    return
  }
  wapp-redirect [::fossilhub::mutationController::relativeRepositoryPath \
    "ticket/[dict get $ticket uuid]"]
}

proc ::fossilhub::mutationController::renderTicket {context repository ticket \
    message comment} {
  set id [dict get $ticket uuid]
  set revision [::fossilhub::mutations::ticketRevision \
    [::fossilhub::model::repositoryPath [dict get $repository name]] $id]
  set closed [expr {[string tolower [dict get $ticket status]] in \
    {closed fixed resolved}}]
  set statusAction [expr {$closed ? "reopen" : "close"}]
  set data [dict create ticket $ticket revision $revision message $message \
    comment $comment \
    csrf_comment [::fossilhub::mutationController::challenge \
      $context $repository ticket-comment $id] \
    csrf_status [::fossilhub::mutationController::challenge \
      $context $repository "ticket-$statusAction" $id] \
    csrf_update [::fossilhub::mutationController::challenge \
      $context $repository ticket-update $id]]
  ::fossilhub::mutationController::render $repository ticket-workbench $data
}

proc ::fossilhub::mutationController::handleTicket {context repository ticketId} {
  set ticket [::fossilhub::mutationController::ticketRecord \
    $repository $ticketId]
  if {$ticket eq ""} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {Ticket not found — FossilHub} \
      {That ticket is not in this repository.}
    return
  }
  if {[::fossilhub::account::method] eq "GET"} {
    set message [expr {[wapp-param changed ""] eq "1" ? \
      "Ticket updated." : ""}]
    ::fossilhub::mutationController::renderTicket \
      $context $repository $ticket $message ""
    return
  }
  set action [string range [wapp-param action ""] 0 16]
  if {$action ni {comment close reopen update}} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::mutationController::renderTicket $context $repository \
      $ticket {Choose a valid Ticket operation.} ""
    return
  }
  if {![::fossilhub::mutationController::consume $context $repository \
      "ticket-$action" $ticketId]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::mutationController::renderTicket $context $repository \
      $ticket {This Ticket form expired. Reload and try again.} ""
    return
  }
  set comment [string range [wapp-param comment ""] 0 262148]
  set fields {}
  if {$action eq "update"} {
    set fields [dict create \
      title [string range [wapp-param title ""] 0 170] \
      type [string range [wapp-param type ""] 0 32]]
  }
  set requestId [::fossilhub::mutationController::requestId]
  if {[catch {::fossilhub::mutations::ticketChange $repository \
      [dict get $context user] $ticketId $action $comment \
      [wapp-param expected ""] $requestId $fields} message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::mutationController::renderTicket $context $repository \
      $ticket [::fossilhub::mutationController::publicError \
        $message {The Ticket change could not be published.}] $comment
    return
  }
  wapp-redirect "?changed=1"
}

proc ::fossilhub::mutationController::renderForum {context repository operation \
    parent message values} {
  set data [dict create operation $operation parent $parent message $message \
    values $values csrf [::fossilhub::mutationController::challenge \
      $context $repository "forum-$operation" $parent]]
  ::fossilhub::mutationController::render $repository forum-compose $data
}

proc ::fossilhub::mutationController::handleForum {context repository operation \
    parent} {
  set values [dict create title [string range [wapp-param title ""] 0 130] \
    content [string range [wapp-param content ""] 0 262148] \
    mimetype [string range [wapp-param mimetype markdown] 0 32]]
  if {[::fossilhub::account::method] eq "GET"} {
    ::fossilhub::mutationController::renderForum \
      $context $repository $operation $parent "" $values
    return
  }
  if {![::fossilhub::mutationController::consume $context $repository \
      "forum-$operation" $parent]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::mutationController::renderForum $context $repository \
      $operation $parent {This Forum form expired. Reload and try again.} $values
    return
  }
  set requestId [::fossilhub::mutationController::requestId]
  if {[catch {::fossilhub::mutations::forumChange $repository \
      [dict get $context user] $operation [dict get $values title] \
      [dict get $values content] [dict get $values mimetype] $parent \
      $requestId} message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::mutationController::renderForum $context $repository \
      $operation $parent [::fossilhub::mutationController::publicError \
        $message {The Forum post could not be published.}] $values
    return
  }
  wapp-redirect [::fossilhub::mutationController::relativeRepositoryPath forum]
}

proc ::fossilhub::mutationController::handle {context name operation target} {
  if {![::fossilhub::mutationController::requireRequest \
      $context {GET POST}]} {
    return
  }
  set capability [expr {$operation in {ticket-new ticket forum-new forum-reply} ? \
    "triage" : "write"}]
  set repository [::fossilhub::mutationController::repositoryForName \
    $name $context $capability]
  if {$repository eq ""} {
    return
  }
  switch -- $operation {
    file-new { ::fossilhub::mutationController::handleFile \
      $context $repository create "" }
    file-edit { ::fossilhub::mutationController::handleFile \
      $context $repository edit $target }
    wiki-new { ::fossilhub::mutationController::handleWiki \
      $context $repository create "" }
    wiki-edit { ::fossilhub::mutationController::handleWiki \
      $context $repository edit $target }
    ticket-new { ::fossilhub::mutationController::handleTicketNew \
      $context $repository }
    ticket { ::fossilhub::mutationController::handleTicket \
      $context $repository $target }
    forum-new { ::fossilhub::mutationController::handleForum \
      $context $repository thread "" }
    forum-reply { ::fossilhub::mutationController::handleForum \
      $context $repository reply $target }
    default {
      wapp-reply-code "404 Not Found"
      ::fossilhub::placeholder {Workbench not found — FossilHub} \
        {That repository workbench is unavailable.}
    }
  }
}
