namespace eval ::fossilhub::views {}

proc ::fossilhub::views::localizedFormat {template args} {
  return [format [::fossilhub::i18n::template $template] {*}$args]
}

proc ::fossilhub::views::anonymousContext {} {
  return [dict create authenticated 0 user "" session_hash "" token "" \
    logout_token "" locale [::fossilhub::i18n::locale] return_to /]
}

proc ::fossilhub::views::siteTools {{context ""}} {
  if {$context eq ""} {
    set context [::fossilhub::views::anonymousContext]
  }
  set returnTo [expr {[dict exists $context return_to] ? \
    [dict get $context return_to] : "/"}]
  set locale [::fossilhub::i18n::locale]
  set nextLocale [expr {$locale eq "zh-CN" ? "en" : "zh-CN"}]
  set html [::fossilhub::views::localizedFormat {
    <div class="site-tools" aria-label="%s">
      <form class="locale-form" action="locale" method="post" data-hub-action="/locale">
        <input type="hidden" name="locale" value="%s">
        <input type="hidden" name="return_to" value="%s">
        <button type="submit" aria-label="%s">%s</button>
      </form>} \
    [::fossilhub::view::escape [::fossilhub::i18n::t account_navigation]] \
    $nextLocale [::fossilhub::view::escape $returnTo] \
    [::fossilhub::view::escape [::fossilhub::i18n::t locale_label]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t switch_language]]]
  if {[dict get $context authenticated]} {
    set user [dict get $context user]
    append html [::fossilhub::views::localizedFormat {
      <a href="#" data-hub-path="/dashboard">%s</a>
      <a href="#" data-hub-path="/account/repositories">%s</a>
      <a href="#" data-hub-path="/users/%s">%s</a>
      <a href="#" data-hub-path="/settings">%s</a>} \
      [::fossilhub::view::escape [::fossilhub::i18n::t dashboard]] \
      [::fossilhub::view::escape [::fossilhub::i18n::t repositories]] \
      [::fossilhub::view::escape [dict get $user username]] \
      [::fossilhub::view::escape [::fossilhub::i18n::t profile]] \
      [::fossilhub::view::escape [::fossilhub::i18n::t settings]]]
    if {[dict get $user role] eq "administrator"} {
      append html [::fossilhub::views::localizedFormat {<a href="#" data-hub-path="/admin">%s</a>} \
        [::fossilhub::view::escape [::fossilhub::i18n::t admin]]]
    }
    set logoutToken [expr {[dict exists $context logout_token] ? \
      [dict get $context logout_token] : ""}]
    append html [::fossilhub::views::localizedFormat {
      <form class="nav-form" action="logout" method="post" data-hub-action="/logout">
        <input type="hidden" name="csrf" value="%s">
        <button type="submit">%s</button>
      </form>} \
      [::fossilhub::view::escape $logoutToken] \
      [::fossilhub::view::escape [::fossilhub::i18n::t sign_out]]]
  } else {
    append html [::fossilhub::views::localizedFormat {
      <a href="#" data-hub-path="/login">%s</a>
      <a class="site-register" href="#" data-hub-path="/register">%s</a>} \
      [::fossilhub::view::escape [::fossilhub::i18n::t sign_in]] \
      [::fossilhub::view::escape [::fossilhub::i18n::t register]]]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::views::accountFrame {title eyebrow heading lede content context} {
  set identity [::fossilhub::views::siteTools $context]
  set title [::fossilhub::i18n::phrase $title]
  set eyebrow [::fossilhub::i18n::phrase $eyebrow]
  set heading [::fossilhub::i18n::phrase $heading]
  set lede [::fossilhub::i18n::phrase $lede]
  return [::fossilhub::views::localizedFormat {<!doctype html>
<html lang="%s">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%s — FossilHub</title>
<script>try{const t=localStorage.getItem('fh-theme');document.documentElement.dataset.theme=t||(matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light')}catch(e){}</script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@500;600;700;800&amp;family=IBM+Plex+Mono:wght@400;500&amp;family=IBM+Plex+Sans:wght@400;500;600&amp;display=swap" rel="stylesheet">
<link rel="stylesheet" href="fh.css?v=20260830-2">
</head>
<body class="account-body">
<div class="rail account-rail" aria-hidden="true"><div class="rail-track"></div><span class="rail-label" style="top:16%%">ID</span><span class="rail-label" style="top:49%%">ACL</span><span class="rail-label" style="top:82%%">LOG</span></div>
<header class="topbar">
  <div class="wrap">
    <a class="wordmark" href="#" data-hub-path="/" aria-label="FossilHub home">
      <img src="fossilhub-hub-lockup-v1.png?v=20260829-1" width="137" height="50" alt="FossilHub">
    </a>
    <nav class="topnav account-nav" aria-label="Account navigation">
      <a href="#" data-hub-path="/explore">%s</a>%s
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
      <div class="identity-strata" aria-hidden="true"><span>%s</span><span>%s</span><span>%s</span></div>
    </section>
    <section class="account-panel">%s</section>
  </div>
</main>
<script src="fossilhub-live.js?v=20260828-3"></script>
<script>const b=document.getElementById('themeBtn');if(b)b.addEventListener('click',()=>{const n=document.documentElement.dataset.theme==='dark'?'light':'dark';document.documentElement.dataset.theme=n;localStorage.setItem('fh-theme',n)});</script>
</body>
</html>} \
    [::fossilhub::i18n::locale] \
    [::fossilhub::view::escape $title] \
    [::fossilhub::view::escape [::fossilhub::i18n::t explore]] $identity \
    [::fossilhub::view::escape $eyebrow] \
    [::fossilhub::view::escape $heading] \
    [::fossilhub::view::escape $lede] \
    [::fossilhub::view::escape [::fossilhub::i18n::t identity]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t access]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t audit]] $content]
}

proc ::fossilhub::views::accountNotice {message} {
  if {$message eq ""} {
    return ""
  }
  return [::fossilhub::views::localizedFormat {<div class="form-notice" role="alert">%s</div>} \
    [::fossilhub::view::escape $message]]
}

proc ::fossilhub::views::activityLabel {action} {
  set labels [dict create \
    user.register {created an account} \
    user.profile-update {updated their profile} \
    repository.create {created a repository} \
    repository.settings {updated repository settings} \
    repository.member-add {added a collaborator} \
    repository.member-remove {removed a collaborator} \
    repository.transfer {transferred a repository} \
    repository.archive {archived a repository} \
    repository.restore {restored a repository} \
    repository.file-create {created a file} \
    repository.file-edit {updated a file} \
    repository.file-delete {deleted a file} \
    repository.wiki-create {created a Wiki page} \
    repository.wiki-edit {updated a Wiki page} \
    repository.ticket-create {opened a Ticket} \
    repository.ticket-update {updated a Ticket} \
    repository.forum-thread {opened a discussion} \
    repository.forum-reply {replied to a discussion}]
  if {[dict exists $labels $action]} {
    return [::fossilhub::i18n::phrase [dict get $labels $action]]
  }
  return [string map {. { · } - { }} $action]
}

proc ::fossilhub::views::renderWorkspaceRepositories {repositories emptyText} {
  if {[llength $repositories] == 0} {
    return [::fossilhub::views::localizedFormat {<div class="workspace-empty"><p>%s</p></div>} \
      [::fossilhub::view::escape [::fossilhub::i18n::phrase $emptyText]]]
  }
  set html {<div class="workspace-list">}
  foreach repository $repositories {
    set role "Owner"
    if {[dict exists $repository membership_role]} {
      set role [string totitle [dict get $repository membership_role]]
    }
    append html [::fossilhub::views::localizedFormat {
      <article class="workspace-repository">
        <div><div class="workspace-repo-title"><a href="#" data-hub-path="/repo/%s">%s</a><span class="repo-state repo-state-%s">%s</span></div>
        <p>%s</p><small>%s · %s · updated %s</small></div>
        <a class="btn btn-ghost btn-compact" href="#" data-hub-path="/repo/%s">Open</a>
      </article>} \
      [::fossilhub::view::escape [dict get $repository name]] \
      [::fossilhub::view::escape [dict get $repository title]] \
      [::fossilhub::view::escape [dict get $repository visibility]] \
      [::fossilhub::view::escape [dict get $repository visibility]] \
      [::fossilhub::view::escape [dict get $repository description]] \
      [::fossilhub::view::escape [::fossilhub::i18n::phrase $role]] \
      [::fossilhub::view::escape [::fossilhub::i18n::phrase \
        [dict get $repository state]]] \
      [::fossilhub::view::escape [::fossilhub::view::formatDate \
        [dict get $repository updated_epoch]]] \
      [::fossilhub::view::escape [dict get $repository name]]]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::views::renderActivity {activity emptyText} {
  if {[llength $activity] == 0} {
    return [::fossilhub::views::localizedFormat {<div class="workspace-empty"><p>%s</p></div>} \
      [::fossilhub::view::escape [::fossilhub::i18n::phrase $emptyText]]]
  }
  set html {<ol class="activity-list">}
  foreach event $activity {
    set repository [dict get $event repository_slug]
    set context ""
    if {$repository ne ""} {
      set context [::fossilhub::views::localizedFormat { in <a href="#" data-hub-path="/repo/%s">%s</a>} \
        [::fossilhub::view::escape "${repository}.fossil"] \
        [::fossilhub::view::escape [dict get $event repository_title]]]
    }
    append html [::fossilhub::views::localizedFormat {
      <li><span class="activity-mark" aria-hidden="true"></span><div><b>%s</b>%s<small>%s · %s</small></div></li>} \
      [::fossilhub::view::escape [::fossilhub::views::activityLabel \
        [dict get $event action]]] $context \
      [::fossilhub::view::escape [::fossilhub::i18n::phrase \
        [dict get $event outcome]]] \
      [::fossilhub::view::escape [::fossilhub::view::formatDate \
        [dict get $event epoch]]]]
  }
  append html {</ol>}
  return $html
}

proc ::fossilhub::views::renderDashboard {context data} {
  set tickets [dict get $data tickets]
  if {[llength $tickets] == 0} {
    set ticketHtml {<div class="workspace-empty"><p>No open Tickets in your repositories.</p></div>}
  } else {
    set ticketHtml {<div class="dashboard-tickets">}
    foreach ticket $tickets {
      append ticketHtml [::fossilhub::views::localizedFormat {
        <a href="#" data-hub-path="/repo/%s.fossil/ticket/%s"><span>%s</span><b>%s</b><small>%s · %s</small></a>} \
        [::fossilhub::view::escape [dict get $ticket repository_slug]] \
        [::fossilhub::view::escape [dict get $ticket uuid]] \
        [::fossilhub::view::escape [dict get $ticket repository_title]] \
        [::fossilhub::view::escape [dict get $ticket title]] \
        [::fossilhub::view::escape [dict get $ticket status]] \
        [::fossilhub::view::escape [::fossilhub::view::formatDate \
          [dict get $ticket epoch]]]]
    }
    append ticketHtml {</div>}
  }
  set content [::fossilhub::views::localizedFormat {
    <div class="workspace-actions"><div><h2>Your repositories</h2><p>Owned strata and repositories where you collaborate.</p></div><a class="btn btn-primary" href="#" data-hub-path="/repositories/new">New repository</a></div>
    <h3 class="workspace-section-title">Owned</h3>%s
    <h3 class="workspace-section-title">Collaborations</h3>%s
    <div class="section-rule"></div><h2>Open Tickets</h2><p class="section-copy">Open work across repositories you can access. FossilHub does not invent assignment fields that are absent from the repository.</p>%s
    <div class="section-rule"></div><h2>Recent activity</h2>%s} \
    [::fossilhub::views::renderWorkspaceRepositories [dict get $data owned] \
      {You do not own a repository yet.}] \
    [::fossilhub::views::renderWorkspaceRepositories \
      [dict get $data collaborations] {No collaboration invitations yet.}] \
    $ticketHtml [::fossilhub::views::renderActivity [dict get $data activity] \
      {Your activity ledger is empty.}]]
  return [::fossilhub::views::accountFrame {Dashboard} {Field workspace} \
    {Survey your work} \
    {Repositories, open work, and recent changes gathered in one place.} \
    $content $context]
}

proc ::fossilhub::views::renderPublicProfile {context profile} {
  set user [dict get $profile user]
  set facts ""
  if {[dict get $user location] ne ""} {
    append facts [::fossilhub::views::localizedFormat {<span>%s</span>} \
      [::fossilhub::view::escape [dict get $user location]]]
  }
  if {[dict get $user website] ne ""} {
    append facts [::fossilhub::views::localizedFormat {<a href="%s" rel="nofollow me">Website</a>} \
      [::fossilhub::view::escape [dict get $user website]]]
  }
  append facts [::fossilhub::views::localizedFormat {<span>Joined %s</span>} \
    [::fossilhub::view::escape [::fossilhub::view::formatDate \
      [dict get $user created_epoch]]]]
  set content [::fossilhub::views::localizedFormat {
    <div class="profile-record"><div class="profile-monogram" aria-hidden="true">%s</div><div><h2>%s</h2><code>@%s</code></div></div>
    <p class="profile-biography">%s</p><div class="profile-facts">%s</div>
    <div class="section-rule"></div><h2>Public repositories</h2>%s
    <div class="section-rule"></div><h2>Public activity</h2>%s} \
    [::fossilhub::view::escape [string toupper [string index \
      [dict get $user display_name] 0]]] \
    [::fossilhub::view::escape [dict get $user display_name]] \
    [::fossilhub::view::escape [dict get $user username]] \
    [::fossilhub::view::escape [expr {[dict get $user biography] eq "" ?
      [::fossilhub::i18n::phrase {No biography recorded.}] : \
      [dict get $user biography]}]] $facts \
    [::fossilhub::views::renderWorkspaceRepositories \
      [dict get $profile repositories] {No public repositories yet.}] \
    [::fossilhub::views::renderActivity [dict get $profile activity] \
      {No public repository activity yet.}]]
  return [::fossilhub::views::accountFrame \
    "[dict get $user display_name] · profile" {Public field record} \
    [dict get $user display_name] \
    {A public identity, repository record, and activity summary.} \
    $content $context]
}

proc ::fossilhub::views::renderSettings {context profileCsrf deactivateCsrf \
    message values} {
  set user [dict get $context user]
  set content [::fossilhub::views::localizedFormat {%s
    <div class="settings-tabs" aria-label="Settings sections"><a aria-current="page" href="#" data-hub-path="/settings">Profile</a><a href="#" data-hub-path="/settings/security">Password &amp; sessions</a></div>
    <h2>Public profile</h2>
    <form class="field-form" action="settings" method="post" data-hub-action="/settings">
      <input type="hidden" name="csrf" value="%s">
      <label>Display name<input name="display_name" autocomplete="name" maxlength="80" value="%s" required></label>
      <label>Email<input name="email" type="email" autocomplete="email" maxlength="254" value="%s" required><small>Email is private and is never shown on your public profile.</small></label>
      <label>Biography<textarea name="biography" maxlength="1000" rows="5">%s</textarea></label>
      <div class="field-pair"><label>Website<input name="website" type="url" inputmode="url" maxlength="240" placeholder="https://example.com" value="%s"></label><label>Location<input name="location" maxlength="100" value="%s"></label></div>
      <button class="btn btn-primary" type="submit">Save profile</button>
    </form>
    <div class="section-rule"></div><h2>Appearance</h2><p class="section-copy">Theme is stored only in this browser. System mode follows your device preference.</p>
    <div class="theme-settings" role="group" aria-label="Color theme"><button type="button" data-theme-choice="light">Light</button><button type="button" data-theme-choice="dark">Dark</button><button type="button" data-theme-choice="system">System</button></div>
    <div class="section-rule"></div><section class="danger-section"><h2>Deactivate account</h2><p>Signing in will be blocked and every active session will close. Repository custody remains intact for administrator review.</p>
    <form class="field-form compact-form" action="deactivate" method="post" data-hub-action="/settings/deactivate">
      <input type="hidden" name="csrf" value="%s"><label>Type <code>%s</code> to confirm<input name="confirmation" autocomplete="off" required></label><label>Current password<input name="current_password" type="password" autocomplete="current-password" required></label><button class="btn btn-danger" type="submit">Deactivate account</button>
    </form></section>
    <script>document.querySelectorAll('[data-theme-choice]').forEach(x=>x.addEventListener('click',()=>{const v=x.dataset.themeChoice;if(v==='system'){localStorage.removeItem('fh-theme');document.documentElement.dataset.theme=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'}else{document.documentElement.dataset.theme=v;localStorage.setItem('fh-theme',v)}}));</script>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $profileCsrf] \
    [::fossilhub::view::escape [dict get $values display_name]] \
    [::fossilhub::view::escape [dict get $values email]] \
    [::fossilhub::view::escape [dict get $values biography]] \
    [::fossilhub::view::escape [dict get $values website]] \
    [::fossilhub::view::escape [dict get $values location]] \
    [::fossilhub::view::escape $deactivateCsrf] \
    [::fossilhub::view::escape [dict get $user username]]]
  return [::fossilhub::views::accountFrame {Account settings} \
    {Identity · preferences} {Shape your field record} \
    {Manage the public details and local appearance attached to your account.} \
    $content $context]
}

proc ::fossilhub::views::renderLogin {context csrf {message ""} {login ""}} {
  set content [::fossilhub::views::localizedFormat {%s
    <form class="field-form" action="login" method="post" data-hub-action="/login">
      <input type="hidden" name="csrf" value="%s">
      <label>%s<input name="login" type="text" autocomplete="username" maxlength="254" value="%s" required autofocus></label>
      <label>%s<input name="password" type="password" autocomplete="current-password" maxlength="1024" required></label>
      <button class="btn btn-primary" type="submit">%s</button>
    </form>
    <p class="form-foot">%s <a href="#" data-hub-path="/register">%s</a></p>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $csrf] \
    [::fossilhub::view::escape [::fossilhub::i18n::t username_or_email]] \
    [::fossilhub::view::escape $login] \
    [::fossilhub::view::escape [::fossilhub::i18n::t password]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t sign_in]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t new_to_dig]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t create_account]]]
  return [::fossilhub::views::accountFrame \
    [::fossilhub::i18n::t sign_in] {Identity checkpoint} \
    [::fossilhub::i18n::t return_to_field] \
    [::fossilhub::i18n::t account_opens_tools] \
    $content $context]
}

proc ::fossilhub::views::renderRegister {context csrf {message ""} {values {}}} {
  set defaults [dict create username "" email "" display_name ""]
  set values [dict merge $defaults $values]
  set content [::fossilhub::views::localizedFormat {%s
    <form class="field-form" action="register" method="post" data-hub-action="/register">
      <input type="hidden" name="csrf" value="%s">
      <label>%s<input name="username" type="text" autocomplete="username" maxlength="39" pattern="[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?" value="%s" required></label>
      <label>%s<input name="display_name" type="text" autocomplete="name" maxlength="80" value="%s"></label>
      <label>%s<input name="email" type="email" autocomplete="email" maxlength="254" value="%s" required></label>
      <label>%s<input name="password" type="password" autocomplete="new-password" minlength="12" maxlength="1024" required><small>%s</small></label>
      <label>%s<input name="password_confirm" type="password" autocomplete="new-password" maxlength="1024" required></label>
      <button class="btn btn-primary" type="submit">%s</button>
    </form>
    <p class="form-foot">%s <a href="#" data-hub-path="/login">%s</a></p>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $csrf] \
    [::fossilhub::view::escape [::fossilhub::i18n::t username]] \
    [::fossilhub::view::escape [dict get $values username]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t display_name]] \
    [::fossilhub::view::escape [dict get $values display_name]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t email]] \
    [::fossilhub::view::escape [dict get $values email]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t password]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t password_help]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t confirm_password]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t create_account]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t already_registered]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t sign_in]]]
  return [::fossilhub::views::accountFrame \
    [::fossilhub::i18n::t create_account] {Open a field record} \
    [::fossilhub::i18n::t claim_survey_mark] \
    [::fossilhub::i18n::t identity_follows_work] \
    $content $context]
}

proc ::fossilhub::views::renderSecurity {context passwordCsrf sessions message} {
  set user [dict get $context user]
  set rows ""
  foreach session $sessions {
    set current [expr {[dict get $session id_hash] eq \
      [dict get $context session_hash]}]
    set label [::fossilhub::i18n::phrase \
      [expr {$current ? "Current session" : "Signed-in session"}]]
    set purpose "revoke-session:[dict get $session id_hash]"
    set challenge [::fossilhub::auth::issueChallenge \
      $purpose [dict get $context session_hash]]
    append rows [::fossilhub::views::localizedFormat {
      <div class="session-row">
        <div><b>%s</b><small>Last seen %s · expires %s · mark %s</small></div>
        <form action="revoke" method="post" data-hub-action="/settings/session/revoke">
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
      [expr {$current ? [::fossilhub::i18n::t sign_out] : \
        [::fossilhub::i18n::phrase Revoke]}]]
  }
  set content [::fossilhub::views::localizedFormat {%s
    <div class="settings-tabs" aria-label="Settings sections"><a href="#" data-hub-path="/settings">Profile</a><a aria-current="page" href="#" data-hub-path="/settings/security">Password &amp; sessions</a></div>
    <div class="account-label"><span>Signed in as</span><b>%s</b><small>%s · %s</small></div>
    <h2>Change password</h2>
    <form class="field-form compact-form" action="security" method="post" data-hub-action="/settings/security">
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
