namespace eval ::fossilhub::adminController {}

proc ::fossilhub::adminController::routeDepth {} {
  set segments [split [string trim [::fossilhub::requestPath] /] /]
  set index [lsearch -exact $segments admin]
  if {$index < 0} {
    return 1
  }
  return [expr {[llength $segments] - $index}]
}

proc ::fossilhub::adminController::relativeRoot {target} {
  return "[string repeat ../ [::fossilhub::adminController::routeDepth]]$target"
}

proc ::fossilhub::adminController::requireAdministrator {context} {
  if {[::fossilhub::account::isAdministrator $context]} {
    return 1
  }
  if {![dict get $context authenticated]} {
    wapp-redirect [::fossilhub::adminController::relativeRoot login]
  } else {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {Not found — FossilHub} \
      {That layer is not in this dig.}
  }
  return 0
}

proc ::fossilhub::adminController::pageContext {context} {
  ::fossilhub::account::withLogoutChallenge $context
}

proc ::fossilhub::adminController::method {expected message} {
  if {[::fossilhub::account::method] eq $expected} {
    return 1
  }
  wapp-reply-code "405 Method Not Allowed"
  ::fossilhub::placeholder {Method not allowed — FossilHub} $message
  return 0
}

proc ::fossilhub::adminController::validReturn {value} {
  expr {$value eq "" ||
    [regexp {^(users/[[:xdigit:]]{32}|repositories/[a-z0-9-]{1,39}|settings|health)$} \
      $value]}
}

proc ::fossilhub::adminController::renderReauth {context returnTo {message ""}} {
  if {![::fossilhub::adminController::validReturn $returnTo]} {
    set returnTo ""
  }
  set context [::fossilhub::adminController::pageContext $context]
  set csrf [::fossilhub::auth::issueChallenge admin-reauth \
    [dict get $context session_hash]]
  ::fossilhub::account::renderPage [::fossilhub::views::renderAdminReauth \
    $context $csrf $returnTo $message]
}

proc ::fossilhub::adminController::requireRecent {context returnTo} {
  if {[::fossilhub::account::recentlyAuthenticated $context]} {
    return 1
  }
  ::fossilhub::adminController::renderReauth $context $returnTo \
    {Confirm your password before this administrator action.}
  return 0
}

proc ::fossilhub::adminController::consume {context purpose returnTo} {
  if {![::fossilhub::adminController::requireRecent $context $returnTo]} {
    return 0
  }
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] $purpose \
      [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::placeholder {Form expired — FossilHub} \
      {Reload the administrator page before trying again.}
    return 0
  }
  return 1
}

proc ::fossilhub::adminController::options {kind} {
  switch -- $kind {
    users {
      return [dict create q [string range [wapp-param q ""] 0 120] \
        status [string range [wapp-param status all] 0 16] \
        role [string range [wapp-param role all] 0 20]]
    }
    repositories {
      return [dict create q [string range [wapp-param q ""] 0 120] \
        state [string range [wapp-param state all] 0 16] \
        visibility [string range [wapp-param visibility all] 0 16]]
    }
    audit {
      return [dict create q [string range [wapp-param q ""] 0 120] \
        outcome [string range [wapp-param outcome all] 0 16] \
        action [string range [wapp-param action ""] 0 100]]
    }
  }
  return [dict create]
}

proc ::fossilhub::adminController::handleOverview {context} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method GET \
        {The administrator overview is read-only.}]} {
    return
  }
  set context [::fossilhub::adminController::pageContext $context]
  ::fossilhub::account::renderPage [::fossilhub::views::renderAdminOverview \
    $context [::fossilhub::admin::overview] \
    [::fossilhub::admin::auditEvents "" all "" 20]]
}

proc ::fossilhub::adminController::handleUsers {context} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method GET \
        {The user index is read-only.}]} {
    return
  }
  set options [::fossilhub::adminController::options users]
  set users [::fossilhub::admin::users [dict get $options q] \
    [dict get $options status] [dict get $options role]]
  set context [::fossilhub::adminController::pageContext $context]
  ::fossilhub::account::renderPage \
    [::fossilhub::views::renderAdminUsers $context $users $options]
}

proc ::fossilhub::adminController::userChallenges {context id} {
  set result [dict create]
  foreach action {role status sessions} {
    dict set result $action [::fossilhub::auth::issueChallenge \
      "admin-user-$action:$id" [dict get $context session_hash]]
  }
  return $result
}

proc ::fossilhub::adminController::renderUser {context id {message ""}} {
  set user [::fossilhub::admin::userDetail $id]
  if {$user eq ""} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {User not found — FossilHub} \
      {That account record is unavailable.}
    return
  }
  set context [::fossilhub::adminController::pageContext $context]
  set challenges [::fossilhub::adminController::userChallenges $context $id]
  ::fossilhub::account::renderPage [::fossilhub::views::renderAdminUser \
    $context $user $challenges $message]
}

proc ::fossilhub::adminController::handleUser {context id} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method GET \
        {The user record is read-only.}]} {
    return
  }
  ::fossilhub::adminController::renderUser $context $id
}

proc ::fossilhub::adminController::handleUserAction {context id action} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method POST \
        {Administrator user changes require a submitted form.}]} {
    return
  }
  set returnTo "users/$id"
  if {![::fossilhub::adminController::consume $context \
      "admin-user-$action:$id" $returnTo]} {
    return
  }
  set actorId [dict get [dict get $context user] id]
  if {[catch {
    switch -- $action {
      role {
        ::fossilhub::admin::changeUserRole $actorId $id \
          [string range [wapp-param role ""] 0 20]
        set message {Platform role changed.}
      }
      status {
        ::fossilhub::admin::changeUserStatus $actorId $id \
          [string range [wapp-param status ""] 0 20]
        set message {Account access state changed and affected sessions closed.}
      }
      sessions {
        set count [::fossilhub::admin::revokeUserSessions $actorId $id]
        set message "$count active sessions revoked."
      }
      default { error "Administrator user action is invalid." }
    }
  } errorMessage]} {
    wapp-reply-code "422 Unprocessable Content"
    if {[regexp {^(User|The last active administrator)} $errorMessage]} {
      set message $errorMessage
    } else {
      set message {The user action could not be completed.}
    }
  }
  ::fossilhub::adminController::renderUser $context $id $message
}

proc ::fossilhub::adminController::handleRepositories {context} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method GET \
        {The repository index is read-only.}]} {
    return
  }
  set options [::fossilhub::adminController::options repositories]
  set repositories [::fossilhub::admin::repositories [dict get $options q] \
    [dict get $options state] [dict get $options visibility]]
  set context [::fossilhub::adminController::pageContext $context]
  ::fossilhub::account::renderPage [::fossilhub::views::renderAdminRepositories \
    $context $repositories $options]
}

proc ::fossilhub::adminController::repositoryChallenges {context repository} {
  set result [dict create]
  foreach action {archive restore integrity} {
    dict set result $action [::fossilhub::auth::issueChallenge \
      "admin-repository-$action:[dict get $repository id]" \
      [dict get $context session_hash]]
  }
  return $result
}

proc ::fossilhub::adminController::renderRepository {context slug {message ""}} {
  set repository [::fossilhub::admin::repositoryDetail $slug]
  if {$repository eq ""} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {Repository not found — FossilHub} \
      {That registry record is unavailable.}
    return
  }
  set context [::fossilhub::adminController::pageContext $context]
  set challenges [::fossilhub::adminController::repositoryChallenges \
    $context $repository]
  ::fossilhub::account::renderPage [::fossilhub::views::renderAdminRepository \
    $context $repository $challenges $message]
}

proc ::fossilhub::adminController::handleRepository {context slug} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method GET \
        {The administrator repository record is read-only.}]} {
    return
  }
  ::fossilhub::adminController::renderRepository $context $slug
}

proc ::fossilhub::adminController::handleRepositoryAction {context slug action} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method POST \
        {Administrator repository changes require a submitted form.}]} {
    return
  }
  set repository [::fossilhub::admin::repositoryDetail $slug]
  if {$repository eq ""} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {Repository not found — FossilHub} \
      {That registry record is unavailable.}
    return
  }
  if {![::fossilhub::adminController::consume $context \
      "admin-repository-$action:[dict get $repository id]" \
      "repositories/$slug"]} {
    return
  }
  set actorId [dict get [dict get $context user] id]
  if {[catch {
    switch -- $action {
      archive {
        ::fossilhub::repositories::archive $repository $actorId
        set message {Repository archived.}
      }
      restore {
        ::fossilhub::repositories::restore $repository $actorId
        set message {Repository restored.}
      }
      integrity {
        ::fossilhub::admin::checkRepositoryIntegrity $repository $actorId
        set message {Repository integrity check passed.}
      }
      default { error "Administrator repository action is invalid." }
    }
  } errorMessage]} {
    wapp-reply-code "422 Unprocessable Content"
    if {[regexp {^(Repository|Only an active)} $errorMessage]} {
      set message $errorMessage
    } else {
      set message {The repository action could not be completed.}
    }
  }
  ::fossilhub::adminController::renderRepository $context $slug $message
}

proc ::fossilhub::adminController::handleAudit {context export} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method GET \
        {The audit ledger is read-only.}]} {
    return
  }
  set options [::fossilhub::adminController::options audit]
  set events [::fossilhub::admin::auditEvents [dict get $options q] \
    [dict get $options outcome] [dict get $options action] \
    [expr {$export ? 1000 : 200}]]
  if {$export} {
    ::fossilhub::adminController::serveAuditCsv $events
    return
  }
  set context [::fossilhub::adminController::pageContext $context]
  ::fossilhub::account::renderPage \
    [::fossilhub::views::renderAdminAudit $context $events $options]
}

proc ::fossilhub::adminController::csvField {value} {
  set value [string map [list "\r" " " "\n" " "] $value]
  return "\"[string map [list \" \"\"] $value]\""
}

proc ::fossilhub::adminController::serveAuditCsv {events} {
  set csv "event_id,epoch,action,outcome,actor,repository\r\n"
  foreach event $events {
    set fields {}
    foreach key {id epoch action outcome actor repository_slug} {
      lappend fields [::fossilhub::adminController::csvField [dict get $event $key]]
    }
    append csv "[join $fields ,]\r\n"
  }
  wapp-mimetype "text/csv; charset=utf-8"
  wapp-cache-control {no-store, private}
  wapp-reply-extra X-Content-Type-Options nosniff
  wapp-reply-extra Content-Disposition {attachment; filename="fossilhub-audit.csv"}
  wapp-unsafe $csv
}

proc ::fossilhub::adminController::renderHealth {context {message ""}} {
  set context [::fossilhub::adminController::pageContext $context]
  set csrf [::fossilhub::auth::issueChallenge admin-catalogue-reindex \
    [dict get $context session_hash]]
  ::fossilhub::account::renderPage [::fossilhub::views::renderAdminHealth \
    $context [::fossilhub::admin::health] $csrf $message]
}

proc ::fossilhub::adminController::handleHealth {context} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method GET \
        {The health page is read-only.}]} {
    return
  }
  ::fossilhub::adminController::renderHealth $context
}

proc ::fossilhub::adminController::handleReindex {context} {
  if {![::fossilhub::adminController::requireAdministrator $context] ||
      ![::fossilhub::adminController::method POST \
        {Catalogue rebuild requires a submitted form.}] ||
      ![::fossilhub::adminController::consume $context \
        admin-catalogue-reindex health]} {
    return
  }
  if {[catch {set count [::fossilhub::admin::rebuildCatalogue \
      [dict get [dict get $context user] id]]}]} {
    wapp-reply-code "422 Unprocessable Content"
    set message {Catalogue rebuild failed.}
  } else {
    set message "Catalogue rebuilt from $count active public repositories."
  }
  ::fossilhub::adminController::renderHealth $context $message
}

proc ::fossilhub::adminController::renderSettings {context {message ""} \
    {values ""}} {
  if {$values eq ""} {
    set values [::fossilhub::admin::settings]
  }
  set context [::fossilhub::adminController::pageContext $context]
  set csrf [::fossilhub::auth::issueChallenge admin-settings \
    [dict get $context session_hash]]
  ::fossilhub::account::renderPage [::fossilhub::views::renderAdminSettings \
    $context $values $csrf $message]
}

proc ::fossilhub::adminController::handleSettings {context} {
  if {![::fossilhub::adminController::requireAdministrator $context]} {
    return
  }
  set method [::fossilhub::account::method]
  if {$method eq "GET"} {
    ::fossilhub::adminController::renderSettings $context
    return
  }
  if {$method ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Platform settings accept GET and POST requests only.}
    return
  }
  if {![::fossilhub::adminController::consume $context admin-settings settings]} {
    return
  }
  set values [dict create \
    registration [string range [wapp-param registration ""] 0 16] \
    default_visibility [string range [wapp-param default_visibility ""] 0 16] \
    repositories_per_user [string range [wapp-param repositories_per_user ""] 0 12] \
    repository_quota_mb [string range [wapp-param repository_quota_mb ""] 0 12] \
    maintenance_banner [string range [wapp-param maintenance_banner ""] 0 500]]
  if {[catch {::fossilhub::admin::updateSettings \
      [dict get [dict get $context user] id] $values} errorMessage]} {
    wapp-reply-code "422 Unprocessable Content"
    if {[regexp {^(Registration|Default visibility|Repository|Maintenance)} \
        $errorMessage]} {
      set message $errorMessage
    } else {
      set message {Platform policy could not be saved.}
    }
  } else {
    set message {Platform policy saved.}
  }
  ::fossilhub::adminController::renderSettings $context $message $values
}

proc ::fossilhub::adminController::handleReauth {context} {
  if {![::fossilhub::adminController::requireAdministrator $context]} {
    return
  }
  set returnTo [string range [wapp-param return_to ""] 0 120]
  if {![::fossilhub::adminController::validReturn $returnTo]} {
    set returnTo ""
  }
  if {[::fossilhub::account::method] eq "GET"} {
    ::fossilhub::adminController::renderReauth $context $returnTo
    return
  }
  if {![::fossilhub::adminController::method POST \
      {Administrator verification accepts GET and POST requests only.}]} {
    return
  }
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] admin-reauth \
      [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::adminController::renderReauth $context $returnTo \
      {This verification form expired. Try again.}
    return
  }
  if {![::fossilhub::auth::reauthenticate \
      [dict get [dict get $context user] id] [wapp-param password ""] \
      [dict get $context session_hash]]} {
    wapp-reply-code "401 Unauthorized"
    ::fossilhub::adminController::renderReauth $context $returnTo \
      {The current password is incorrect.}
    return
  }
  set target [expr {$returnTo eq "" ? "admin" : "admin/$returnTo"}]
  wapp-redirect [::fossilhub::adminController::relativeRoot $target]
}
