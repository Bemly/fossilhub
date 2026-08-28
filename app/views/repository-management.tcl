namespace eval ::fossilhub::views {}

proc ::fossilhub::views::repositoryStateChip {repository} {
  set visibility [dict get $repository visibility]
  set state [dict get $repository state]
  return [format {
    <span class="repo-state repo-state-%s">%s</span>
    <span class="repo-state repo-state-%s">%s</span>} \
    [::fossilhub::view::escape $visibility] \
    [::fossilhub::view::escape $visibility] \
    [::fossilhub::view::escape $state] \
    [::fossilhub::view::escape $state]]
}

proc ::fossilhub::views::renderRepositoryWorkspace {context repositories} {
  set rows ""
  foreach repository $repositories {
    set role [::fossilhub::repositories::effectiveRole $repository $context]
    append rows [format {
      <article class="workspace-repository">
        <div>
          <div class="workspace-repo-title"><a href="../../repo/%s" data-hub-path="/repo/%s">%s</a>%s</div>
          <p>%s</p>
          <small>%s · default branch %s</small>
        </div>
        <a class="btn btn-ghost btn-compact" href="%s/settings" data-hub-path="/account/repositories/%s/settings">Manage</a>
      </article>} \
      [::fossilhub::view::escape [dict get $repository name]] \
      [::fossilhub::view::escape [dict get $repository name]] \
      [::fossilhub::view::escape [dict get $repository title]] \
      [::fossilhub::views::repositoryStateChip $repository] \
      [::fossilhub::view::escape [dict get $repository description]] \
      [::fossilhub::view::escape $role] \
      [::fossilhub::view::escape [dict get $repository default_branch]] \
      [::fossilhub::view::escape [dict get $repository slug]] \
      [::fossilhub::view::escape [dict get $repository slug]]]
  }
  if {$rows eq ""} {
    set rows {<div class="workspace-empty"><b>No repositories yet</b><p>Create a repository or ask an owner to add you as a collaborator.</p></div>}
  }
  set content [format {
    <div class="workspace-actions"><div><h2>Your repositories</h2><p>Owned strata and collaborations in one field ledger.</p></div><a class="btn btn-primary" href="repositories/new" data-hub-path="/account/repositories/new">New repository</a></div>
    <div class="workspace-list">%s</div>} $rows]
  return [::fossilhub::views::accountFrame {Repository workspace} \
    {Workspace · repositories} {Your working strata} \
    {Create, inspect, and manage the repositories entrusted to your account.} \
    $content $context]
}

proc ::fossilhub::views::renderRepositoryNew {context csrf message values} {
  set values [dict merge [dict create slug "" title "" description "" \
    visibility public] $values]
  set content [format {%s
    <h2>Create repository</h2>
    <form class="field-form" action="new" method="post" data-hub-action="/account/repositories/new">
      <input type="hidden" name="csrf" value="%s">
      <label>Repository name<input name="slug" type="text" maxlength="39" pattern="[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?" value="%s" required autofocus><small>Lowercase letters, numbers, and single hyphens. The URL cannot be renamed in this milestone.</small></label>
      <label>Display title<input name="title" type="text" maxlength="100" value="%s" required></label>
      <label>Description<textarea name="description" maxlength="500" rows="4">%s</textarea></label>
      <label>Visibility<select name="visibility"><option value="public"%s>Public — visible and cloneable by everyone</option><option value="private"%s>Private — members only</option></select></label>
      <button class="btn btn-primary" type="submit">Create repository</button>
    </form>} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape $csrf] \
    [::fossilhub::view::escape [dict get $values slug]] \
    [::fossilhub::view::escape [dict get $values title]] \
    [::fossilhub::view::escape [dict get $values description]] \
    [expr {[dict get $values visibility] eq "public" ? " selected" : ""}] \
    [expr {[dict get $values visibility] eq "private" ? " selected" : ""}]]
  return [::fossilhub::views::accountFrame {New repository} \
    {Workspace · deposition} {Open a new stratum} \
    {FossilHub initializes an isolated Fossil repository and records you as its owner.} \
    $content $context]
}

proc ::fossilhub::views::permissionStrata {members} {
  set layers ""
  set widths [dict create owner 100 maintainer 86 writer 70 triage 54 reader 40]
  foreach member $members {
    set role [dict get $member role]
    append layers [format {
      <div class="permission-layer permission-%s" style="--layer-width:%s%%"><b>%s</b><span>@%s</span><small>%s</small></div>} \
      [::fossilhub::view::escape $role] [dict get $widths $role] \
      [::fossilhub::view::escape [dict get $member display_name]] \
      [::fossilhub::view::escape [dict get $member username]] \
      [::fossilhub::view::escape $role]]
  }
  return [format {<div class="permission-strata" aria-label="Repository permission layers">%s</div>} $layers]
}

proc ::fossilhub::views::renderRepositorySettings {context repository members \
    challenges message values} {
  set values [dict merge [dict create \
    title [dict get $repository title] \
    description [dict get $repository description] \
    visibility [dict get $repository visibility] \
    default_branch [dict get $repository default_branch]] $values]
  set canManage [expr {
    [dict get $repository state] eq "active" &&
    [::fossilhub::repositories::allows $repository $context manage]
  }]
  set canOwn [::fossilhub::repositories::allows $repository $context owner]
  set memberRows ""
  foreach member $members {
    set remove ""
    if {$canManage && [dict get $member role] ne "owner"} {
      set removeToken [dict get $challenges "remove:[dict get $member id]"]
      set remove [format {
        <form method="post" action="member-remove" data-hub-action="/account/repositories/%s/member-remove">
          <input type="hidden" name="csrf" value="%s"><input type="hidden" name="user" value="%s">
          <button class="btn btn-ghost btn-compact" type="submit">Remove</button>
        </form>} \
        [::fossilhub::view::escape [dict get $repository slug]] \
        [::fossilhub::view::escape $removeToken] \
        [::fossilhub::view::escape [dict get $member id]]]
    }
    append memberRows [format {
      <div class="member-ledger-row"><div><b>%s</b><span>@%s</span></div><code>%s</code>%s</div>} \
      [::fossilhub::view::escape [dict get $member display_name]] \
      [::fossilhub::view::escape [dict get $member username]] \
      [::fossilhub::view::escape [dict get $member role]] $remove]
  }
  set manageForms ""
  if {$canManage && [dict get $repository state] eq "active"} {
    set manageForms [format {
      <section class="settings-section"><h2>Repository record</h2>
        <form class="field-form compact-form" method="post" action="settings" data-hub-action="/account/repositories/%s/settings">
          <input type="hidden" name="csrf" value="%s">
          <label>Display title<input name="title" maxlength="100" value="%s" required></label>
          <label>Description<textarea name="description" maxlength="500" rows="3">%s</textarea></label>
          <div class="field-pair"><label>Visibility<select name="visibility"><option value="public"%s>Public</option><option value="private"%s>Private</option></select></label><label>Default branch<input name="default_branch" maxlength="100" value="%s" required></label></div>
          <button class="btn btn-primary" type="submit">Save repository</button>
        </form>
      </section>
      <section class="settings-section"><h2>Collaborators</h2>%s<div class="member-ledger">%s</div>
        <form class="field-form member-form" method="post" action="member" data-hub-action="/account/repositories/%s/member">
          <input type="hidden" name="csrf" value="%s">
          <label>Username<input name="username" maxlength="39" required></label>
          <label>Role<select name="role"><option value="reader">Reader</option><option value="triage">Triage</option><option value="writer">Writer</option><option value="maintainer">Maintainer</option></select></label>
          <button class="btn btn-ghost" type="submit">Add or update</button>
        </form>
      </section>} \
      [::fossilhub::view::escape [dict get $repository slug]] \
      [::fossilhub::view::escape [dict get $challenges settings]] \
      [::fossilhub::view::escape [dict get $values title]] \
      [::fossilhub::view::escape [dict get $values description]] \
      [expr {[dict get $values visibility] eq "public" ? " selected" : ""}] \
      [expr {[dict get $values visibility] eq "private" ? " selected" : ""}] \
      [::fossilhub::view::escape [dict get $values default_branch]] \
      [::fossilhub::views::permissionStrata $members] $memberRows \
      [::fossilhub::view::escape [dict get $repository slug]] \
      [::fossilhub::view::escape [dict get $challenges member]]]
  } else {
    set manageForms [format {
      <section class="settings-section"><h2>Collaborators</h2>%s<div class="member-ledger">%s</div></section>} \
      [::fossilhub::views::permissionStrata $members] $memberRows]
  }

  set ownerForms ""
  if {$canOwn} {
    if {[dict get $repository state] eq "active"} {
      set ownerForms [format {
        <section class="settings-section danger-section"><h2>Owner controls</h2><p>These operations require a recently authenticated session and the exact repository name.</p>
          <form class="field-form compact-form" method="post" action="transfer" data-hub-action="/account/repositories/%s/transfer">
            <input type="hidden" name="csrf" value="%s"><label>Transfer to username<input name="username" maxlength="39" required></label><label>Type <code>%s</code> to confirm<input name="confirm" autocomplete="off" required></label><button class="btn btn-ghost" type="submit">Transfer ownership</button>
          </form><div class="section-rule"></div>
          <form class="field-form compact-form" method="post" action="archive" data-hub-action="/account/repositories/%s/archive">
            <input type="hidden" name="csrf" value="%s"><label>Type <code>%s</code> to archive<input name="confirm" autocomplete="off" required></label><button class="btn btn-danger" type="submit">Archive repository</button>
          </form>
        </section>} \
        [::fossilhub::view::escape [dict get $repository slug]] \
        [::fossilhub::view::escape [dict get $challenges transfer]] \
        [::fossilhub::view::escape [dict get $repository slug]] \
        [::fossilhub::view::escape [dict get $repository slug]] \
        [::fossilhub::view::escape [dict get $challenges archive]] \
        [::fossilhub::view::escape [dict get $repository slug]]]
    } else {
      set ownerForms [format {
        <section class="settings-section danger-section"><h2>Archived repository</h2><p>The repository file is in quarantine and is not readable or cloneable.</p>
          <form class="field-form compact-form" method="post" action="restore" data-hub-action="/account/repositories/%s/restore"><input type="hidden" name="csrf" value="%s"><label>Type <code>%s</code> to restore<input name="confirm" autocomplete="off" required></label><button class="btn btn-primary" type="submit">Restore repository</button></form>
        </section>} \
        [::fossilhub::view::escape [dict get $repository slug]] \
        [::fossilhub::view::escape [dict get $challenges restore]] \
        [::fossilhub::view::escape [dict get $repository slug]]]
    }
  }
  set content [format {%s
    <div class="repository-heading"><div><span class="mono-label">%s.fossil</span><h2>%s</h2></div>%s</div>
    %s%s} \
    [::fossilhub::views::accountNotice $message] \
    [::fossilhub::view::escape [dict get $repository slug]] \
    [::fossilhub::view::escape [dict get $repository title]] \
    [::fossilhub::views::repositoryStateChip $repository] \
    $manageForms $ownerForms]
  return [::fossilhub::views::accountFrame {Repository settings} \
    {Workspace · custody} {Manage this stratum} \
    {Visibility, collaborators, ownership, and archive state are enforced centrally.} \
    $content $context]
}
