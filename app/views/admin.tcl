namespace eval ::fossilhub::views {}

proc ::fossilhub::views::adminFrame {title heading lede content context \
    {active overview}} {
  set links ""
  foreach {key label path} {
    overview Overview /admin
    users Users /admin/users
    repositories Repositories /admin/repositories
    audit Audit /admin/audit
    health Health /admin/health
    settings Settings /admin/settings
  } {
    set current [expr {$key eq $active ? { aria-current="page"} : ""}]
    append links [format {<a%s href="#" data-hub-path="%s">%s</a>} \
      $current $path $label]
  }
  set body [format {<nav class="admin-tabs" aria-label="Administration">%s</nav>%s} \
    $links $content]
  return [::fossilhub::views::accountFrame $title {Platform custody} \
    $heading $lede $body $context]
}

proc ::fossilhub::views::adminState {value} {
  set class [expr {$value in {active success ok open public} ? "good" :
    ($value in {failure quarantined disabled deactivated missing closed} ?
      "bad" : "warn")}]
  return [format {<span class="admin-state admin-state-%s">%s</span>} \
    $class [::fossilhub::view::escape $value]]
}

proc ::fossilhub::views::renderAdminOverview {context overview activity} {
  set cards ""
  foreach {label key note} {
    Users users {registered identities}
    Active active_users {able to sign in}
    Repositories repositories {registry records}
    {Active repositories} active_repositories {published strata}
    {Activity · 24h} activity_24h {audited events}
    {Failures · 24h} failures_24h {review required}
  } {
    append cards [format {<article><span>%s</span><b>%s</b><small>%s</small></article>} \
      $label [::fossilhub::view::escape [::fossilhub::view::formatCount \
        [dict get $overview $key]]] $note]
  }
  set content [format {
    <div class="admin-heading"><div><h2>Operational overview</h2><p>Safe platform totals without credentials, paths, or private content.</p></div><a class="btn btn-ghost" href="#" data-hub-path="/admin/health">Inspect health</a></div>
    <div class="admin-metrics">%s</div>
    <div class="admin-facts"><span>Storage <b>%s</b></span><span>Readable <b>%s / %s</b></span><span>Inactive records <b>%s</b></span></div>
    <div class="section-rule"></div><h2>Recent audit activity</h2>%s} \
    $cards [::fossilhub::view::escape [::fossilhub::view::formatBytes \
      [dict get $overview storage_bytes]]] \
    [::fossilhub::view::escape [dict get $overview readable_repositories]] \
    [::fossilhub::view::escape [dict get $overview active_repositories]] \
    [::fossilhub::view::escape [dict get $overview inactive_repositories]] \
    [::fossilhub::views::renderAdminAuditRows $activity]]
  return [::fossilhub::views::adminFrame {Administrator overview} \
    {Hold the whole survey} \
    {Platform counts, custody signals, and recent audited change.} \
    $content $context overview]
}

proc ::fossilhub::views::renderAdminUsers {context users options {message ""}} {
  set rows ""
  foreach user $users {
    append rows [format {
      <tr><td><a href="#" data-hub-path="/admin/users/%s"><b>%s</b><small>@%s</small></a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>} \
      [::fossilhub::view::escape [dict get $user id]] \
      [::fossilhub::view::escape [dict get $user display_name]] \
      [::fossilhub::view::escape [dict get $user username]] \
      [::fossilhub::views::adminState [dict get $user role]] \
      [::fossilhub::views::adminState [dict get $user status]] \
      [::fossilhub::view::escape [dict get $user repository_count]] \
      [::fossilhub::view::escape [::fossilhub::view::formatDate \
        [dict get $user last_login_epoch]]]]
  }
  if {$rows eq ""} {
    set rows {<tr><td colspan="5">No users match these filters.</td></tr>}
  }
  set content [format {%s
    <div class="admin-heading"><div><h2>User custody</h2><p>Search identities, review status, and open a controlled record.</p></div></div>
    <form class="admin-filter" action="users" method="get" data-hub-action="/admin/users">
      <label>Search<input name="q" maxlength="120" value="%s"></label>
      <label>Status<select name="status">%s</select></label>
      <label>Role<select name="role">%s</select></label><button class="btn btn-ghost" type="submit">Filter</button>
    </form><div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>User</th><th>Role</th><th>Status</th><th>Repos</th><th>Last sign-in</th></tr></thead><tbody>%s</tbody></table></div>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape [dict get $options q]] \
    [::fossilhub::views::selectOptions {all active disabled deactivated} \
      [dict get $options status]] \
    [::fossilhub::views::selectOptions {all user administrator} \
      [dict get $options role]] $rows]
  return [::fossilhub::views::adminFrame {Administrator users} \
    {Inspect identities} {Every account action is attributable and reversible.} \
    $content $context users]
}

proc ::fossilhub::views::selectOptions {values selected} {
  set html ""
  foreach value $values {
    append html [format {<option value="%s"%s>%s</option>} \
      [::fossilhub::view::escape $value] \
      [expr {$value eq $selected ? " selected" : ""}] \
      [::fossilhub::view::escape [string totitle $value]]]
  }
  return $html
}

proc ::fossilhub::views::renderAdminUser {context user challenges {message ""}} {
  set repositories [dict get $user repositories]
  set repositoryRows ""
  foreach repository $repositories {
    append repositoryRows [format {<li><a href="#" data-hub-path="/admin/repositories/%s">%s</a><span>%s · %s</span></li>} \
      [::fossilhub::view::escape [dict get $repository slug]] \
      [::fossilhub::view::escape [dict get $repository title]] \
      [::fossilhub::view::escape [dict get $repository visibility]] \
      [::fossilhub::view::escape [dict get $repository state]]]
  }
  if {$repositoryRows eq ""} {
    set repositoryRows {<li>No repository relationships.</li>}
  }
  set nextStatus [expr {[dict get $user status] eq "active" ? "disabled" : "active"}]
  set statusLabel [expr {$nextStatus eq "active" ? "Restore access" : "Disable access"}]
  set id [dict get $user id]
  set content [format {%s
    <a class="back-link" href="#" data-hub-path="/admin/users">← users</a>
    <div class="admin-record"><div><h2>%s</h2><code>@%s</code></div><div>%s %s</div></div>
    <dl class="admin-definition"><div><dt>Email</dt><dd>%s</dd></div><div><dt>Joined</dt><dd>%s</dd></div><div><dt>Last sign-in</dt><dd>%s</dd></div><div><dt>Sessions</dt><dd>%s</dd></div></dl>
    <div class="section-rule"></div><h2>Repository relationships</h2><ul class="admin-repository-list">%s</ul>
    <div class="section-rule"></div><h2>Controlled actions</h2><p class="section-copy">These actions require a password check from the last ten minutes and produce an audit event.</p>
    <div class="admin-actions">
      <form class="field-form compact-form" action="%s/role" method="post" data-hub-action="/admin/users/%s/role"><input type="hidden" name="csrf" value="%s"><label>Platform role<select name="role">%s</select></label><button class="btn btn-ghost" type="submit">Change role</button></form>
      <form class="field-form compact-form" action="%s/status" method="post" data-hub-action="/admin/users/%s/status"><input type="hidden" name="csrf" value="%s"><input type="hidden" name="status" value="%s"><button class="btn %s" type="submit">%s</button></form>
      <form class="field-form compact-form" action="%s/sessions" method="post" data-hub-action="/admin/users/%s/sessions"><input type="hidden" name="csrf" value="%s"><button class="btn btn-ghost" type="submit">Revoke all sessions</button></form>
    </div><div class="section-rule"></div><h2>Recent activity</h2>%s} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape [dict get $user display_name]] \
    [::fossilhub::view::escape [dict get $user username]] \
    [::fossilhub::views::adminState [dict get $user role]] \
    [::fossilhub::views::adminState [dict get $user status]] \
    [::fossilhub::view::escape [dict get $user email]] \
    [::fossilhub::view::escape [::fossilhub::view::formatDate [dict get $user created_epoch]]] \
    [::fossilhub::view::escape [::fossilhub::view::formatDate [dict get $user last_login_epoch]]] \
    [llength [dict get $user sessions]] $repositoryRows $id $id \
    [::fossilhub::view::escape [dict get $challenges role]] \
    [::fossilhub::views::selectOptions {user administrator} [dict get $user role]] \
    $id $id [::fossilhub::view::escape [dict get $challenges status]] \
    $nextStatus [expr {$nextStatus eq "active" ? "btn-primary" : "btn-danger"}] \
    $statusLabel $id $id \
    [::fossilhub::view::escape [dict get $challenges sessions]] \
    [::fossilhub::views::renderActivity [dict get $user activity] \
      {No recorded activity.}]]
  return [::fossilhub::views::adminFrame {Administrator user record} \
    [dict get $user display_name] \
    {Review access, repository relationships, and active sessions.} \
    $content $context users]
}

proc ::fossilhub::views::renderAdminRepositories {context repositories options \
    {message ""}} {
  set rows ""
  foreach repository $repositories {
    set owner [expr {[dict get $repository owner_username] eq "" ?
      "Unassigned" : "@[dict get $repository owner_username]"}]
    append rows [format {
      <tr><td><a href="#" data-hub-path="/admin/repositories/%s"><b>%s</b><small>%s</small></a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>} \
      [::fossilhub::view::escape [dict get $repository slug]] \
      [::fossilhub::view::escape [dict get $repository title]] \
      [::fossilhub::view::escape [dict get $repository name]] \
      [::fossilhub::view::escape $owner] \
      [::fossilhub::views::adminState [dict get $repository visibility]] \
      [::fossilhub::views::adminState [dict get $repository state]] \
      [::fossilhub::view::escape [::fossilhub::view::formatDate \
        [dict get $repository updated_epoch]]]]
  }
  if {$rows eq ""} {
    set rows {<tr><td colspan="5">No repositories match these filters.</td></tr>}
  }
  set content [format {%s<h2>Repository custody</h2>
    <form class="admin-filter" action="repositories" method="get" data-hub-action="/admin/repositories"><label>Search<input name="q" maxlength="120" value="%s"></label><label>State<select name="state">%s</select></label><label>Visibility<select name="visibility">%s</select></label><button class="btn btn-ghost" type="submit">Filter</button></form>
    <div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>Repository</th><th>Owner</th><th>Visibility</th><th>State</th><th>Updated</th></tr></thead><tbody>%s</tbody></table></div>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape [dict get $options q]] \
    [::fossilhub::views::selectOptions {all active archived quarantined} [dict get $options state]] \
    [::fossilhub::views::selectOptions {all public private} [dict get $options visibility]] $rows]
  return [::fossilhub::views::adminFrame {Administrator repositories} \
    {Repository custody} {Inspect every registered stratum without exposing its contents.} \
    $content $context repositories]
}

proc ::fossilhub::views::renderAdminRepository {context repository challenges \
    {message ""}} {
  set state [dict get $repository state]
  set action ""
  if {$state eq "active"} {
    set action [format {
      <form action="%s/integrity" method="post" data-hub-action="/admin/repositories/%s/integrity"><input type="hidden" name="csrf" value="%s"><button class="btn btn-ghost" type="submit">Run integrity check</button></form>
      <form action="%s/archive" method="post" data-hub-action="/admin/repositories/%s/archive"><input type="hidden" name="csrf" value="%s"><button class="btn btn-danger" type="submit">Archive repository</button></form>} \
      [dict get $repository slug] [dict get $repository slug] \
      [::fossilhub::view::escape [dict get $challenges integrity]] \
      [dict get $repository slug] [dict get $repository slug] \
      [::fossilhub::view::escape [dict get $challenges archive]]]
  } elseif {$state eq "archived"} {
    set action [format {<form action="%s/restore" method="post" data-hub-action="/admin/repositories/%s/restore"><input type="hidden" name="csrf" value="%s"><button class="btn btn-primary" type="submit">Restore repository</button></form>} \
      [dict get $repository slug] [dict get $repository slug] \
      [::fossilhub::view::escape [dict get $challenges restore]]]
  } else {
    set action {<p class="form-notice">This repository is quarantined. Browser restore is deliberately blocked pending trusted recovery.</p>}
  }
  set owner [expr {[dict get $repository owner_username] eq "" ?
    "Unassigned" : "@[dict get $repository owner_username]"}]
  set content [format {%s<a class="back-link" href="#" data-hub-path="/admin/repositories">← repositories</a>
    <div class="admin-record"><div><h2>%s</h2><code>%s</code></div><div>%s %s</div></div>
    <dl class="admin-definition"><div><dt>Owner</dt><dd>%s</dd></div><div><dt>Default branch</dt><dd>%s</dd></div><div><dt>Created</dt><dd>%s</dd></div><div><dt>Updated</dt><dd>%s</dd></div></dl>
    <p class="profile-biography">%s</p><div class="section-rule"></div><h2>Controlled actions</h2><p class="section-copy">Integrity failure moves the file out of publication and marks the registry record quarantined.</p><div class="admin-actions">%s</div>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape [dict get $repository title]] \
    [::fossilhub::view::escape [dict get $repository name]] \
    [::fossilhub::views::adminState [dict get $repository visibility]] \
    [::fossilhub::views::adminState $state] \
    [::fossilhub::view::escape $owner] \
    [::fossilhub::view::escape [dict get $repository default_branch]] \
    [::fossilhub::view::escape [::fossilhub::view::formatDate [dict get $repository created_epoch]]] \
    [::fossilhub::view::escape [::fossilhub::view::formatDate [dict get $repository updated_epoch]]] \
    [::fossilhub::view::escape [dict get $repository description]] $action]
  return [::fossilhub::views::adminFrame {Administrator repository record} \
    [dict get $repository title] \
    {Visibility, ownership, lifecycle, and integrity controls.} \
    $content $context repositories]
}

proc ::fossilhub::views::renderAdminAuditRows {events} {
  if {[llength $events] == 0} {
    return {<div class="workspace-empty"><p>No audit events match.</p></div>}
  }
  set rows ""
  foreach event $events {
    append rows [format {<tr><td>%s</td><td><b>%s</b><small>%s</small></td><td>%s</td><td>%s</td><td>%s</td></tr>} \
      [::fossilhub::view::escape [::fossilhub::view::formatDate [dict get $event epoch]]] \
      [::fossilhub::view::escape [dict get $event action]] \
      [::fossilhub::view::escape [string range [dict get $event id] 0 11]] \
      [::fossilhub::view::escape [expr {[dict get $event actor] eq "" ? "system" : "@[dict get $event actor]"}]] \
      [::fossilhub::view::escape [expr {[dict get $event repository_slug] eq "" ? "—" : [dict get $event repository_slug]}]] \
      [::fossilhub::views::adminState [dict get $event outcome]]]
  }
  return [format {<div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>Date</th><th>Action / mark</th><th>Actor</th><th>Repository</th><th>Outcome</th></tr></thead><tbody>%s</tbody></table></div>} $rows]
}

proc ::fossilhub::views::renderAdminAudit {context events options} {
  set exportQuery [format {q=%s&amp;outcome=%s&amp;action=%s} \
    [::fossilhub::view::queryEncode [dict get $options q]] \
    [::fossilhub::view::queryEncode [dict get $options outcome]] \
    [::fossilhub::view::queryEncode [dict get $options action]]]
  set content [format {<div class="admin-heading"><div><h2>Audit ledger</h2><p>Submitted content, session material, request identifiers, and internal detail are excluded.</p></div><a class="btn btn-ghost" href="audit.csv?%s" data-hub-path="/admin/audit.csv?%s">Export CSV</a></div>
    <form class="admin-filter" action="audit" method="get" data-hub-action="/admin/audit"><label>Search<input name="q" maxlength="120" value="%s"></label><label>Outcome<select name="outcome">%s</select></label><label>Exact action<input name="action" maxlength="100" value="%s"></label><button class="btn btn-ghost" type="submit">Filter</button></form>%s} \
    $exportQuery $exportQuery [::fossilhub::view::escape [dict get $options q]] \
    [::fossilhub::views::selectOptions {all success denied failure} [dict get $options outcome]] \
    [::fossilhub::view::escape [dict get $options action]] \
    [::fossilhub::views::renderAdminAuditRows $events]]
  return [::fossilhub::views::adminFrame {Administrator audit} \
    {Audit ledger} {Search and export a deliberately redacted operational record.} \
    $content $context audit]
}

proc ::fossilhub::views::renderAdminHealth {context health csrf {message ""}} {
  set content [format {%s<div class="admin-heading"><div><h2>Application health</h2><p>Safe checks only; paths, private names, logs, and credentials are omitted.</p></div><form action="health/reindex" method="post" data-hub-action="/admin/health/reindex"><input type="hidden" name="csrf" value="%s"><button class="btn btn-ghost" type="submit">Rebuild catalogue</button></form></div>
    <div class="health-grid"><article><span>Platform database</span>%s</article><article><span>Catalogue database</span>%s</article><article><span>Repository readability</span><b>%s / %s</b></article><article><span>Protected file modes</span>%s</article><article><span>Runtime ownership</span>%s</article><article><span>Storage budget</span><b>%s / %s · %s</b></article><article><span>Catalogue indexed</span><b>%s</b></article><article><span>Application revision</span><b>%s</b></article></div>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $csrf] \
    [::fossilhub::views::adminState [dict get $health platform_database]] \
    [::fossilhub::views::adminState [dict get $health catalogue_database]] \
    [::fossilhub::view::escape [dict get $health readable_repositories]] \
    [::fossilhub::view::escape [dict get $health repository_count]] \
    [::fossilhub::views::adminState [expr {[dict get $health file_modes_ok] ? "ok" : "failure"}]] \
    [::fossilhub::views::adminState [expr {[dict get $health file_ownership_ok] ? "ok" : "warning"}]] \
    [::fossilhub::view::escape [::fossilhub::view::formatBytes [dict get $health storage_bytes]]] \
    [::fossilhub::view::escape [::fossilhub::view::formatBytes [dict get $health storage_capacity_bytes]]] \
    [::fossilhub::view::escape [dict get $health storage_status]] \
    [::fossilhub::view::escape [::fossilhub::view::formatDate [dict get $health catalogue_indexed_epoch]]] \
    [::fossilhub::view::escape [dict get $health revision]]]
  return [::fossilhub::views::adminFrame {Administrator health} \
    {Platform health} {Integrity, freshness, readability, modes, and release identity.} \
    $content $context health]
}

proc ::fossilhub::views::renderAdminSettings {context settings csrf {message ""}} {
  set content [format {%s<h2>Platform policy</h2><p class="section-copy">Only non-secret application policy is editable here.</p>
    <form class="field-form" action="settings" method="post" data-hub-action="/admin/settings"><input type="hidden" name="csrf" value="%s"><div class="field-pair"><label>Registration<select name="registration">%s</select></label><label>Default repository visibility<select name="default_visibility">%s</select></label></div><div class="field-pair"><label>Repositories per user<input name="repositories_per_user" type="number" min="1" max="10000" value="%s" required></label><label>Repository quota · MiB<input name="repository_quota_mb" type="number" min="16" max="1048576" value="%s" required></label></div><label>Maintenance banner<textarea name="maintenance_banner" maxlength="240" rows="3">%s</textarea><small>Public text only. Never enter credentials or operational logs.</small></label><button class="btn btn-primary" type="submit">Save platform policy</button></form>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $csrf] \
    [::fossilhub::views::selectOptions {open closed} [dict get $settings registration]] \
    [::fossilhub::views::selectOptions {public private} [dict get $settings default_visibility]] \
    [::fossilhub::view::escape [dict get $settings repositories_per_user]] \
    [::fossilhub::view::escape [dict get $settings repository_quota_mb]] \
    [::fossilhub::view::escape [dict get $settings maintenance_banner]]]
  return [::fossilhub::views::adminFrame {Administrator settings} \
    {Platform policy} {Registration, defaults, limits, and public maintenance notice.} \
    $content $context settings]
}

proc ::fossilhub::views::renderAdminReauth {context csrf returnTo {message ""}} {
  set content [format {%s<h2>Confirm your password</h2><p class="section-copy">High-risk administrator actions require a fresh identity check.</p><form class="field-form" action="reauth" method="post" data-hub-action="/admin/reauth"><input type="hidden" name="csrf" value="%s"><input type="hidden" name="return_to" value="%s"><label>Current password<input name="password" type="password" autocomplete="current-password" required autofocus></label><button class="btn btn-primary" type="submit">Confirm identity</button></form>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $csrf] [::fossilhub::view::escape $returnTo]]
  return [::fossilhub::views::adminFrame {Administrator verification} \
    {Confirm administrator custody} \
    {Your password is verified locally and is never retained in the audit ledger.} \
    $content $context overview]
}
