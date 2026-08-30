namespace eval ::fossilhub::account {}

proc ::fossilhub::account::renderPage {content} {
  ::fossilhub::htmlPolicy
  wapp-mimetype "text/html; charset=utf-8"
  wapp-reply-extra Cache-Control {no-store, private}
  wapp-unsafe [::fossilhub::decoratePage $content]
}

proc ::fossilhub::account::cookieValue {name} {
  set raw [wapp-param HTTP_COOKIE ""]
  foreach item [split $raw {;}] {
    set item [string trim $item]
    set separator [string first = $item]
    if {$separator < 1} {
      continue
    }
    if {[string range $item 0 [expr {$separator - 1}]] eq $name} {
      return [string range $item [expr {$separator + 1}] end]
    }
  }
  return ""
}

proc ::fossilhub::account::requestContext {} {
  set context [dict create authenticated 0 user "" session_hash "" token ""]
  set token [::fossilhub::account::cookieValue fh_session]
  if {$token eq ""} {
    return $context
  }
  set session [::fossilhub::auth::sessionByToken $token]
  if {$session eq ""} {
    return $context
  }
  dict set context authenticated 1
  dict set context user [dict get $session user]
  dict set context session_hash [dict get $session session_hash]
  dict set context token $token
  dict set context reauthenticated_epoch [dict get $session reauthenticated_epoch]
  return $context
}

proc ::fossilhub::account::requestAddress {} {
  string range [wapp-param REMOTE_ADDR ""] 0 127
}

proc ::fossilhub::account::requestAgent {} {
  string range [wapp-param HTTP_USER_AGENT ""] 0 511
}

proc ::fossilhub::account::secureCookie {} {
  set policy auto
  if {[info exists ::env(FOSSILHUB_COOKIE_SECURE)]} {
    set policy [string tolower $::env(FOSSILHUB_COOKIE_SECURE)]
  }
  if {$policy eq "always"} {
    return 1
  }
  if {$policy eq "never"} {
    return 0
  }
  set forwarded [wapp-param HTTP_X_FORWARDED_PROTO ""]
  if {$forwarded eq ""} {
    set forwarded [wapp-param {.hdr:X-FORWARDED-PROTO} ""]
  }
  set forwarded [string tolower $forwarded]
  expr {[string tolower [wapp-param HTTPS ""]] in {on 1 true} ||
    [lindex [split $forwarded ,] 0] eq "https"}
}

proc ::fossilhub::account::setSessionCookie {token maxAge} {
  set value "fh_session=$token; Path=/; Max-Age=$maxAge; HttpOnly; SameSite=Lax"
  if {[::fossilhub::account::secureCookie]} {
    append value {; Secure}
  }
  wapp-reply-extra Set-Cookie $value
}

proc ::fossilhub::account::clearSessionCookie {} {
  set value {fh_session=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax}
  if {[::fossilhub::account::secureCookie]} {
    append value {; Secure}
  }
  wapp-reply-extra Set-Cookie $value
}

proc ::fossilhub::account::setLocaleCookie {locale} {
  set locale [::fossilhub::i18n::normalize $locale]
  if {$locale eq ""} {
    error "unsupported interface language"
  }
  set value "fh_locale=$locale; Path=/; Max-Age=31536000; SameSite=Lax"
  if {[::fossilhub::account::secureCookie]} {
    append value {; Secure}
  }
  wapp-reply-extra Set-Cookie $value
}

proc ::fossilhub::account::withLogoutChallenge {context} {
  if {[dict get $context authenticated]} {
    dict set context logout_token [::fossilhub::auth::issueChallenge \
      logout [dict get $context session_hash]]
  } else {
    dict set context logout_token ""
  }
  return $context
}

proc ::fossilhub::account::method {} {
  string toupper [wapp-param REQUEST_METHOD GET]
}

proc ::fossilhub::account::renderLogin {context {message ""} {login ""}} {
  if {[dict get $context authenticated]} {
    wapp-redirect dashboard
    return
  }
  set csrf [::fossilhub::auth::issueChallenge login]
  ::fossilhub::account::renderPage \
    [::fossilhub::views::renderLogin $context $csrf $message $login]
}

proc ::fossilhub::account::handleLogin {context} {
  set method [::fossilhub::account::method]
  if {$method eq "GET"} {
    ::fossilhub::account::renderLogin $context
    return
  }
  if {$method ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Sign in accepts GET and POST requests only.}
    return
  }
  set login [string range [wapp-param login ""] 0 253]
  set address [::fossilhub::account::requestAddress]
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] login]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::account::renderLogin $context \
      {This sign-in form expired. Try again.} $login
    return
  }
  if {![::fossilhub::auth::loginAllowed $login $address]} {
    wapp-reply-code "429 Too Many Requests"
    ::fossilhub::account::renderLogin $context \
      {Sign in is temporarily unavailable for these details. Try again later.} \
      $login
    return
  }
  if {[catch {set user [::fossilhub::auth::authenticate \
      $login [wapp-param password ""]]}] || $user eq ""} {
    ::fossilhub::auth::recordLoginFailure $login $address
    ::fossilhub::auth::audit user.login denied "" \
      [string tolower [string trim $login]]
    wapp-reply-code "401 Unauthorized"
    ::fossilhub::account::renderLogin $context \
      {The username/email or password is incorrect.} $login
    return
  }
  ::fossilhub::auth::clearLoginFailures $login $address
  set session [::fossilhub::auth::createSession [dict get $user id] \
    [::fossilhub::account::requestAgent] $address]
  ::fossilhub::auth::audit user.login success [dict get $user id]
  ::fossilhub::account::setSessionCookie [dict get $session token] 604800
  wapp-redirect dashboard
}

proc ::fossilhub::account::renderRegister {context {message ""} {values {}}} {
  if {[dict get $context authenticated]} {
    wapp-redirect dashboard
    return
  }
  if {![::fossilhub::auth::registrationOpen]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::placeholder {Registration closed — FossilHub} \
      {New account registration is currently closed.}
    return
  }
  set csrf [::fossilhub::auth::issueChallenge register]
  ::fossilhub::account::renderPage \
    [::fossilhub::views::renderRegister $context $csrf $message $values]
}

proc ::fossilhub::account::handleRegister {context} {
  set method [::fossilhub::account::method]
  if {$method eq "GET"} {
    ::fossilhub::account::renderRegister $context
    return
  }
  if {$method ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Account registration accepts GET and POST requests only.}
    return
  }
  set values [dict create \
    username [string range [wapp-param username ""] 0 80] \
    email [string range [wapp-param email ""] 0 300] \
    display_name [string range [wapp-param display_name ""] 0 160]]
  if {![::fossilhub::auth::consumeChallenge \
      [wapp-param csrf ""] register]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::account::renderRegister $context \
      {This registration form expired. Try again.} $values
    return
  }
  set password [wapp-param password ""]
  if {![::fossilhub::auth::constantTimeEqual \
      $password [wapp-param password_confirm ""]]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::account::renderRegister $context \
      {The password confirmation does not match.} $values
    return
  }
  if {[catch {
    set user [::fossilhub::auth::createUser \
      [dict get $values username] [dict get $values email] $password \
      [dict get $values display_name]]
  } message]} {
    wapp-reply-code "422 Unprocessable Content"
    if {[string match {Username must*} $message] ||
        [string match {That username*} $message] ||
        [string match {Enter a valid*} $message] ||
        [string match {Display name*} $message] ||
        [string match {Password must*} $message]} {
      set publicMessage $message
    } else {
      set publicMessage {An account with those details cannot be created.}
    }
    ::fossilhub::account::renderRegister $context $publicMessage $values
    return
  }
  set session [::fossilhub::auth::createSession [dict get $user id] \
    [::fossilhub::account::requestAgent] \
    [::fossilhub::account::requestAddress]]
  ::fossilhub::account::setSessionCookie [dict get $session token] 604800
  wapp-redirect dashboard
}

proc ::fossilhub::account::handleLogout {context} {
  if {[::fossilhub::account::method] ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Sign out requires a submitted form.}
    return
  }
  if {![dict get $context authenticated]} {
    ::fossilhub::account::clearSessionCookie
    wapp-redirect ./
    return
  }
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] logout \
      [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::placeholder {Form expired — FossilHub} \
      {Reload your account page before signing out.}
    return
  }
  ::fossilhub::auth::revokeSessionByHash [dict get $context session_hash]
  ::fossilhub::auth::audit user.logout success \
    [dict get [dict get $context user] id]
  ::fossilhub::account::clearSessionCookie
  wapp-redirect ./
}

proc ::fossilhub::account::requireUser {context} {
  if {[dict get $context authenticated]} {
    return 1
  }
  wapp-redirect ../login
  return 0
}

proc ::fossilhub::account::handleDashboard {context} {
  if {![::fossilhub::account::requireUser $context]} {
    return
  }
  if {[::fossilhub::account::method] ne "GET"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {The dashboard is read-only.}
    return
  }
  set userId [dict get [dict get $context user] id]
  set data [::fossilhub::workspace::dashboard $userId]
  set context [::fossilhub::account::withLogoutChallenge $context]
  ::fossilhub::account::renderPage \
    [::fossilhub::views::renderDashboard $context $data]
}

proc ::fossilhub::account::handlePublicProfile {context username} {
  if {[::fossilhub::account::method] ne "GET"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Public profiles are read-only.}
    return
  }
  set profile [::fossilhub::workspace::publicProfile $username]
  if {$profile eq ""} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {Profile not found — FossilHub} \
      {That active field record is not available.}
    return
  }
  set context [::fossilhub::account::withLogoutChallenge $context]
  ::fossilhub::account::renderPage \
    [::fossilhub::views::renderPublicProfile $context $profile]
}

proc ::fossilhub::account::renderSettings {context {message ""} {values ""}} {
  set user [dict get $context user]
  if {$values eq ""} {
    set values $user
  }
  set context [::fossilhub::account::withLogoutChallenge $context]
  set profileCsrf [::fossilhub::auth::issueChallenge account-profile \
    [dict get $context session_hash]]
  set deactivateCsrf [::fossilhub::auth::issueChallenge account-deactivate \
    [dict get $context session_hash]]
  ::fossilhub::account::renderPage [::fossilhub::views::renderSettings \
    $context $profileCsrf $deactivateCsrf $message $values]
}

proc ::fossilhub::account::handleSettings {context} {
  if {![::fossilhub::account::requireUser $context]} {
    return
  }
  set method [::fossilhub::account::method]
  if {$method eq "GET"} {
    set message [expr {[wapp-param updated ""] eq "1" ?
      "Profile settings saved." : ""}]
    ::fossilhub::account::renderSettings $context $message
    return
  }
  if {$method ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Account settings accept GET and POST requests only.}
    return
  }
  set values [dict create \
    display_name [string range [wapp-param display_name ""] 0 160] \
    email [string range [wapp-param email ""] 0 300] \
    biography [string range [wapp-param biography ""] 0 2000] \
    website [string range [wapp-param website ""] 0 500] \
    location [string range [wapp-param location ""] 0 200]]
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] \
      account-profile [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::account::renderSettings $context \
      {This profile form expired. Try again.} $values
    return
  }
  if {[catch {::fossilhub::workspace::updateProfile \
      [dict get [dict get $context user] id] $values} message]} {
    wapp-reply-code "422 Unprocessable Content"
    if {[regexp {^(Display name|Enter a valid|Biography|Website|Location)} \
        $message]} {
      set publicMessage $message
    } else {
      set publicMessage {Those profile settings could not be saved.}
    }
    ::fossilhub::account::renderSettings $context $publicMessage $values
    return
  }
  wapp-redirect {settings?updated=1}
}

proc ::fossilhub::account::handleDeactivate {context} {
  if {![::fossilhub::account::requireUser $context]} {
    return
  }
  if {[::fossilhub::account::method] ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Account deactivation requires a submitted form.}
    return
  }
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] \
      account-deactivate [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::account::renderSettings $context \
      {This deactivation form expired. Try again.}
    return
  }
  if {[wapp-param confirmation ""] ne \
      [dict get [dict get $context user] username]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::account::renderSettings $context \
      {Type your username exactly to confirm deactivation.}
    return
  }
  if {[catch {::fossilhub::workspace::deactivate \
      [dict get [dict get $context user] id] \
      [wapp-param current_password ""]} message]} {
    wapp-reply-code "422 Unprocessable Content"
    if {[string match {Current password*} $message] ||
        [string match {The last active administrator*} $message]} {
      set publicMessage $message
    } else {
      set publicMessage {The account could not be deactivated.}
    }
    ::fossilhub::account::renderSettings $context $publicMessage
    return
  }
  ::fossilhub::account::clearSessionCookie
  wapp-redirect ../
}

proc ::fossilhub::account::renderSecurity {context {message ""}} {
  if {$message eq "" &&
      [dict get [dict get $context user] must_change_password]} {
    set message {Change the one-time bootstrap password before continuing.}
  }
  set context [::fossilhub::account::withLogoutChallenge $context]
  set csrf [::fossilhub::auth::issueChallenge account-password \
    [dict get $context session_hash]]
  set sessions [::fossilhub::auth::sessionsForUser \
    [dict get [dict get $context user] id]]
  ::fossilhub::account::renderPage [::fossilhub::views::renderSecurity \
    $context $csrf $sessions $message]
}

proc ::fossilhub::account::handleSecurity {context} {
  if {![::fossilhub::account::requireUser $context]} {
    return
  }
  set method [::fossilhub::account::method]
  if {$method eq "GET"} {
    set message ""
    if {[wapp-param changed ""] eq "1"} {
      set message {Password changed. Other sessions were revoked.}
    }
    ::fossilhub::account::renderSecurity $context $message
    return
  }
  if {$method ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Account security accepts GET and POST requests only.}
    return
  }
  if {![::fossilhub::auth::consumeChallenge \
      [wapp-param csrf ""] account-password \
      [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::account::renderSecurity $context \
      {This password form expired. Try again.}
    return
  }
  set newPassword [wapp-param new_password ""]
  if {![::fossilhub::auth::constantTimeEqual \
      $newPassword [wapp-param new_password_confirm ""]]} {
    wapp-reply-code "422 Unprocessable Content"
    ::fossilhub::account::renderSecurity $context \
      {The new password confirmation does not match.}
    return
  }
  if {[catch {::fossilhub::auth::changePassword \
      [dict get [dict get $context user] id] \
      [wapp-param current_password ""] $newPassword \
      [dict get $context session_hash]} message]} {
    wapp-reply-code "422 Unprocessable Content"
    if {[string match {Current password*} $message] ||
        [string match {Password must*} $message]} {
      set publicMessage $message
    } else {
      set publicMessage {The password could not be changed.}
    }
    ::fossilhub::account::renderSecurity $context $publicMessage
    return
  }
  set newSession [::fossilhub::auth::createSession \
    [dict get [dict get $context user] id] \
    [::fossilhub::account::requestAgent] \
    [::fossilhub::account::requestAddress]]
  ::fossilhub::account::setSessionCookie [dict get $newSession token] 604800
  wapp-redirect {security?changed=1}
}

proc ::fossilhub::account::handleSessionRevoke {context} {
  if {![::fossilhub::account::requireUser $context]} {
    return
  }
  if {[::fossilhub::account::method] ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Session revocation requires a submitted form.}
    return
  }
  set target [string tolower [wapp-param session ""]]
  set purpose "revoke-session:$target"
  if {![::fossilhub::auth::consumeChallenge [wapp-param csrf ""] $purpose \
      [dict get $context session_hash]]} {
    wapp-reply-code "403 Forbidden"
    ::fossilhub::placeholder {Form expired — FossilHub} \
      {Reload your account security page before revoking a session.}
    return
  }
  set userId [dict get [dict get $context user] id]
  if {![::fossilhub::auth::revokeUserSession $userId $target]} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder {Session not found — FossilHub} \
      {That session is no longer active.}
    return
  }
  ::fossilhub::auth::audit user.session-revoke success $userId \
    [string range $target 0 11]
  if {$target eq [dict get $context session_hash]} {
    ::fossilhub::account::clearSessionCookie
    wapp-redirect ../../
  } else {
    wapp-redirect ../security
  }
}

proc ::fossilhub::account::isAdministrator {context} {
  expr {[dict get $context authenticated] &&
    [dict get [dict get $context user] role] eq "administrator"}
}

proc ::fossilhub::account::recentlyAuthenticated {context {seconds 600}} {
  if {![dict get $context authenticated] ||
      ![string is integer -strict $seconds] || $seconds < 1} {
    return 0
  }
  expr {[dict get $context reauthenticated_epoch] >= [clock seconds] - $seconds}
}
