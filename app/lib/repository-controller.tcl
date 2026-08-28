namespace eval ::fossilhub::repositoryController {}

proc ::fossilhub::repositoryController::methodAllowed {expected message} {
  if {[::fossilhub::account::method] eq $expected} {
    return 1
  }
  wapp-reply-code "405 Method Not Allowed"
  ::fossilhub::placeholder {Method not allowed — FossilHub} $message
  return 0
}

proc ::fossilhub::repositoryController::publicError {message fallback} {
  foreach pattern {
    {Repository name must*}
    {Repository title must*}
    {Repository description must*}
    {Repository visibility must*}
    {Default branch contains*}
    {That repository name is reserved.}
    {A repository with that name already exists.}
    {A repository file with that name already exists.}
    {Repository is busy.*}
    {Repository catalogue update failed.}
    {Collaborator role is invalid.}
    {The repository owner already has full access.}
    {That user already owns the repository.}
    {Archived repository *}
    {Repository is not active.}
    {Repository is not archived.}
    {Repository file is unavailable.}
    {Repository cannot be restored from quarantine.}
    {Repository quarantine target already exists.}
  } {
    if {[string match $pattern $message]} {
      return $message
    }
  }
  return $fallback
}

proc ::fossilhub::repositoryController::accountDepth {} {
  set segments [split [string trim [::fossilhub::requestPath] /] /]
  set accountIndex -1
  for {set index [expr {[llength $segments] - 1}]} {$index >= 0} {incr index -1} {
    if {[lindex $segments $index] eq "account"} {
      set accountIndex $index
      break
    }
  }
  if {$accountIndex < 0} {
    return 0
  }
  return [expr {[llength $segments] - $accountIndex - 1}]
}

proc ::fossilhub::repositoryController::relativeRoot {target} {
  return "[string repeat ../ [::fossilhub::repositoryController::accountDepth]]$target"
}

proc ::fossilhub::repositoryController::relativeAccount {target} {
  set depth [expr {max(0,
    [::fossilhub::repositoryController::accountDepth] - 1)}]
  return "[string repeat ../ $depth]$target"
}

proc ::fossilhub::repositoryController::requireUser {context} {
  if {![dict get $context authenticated]} {
    wapp-redirect [::fossilhub::repositoryController::relativeRoot login]
    return 0
  }
  if {[dict get [dict get $context user] must_change_password]} {
    wapp-redirect [::fossilhub::repositoryController::relativeAccount security]
    return 0
  }
  return 1
}

proc ::fossilhub::repositoryController::contextForPage {context} {
  ::fossilhub::account::withLogoutChallenge $context
}

proc ::fossilhub::repositoryController::repositoryForRoute {slug context capability} {
  if {[catch {set normalized [::fossilhub::repositories::validateSlug $slug]}] ||
      [set repository [::fossilhub::repositories::bySlug $normalized]] eq ""} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {Repository not found — FossilHub} \
      {That repository is not in this dig.}
    return ""
  }
  if {![::fossilhub::repositories::allows $repository $context $capability]} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::auth::audit repository.access denied \
      [expr {[dict get $context authenticated] ? \
        [dict get [dict get $context user] id] : ""}] $normalized \
      [dict get $repository id]
    ::fossilhub::placeholder {Repository not found — FossilHub} \
      {That repository is not in this dig.}
    return ""
  }
  return $repository
}

proc ::fossilhub::repositoryController::renderWorkspace {context} {
  set context [::fossilhub::repositoryController::contextForPage $context]
  set repositories [::fossilhub::repositories::forUser \
    [dict get [dict get $context user] id]]
  ::fossilhub::account::renderPage \
    [::fossilhub::views::renderRepositoryWorkspace $context $repositories]
}

proc ::fossilhub::repositoryController::handleWorkspace {context} {
  if {![::fossilhub::repositoryController::requireUser $context]} {
    return
  }
  if {![::fossilhub::repositoryController::methodAllowed GET \
      {The repository workspace is read-only.}]} {
    return
  }
  ::fossilhub::repositoryController::renderWorkspace $context
}

proc ::fossilhub::repositoryController::renderNew {context message values} {
  set context [::fossilhub::repositoryController::contextForPage $context]
  set challenge [::fossilhub::auth::issueChallenge repository-create \
    [dict get $context session_hash]]
  ::fossilhub::account::renderPage [::fossilhub::views::renderRepositoryNew \
    $context $challenge $message $values]
}

proc ::fossilhub::repositoryController::handleNew {context} {
  if {![::fossilhub::repositoryController::requireUser $context]} {
    return
  }
  set method [::fossilhub::account::method]
  if {$method eq "GET"} {
    ::fossilhub::repositoryController::renderNew $context "" {}
    return
  }
  if {$method ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Repository creation accepts GET and POST requests only.}
    return
  }
  set values [dict create \
    slug [string range [wapp-param slug ""] 0 80] \
    title [string range [wapp-param title ""] 0 160] \
    description [string range [wapp-param description ""] 0 800] \
    visibility [string range [wapp-param visibility public] 0 16]]
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] \
      repository-create [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::repositoryController::renderNew $context \
      {This repository form expired. Try again.} $values
    return
  }
  if {[catch {set repository [::fossilhub::repositories::create \
      [dict get $context user] [dict get $values slug] \
      [dict get $values title] [dict get $values description] \
      [dict get $values visibility]]} message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::repositoryController::renderNew $context \
      [::fossilhub::repositoryController::publicError $message \
        {The repository could not be created.}] $values
    return
  }
  wapp-redirect "../[dict get $repository slug]/settings?created=1"
}

proc ::fossilhub::repositoryController::settingsChallenges {context repository members} {
  set session [dict get $context session_hash]
  set id [dict get $repository id]
  set result [dict create]
  foreach action {settings member transfer archive restore} {
    dict set result $action [::fossilhub::auth::issueChallenge \
      "repository-$action:$id" $session]
  }
  foreach member $members {
    dict set result "remove:[dict get $member id]" \
      [::fossilhub::auth::issueChallenge \
        "repository-member-remove:$id:[dict get $member id]" $session]
  }
  return $result
}

proc ::fossilhub::repositoryController::renderSettings {context repository \
    message values} {
  set context [::fossilhub::repositoryController::contextForPage $context]
  set members [::fossilhub::repositories::members [dict get $repository id]]
  set challenges [::fossilhub::repositoryController::settingsChallenges \
    $context $repository $members]
  ::fossilhub::account::renderPage \
    [::fossilhub::views::renderRepositorySettings $context $repository \
      $members $challenges $message $values]
}

proc ::fossilhub::repositoryController::handleSettings {context slug} {
  if {![::fossilhub::repositoryController::requireUser $context]} {
    return
  }
  set repository [::fossilhub::repositoryController::repositoryForRoute \
    $slug $context manage]
  if {$repository eq ""} {
    return
  }
  set method [::fossilhub::account::method]
  if {$method eq "GET"} {
    set message ""
    foreach {key text} {
      created {Repository created.}
      saved {Repository settings saved.}
      members {Collaborator access updated.}
      transferred {Repository ownership transferred.}
      archived {Repository archived into quarantine.}
      restored {Repository restored.}
    } {
      if {[wapp-param $key ""] eq "1"} {
        set message $text
        break
      }
    }
    ::fossilhub::repositoryController::renderSettings \
      $context $repository $message {}
    return
  }
  if {$method ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Repository settings accepts GET and POST requests only.}
    return
  }
  set purpose "repository-settings:[dict get $repository id]"
  set values [dict create \
    title [string range [wapp-param title ""] 0 160] \
    description [string range [wapp-param description ""] 0 800] \
    visibility [string range [wapp-param visibility ""] 0 16] \
    default_branch [string range [wapp-param default_branch ""] 0 160]]
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] \
      $purpose [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::repositoryController::renderSettings $context $repository \
      {This settings form expired. Try again.} $values
    return
  }
  if {[catch {::fossilhub::repositories::updateSettings $repository \
      [dict get $values title] [dict get $values description] \
      [dict get $values visibility] [dict get $values default_branch] \
      [dict get [dict get $context user] id]} message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::repositoryController::renderSettings \
      $context $repository \
      [::fossilhub::repositoryController::publicError $message \
        {Repository settings could not be saved.}] $values
    return
  }
  wapp-redirect {settings?saved=1}
}

proc ::fossilhub::repositoryController::handleMember {context slug remove} {
  if {![::fossilhub::repositoryController::requireUser $context] ||
      ![::fossilhub::repositoryController::methodAllowed POST \
        {Collaborator changes require a submitted form.}]} {
    return
  }
  set repository [::fossilhub::repositoryController::repositoryForRoute \
    $slug $context manage]
  if {$repository eq ""} {
    return
  }
  if {[dict get $repository state] ne "active"} {
    wapp-reply-code "409 Conflict"
    ::fossilhub::placeholder {Repository archived — FossilHub} \
      {Restore this repository before changing collaborators.}
    return
  }
  set userId [string range [wapp-param user ""] 0 80]
  if {$remove} {
    set purpose "repository-member-remove:[dict get $repository id]:$userId"
  } else {
    set purpose "repository-member:[dict get $repository id]"
  }
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] \
      $purpose [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::placeholder {Form expired — FossilHub} \
      {Reload repository settings before changing collaborators.}
    return
  }
  if {$remove} {
    if {![::fossilhub::repositories::removeMember $repository $userId \
        [dict get [dict get $context user] id]]} {
      wapp-reply-code "404 Not Found"
      ::fossilhub::placeholder {Collaborator not found — FossilHub} \
        {That collaborator no longer has access.}
      return
    }
  } else {
    set user [::fossilhub::auth::userByUsername \
      [string range [wapp-param username ""] 0 80]]
    if {$user eq ""} {
      wapp-reply-code "422 Unprocessable Content"
      ::fossilhub::repositoryController::renderSettings $context $repository \
        {No active account has that username.} {}
      return
    }
    if {[catch {::fossilhub::repositories::addMember $repository $user \
        [string range [wapp-param role ""] 0 20] \
        [dict get [dict get $context user] id]} message]} {
      wapp-reply-code "422 Unprocessable Content"
      ::fossilhub::repositoryController::renderSettings \
        $context $repository \
        [::fossilhub::repositoryController::publicError $message \
          {Collaborator access could not be changed.}] {}
      return
    }
  }
  wapp-redirect {settings?members=1}
}

proc ::fossilhub::repositoryController::confirmSensitive {context repository \
    action} {
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] \
      "repository-$action:[dict get $repository id]" \
      [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::placeholder {Form expired — FossilHub} \
      {Reload repository settings before trying again.}
    return 0
  }
  if {![::fossilhub::account::recentlyAuthenticated $context] ||
      ![::fossilhub::auth::constantTimeEqual [wapp-param confirm ""] \
        [dict get $repository slug]]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::repositoryController::renderSettings $context $repository \
      {Recent authentication and an exact repository-name confirmation are required.} {}
    return 0
  }
  return 1
}

proc ::fossilhub::repositoryController::handleTransfer {context slug} {
  if {![::fossilhub::repositoryController::requireUser $context] ||
      ![::fossilhub::repositoryController::methodAllowed POST \
        {Ownership transfer requires a submitted form.}]} {
    return
  }
  set repository [::fossilhub::repositoryController::repositoryForRoute \
    $slug $context owner]
  if {$repository eq "" ||
      ![::fossilhub::repositoryController::confirmSensitive \
        $context $repository transfer]} {
    return
  }
  set nextOwner [::fossilhub::auth::userByUsername \
    [string range [wapp-param username ""] 0 80]]
  if {$nextOwner eq ""} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::repositoryController::renderSettings $context $repository \
      {No active account has that username.} {}
    return
  }
  if {[catch {::fossilhub::repositories::transfer $repository $nextOwner \
      [dict get [dict get $context user] id]} message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::repositoryController::renderSettings \
      $context $repository \
      [::fossilhub::repositoryController::publicError $message \
        {Repository ownership could not be transferred.}] {}
    return
  }
  wapp-redirect {settings?transferred=1}
}

proc ::fossilhub::repositoryController::handleArchive {context slug restore} {
  if {![::fossilhub::repositoryController::requireUser $context] ||
      ![::fossilhub::repositoryController::methodAllowed POST \
        {Archive changes require a submitted form.}]} {
    return
  }
  set repository [::fossilhub::repositoryController::repositoryForRoute \
    $slug $context owner]
  set action [expr {$restore ? "restore" : "archive"}]
  if {$repository eq "" ||
      ![::fossilhub::repositoryController::confirmSensitive \
        $context $repository $action]} {
    return
  }
  if {[catch {
    if {$restore} {
      ::fossilhub::repositories::restore $repository \
        [dict get [dict get $context user] id]
    } else {
      ::fossilhub::repositories::archive $repository \
        [dict get [dict get $context user] id]
    }
  } message]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::repositoryController::renderSettings \
      $context $repository \
      [::fossilhub::repositoryController::publicError $message \
        {The repository archive state could not be changed.}] {}
    return
  }
  set resultParameter [expr {$restore ? "restored" : "archived"}]
  wapp-redirect "settings?$resultParameter=1"
}
