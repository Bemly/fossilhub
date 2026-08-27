namespace eval ::fossilhub::views {}

proc ::fossilhub::views::accountFrame {title eyebrow heading lede content context} {
  set authenticated [dict get $context authenticated]
  if {$authenticated} {
    set user [dict get $context user]
    set identity [format {
      <a href="#" data-hub-path="/account/security">%s</a>
      <form class="nav-form" action="logout" method="post" data-hub-action="/logout">
        <input type="hidden" name="csrf" value="%s">
        <button type="submit">Sign out</button>
      </form>} \
      [::fossilhub::view::escape [dict get $user username]] \
      [::fossilhub::view::escape [dict get $context logout_token]]]
  } else {
    set identity {
      <a href="#" data-hub-path="/login">Sign in</a>
      <a href="#" data-hub-path="/register">Create account</a>}
  }
  return [format {<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%s — FossilHub</title>
<script>try{const t=localStorage.getItem('fh-theme');if(t)document.documentElement.dataset.theme=t}catch(e){}</script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@500;600;700;800&amp;family=IBM+Plex+Mono:wght@400;500&amp;family=IBM+Plex+Sans:wght@400;500;600&amp;display=swap" rel="stylesheet">
<link rel="stylesheet" href="fh.css">
</head>
<body class="account-body">
<div class="rail account-rail" aria-hidden="true"><div class="rail-track"></div><span class="rail-label" style="top:16%%">ID</span><span class="rail-label" style="top:49%%">ACL</span><span class="rail-label" style="top:82%%">LOG</span></div>
<header class="topbar">
  <div class="wrap">
    <a class="wordmark" href="#" data-hub-path="/" aria-label="FossilHub home">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" aria-hidden="true"><path d="M12 12a1.1 1.1 0 0 1 1.1 1.1A2.2 2.2 0 0 1 10.9 15.3 3.6 3.6 0 0 1 7.3 11.7 5.2 5.2 0 0 1 12.5 6.5 7 7 0 0 1 19.5 13.5"/></svg>
      <b>Fossilhub</b>
    </a>
    <nav class="topnav account-nav" aria-label="Account navigation">
      <a href="#" data-hub-path="/explore">Explore</a>%s
    </nav>
    <button class="theme-btn" id="themeBtn" type="button" aria-label="Toggle color theme"><svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M20 13A8 8 0 1 1 11 4a6.5 6.5 0 0 0 9 9Z"/></svg><svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2"/></svg></button>
  </div>
</header>
<main class="account-main">
  <div class="wrap account-grid">
    <section class="account-intro">
      <p class="eyebrow">%s</p>
      <h1>%s</h1>
      <p>%s</p>
      <div class="identity-strata" aria-hidden="true"><span>Identity</span><span>Access</span><span>Audit</span></div>
    </section>
    <section class="account-panel">%s</section>
  </div>
</main>
<script src="fossilhub-live.js"></script>
<script>const b=document.getElementById('themeBtn');if(b)b.addEventListener('click',()=>{const n=document.documentElement.dataset.theme==='dark'?'light':'dark';document.documentElement.dataset.theme=n;localStorage.setItem('fh-theme',n)});</script>
</body>
</html>} \
    [::fossilhub::view::escape $title] $identity \
    [::fossilhub::view::escape $eyebrow] \
    [::fossilhub::view::escape $heading] \
    [::fossilhub::view::escape $lede] $content]
}

proc ::fossilhub::views::accountNotice {message} {
  if {$message eq ""} {
    return ""
  }
  return [format {<div class="form-notice" role="alert">%s</div>} \
    [::fossilhub::view::escape $message]]
}

proc ::fossilhub::views::renderLogin {context csrf {message ""} {login ""}} {
  set content [format {%s
    <form class="field-form" action="login" method="post" data-hub-action="/login">
      <input type="hidden" name="csrf" value="%s">
      <label>Username or email<input name="login" type="text" autocomplete="username" maxlength="254" value="%s" required autofocus></label>
      <label>Password<input name="password" type="password" autocomplete="current-password" maxlength="1024" required></label>
      <button class="btn btn-primary" type="submit">Sign in</button>
    </form>
    <p class="form-foot">New to this dig? <a href="#" data-hub-path="/register">Create an account</a>.</p>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $csrf] \
    [::fossilhub::view::escape $login]]
  return [::fossilhub::views::accountFrame {Sign in} {Identity checkpoint} \
    {Return to the field} \
    {Your account opens the repositories and tools assigned to you.} \
    $content $context]
}

proc ::fossilhub::views::renderRegister {context csrf {message ""} {values {}}} {
  set defaults [dict create username "" email "" display_name ""]
  set values [dict merge $defaults $values]
  set content [format {%s
    <form class="field-form" action="register" method="post" data-hub-action="/register">
      <input type="hidden" name="csrf" value="%s">
      <label>Username<input name="username" type="text" autocomplete="username" maxlength="39" pattern="[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?" value="%s" required></label>
      <label>Display name<input name="display_name" type="text" autocomplete="name" maxlength="80" value="%s"></label>
      <label>Email<input name="email" type="email" autocomplete="email" maxlength="254" value="%s" required></label>
      <label>Password<input name="password" type="password" autocomplete="new-password" minlength="12" maxlength="1024" required><small>At least 12 characters. Passwords are stored with Argon2id.</small></label>
      <label>Confirm password<input name="password_confirm" type="password" autocomplete="new-password" maxlength="1024" required></label>
      <button class="btn btn-primary" type="submit">Create account</button>
    </form>
    <p class="form-foot">Already registered? <a href="#" data-hub-path="/login">Sign in</a>.</p>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $csrf] \
    [::fossilhub::view::escape [dict get $values username]] \
    [::fossilhub::view::escape [dict get $values display_name]] \
    [::fossilhub::view::escape [dict get $values email]]]
  return [::fossilhub::views::accountFrame {Create account} {Open a field record} \
    {Claim your survey mark} \
    {One identity follows every commit, field note, ticket, and discussion.} \
    $content $context]
}

proc ::fossilhub::views::renderSecurity {context passwordCsrf sessions message} {
  set user [dict get $context user]
  set rows ""
  foreach session $sessions {
    set current [expr {[dict get $session id_hash] eq \
      [dict get $context session_hash]}]
    set label [expr {$current ? "Current session" : "Signed-in session"}]
    set purpose "revoke-session:[dict get $session id_hash]"
    set challenge [::fossilhub::auth::issueChallenge \
      $purpose [dict get $context session_hash]]
    append rows [format {
      <div class="session-row">
        <div><b>%s</b><small>Last seen %s · expires %s · mark %s</small></div>
        <form action="revoke" method="post" data-hub-action="/account/session/revoke">
          <input type="hidden" name="csrf" value="%s"><input type="hidden" name="session" value="%s">
          <button class="btn btn-ghost btn-compact" type="submit">%s</button>
        </form>
      </div>} \
      $label \
      [::fossilhub::view::escape [::fossilhub::view::formatDate \
        [dict get $session seen_epoch]]] \
      [::fossilhub::view::escape [::fossilhub::view::formatDate \
        [dict get $session absolute_expires_epoch]]] \
      [::fossilhub::view::escape [string range [dict get $session id_hash] 0 9]] \
      [::fossilhub::view::escape $challenge] \
      [::fossilhub::view::escape [dict get $session id_hash]] \
      [expr {$current ? "Sign out" : "Revoke"}]]
  }
  set content [format {%s
    <div class="account-label"><span>Signed in as</span><b>%s</b><small>%s · %s</small></div>
    <h2>Change password</h2>
    <form class="field-form compact-form" action="security" method="post" data-hub-action="/account/security">
      <input type="hidden" name="csrf" value="%s">
      <label>Current password<input name="current_password" type="password" autocomplete="current-password" maxlength="1024" required></label>
      <label>New password<input name="new_password" type="password" autocomplete="new-password" minlength="12" maxlength="1024" required></label>
      <label>Confirm new password<input name="new_password_confirm" type="password" autocomplete="new-password" maxlength="1024" required></label>
      <button class="btn btn-primary" type="submit">Change password</button>
    </form>
    <div class="section-rule"></div><h2>Active sessions</h2><div class="session-list">%s</div>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape [dict get $user display_name]] \
    [::fossilhub::view::escape [dict get $user username]] \
    [::fossilhub::view::escape [dict get $user role]] \
    [::fossilhub::view::escape $passwordCsrf] $rows]
  return [::fossilhub::views::accountFrame {Account security} \
    {Identity · security} {Secure your field record} \
    {Change your credential and close sessions you no longer recognize.} \
    $content $context]
}
