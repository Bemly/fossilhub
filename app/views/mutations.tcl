namespace eval ::fossilhub::views {}

proc ::fossilhub::views::mutationNotice {message} {
  if {$message eq ""} {
    return ""
  }
  return [format {<p class="form-notice" role="alert">%s</p>} \
    [::fossilhub::view::escape $message]]
}

proc ::fossilhub::views::hiddenField {name value} {
  format {<input type="hidden" name="%s" value="%s">} \
    [::fossilhub::view::escape $name] [::fossilhub::view::escape $value]
}

proc ::fossilhub::views::mutationHeader {repository eyebrow title backSuffix} {
  return [format {
    <div class="section-lede mutation-lede">
      <a class="back-link" href="#" data-hub-path="/repo/%s/%s">← back to repository</a>
      <p class="eyebrow">%s</p><h2>%s</h2>
    </div>} \
    [::fossilhub::view::escape [dict get $repository name]] \
    [::fossilhub::view::escape $backSuffix] \
    [::fossilhub::view::escape $eyebrow] \
    [::fossilhub::view::escape $title]]
}

proc ::fossilhub::views::renderFileCompose {repository data} {
  set operation [dict get $data operation]
  set values [dict get $data values]
  set head [dict get $data head]
  set branch [dict get $data branch]
  set notice [::fossilhub::views::mutationNotice [dict get $data message]]
  if {$operation eq "create"} {
    set branchOptions ""
    foreach candidate [dict get $data branches] {
      set selected [expr {$candidate eq $branch ? " selected" : ""}]
      append branchOptions [format {<option value="%s"%s>%s</option>} \
        [::fossilhub::view::escape $candidate] $selected \
        [::fossilhub::view::escape $candidate]]
    }
    set heading [::fossilhub::views::mutationHeader $repository \
      {Trunk workbench} {Add a file} files]
    return [format {%s%s
      <form class="panel panel-body field-form mutation-form" action="" method="post">
        %s%s
        <label>Target branch <select name="branch">%s</select></label>
        <label>Repository path
          <input name="filename" value="%s" maxlength="512" required
            placeholder="docs/field-guide.md" autocomplete="off">
          <small>Relative to the repository root; intermediate folders are created.</small>
        </label>
        <label>File content
          <textarea name="content" rows="22" maxlength="1048576" required>%s</textarea>
        </label>
        <label>Commit message
          <input name="message" value="%s" maxlength="4096" required
            placeholder="Add field guide" autocomplete="off">
        </label>
        <button class="btn" type="submit">Commit file</button>
      </form>} \
      $heading $notice \
      [::fossilhub::views::hiddenField csrf [dict get $data csrf]] \
      [::fossilhub::views::hiddenField expected $head] \
      $branchOptions \
      [::fossilhub::view::escape [dict get $values filename]] \
      [::fossilhub::view::escape [dict get $values content]] \
      [::fossilhub::view::escape [dict get $values message]]]
  }

  set record [dict get $data file]
  set filename [dict get $record filename]
  set heading [::fossilhub::views::mutationHeader $repository \
    {Trunk workbench} "Edit $filename" "file/[dict get $record uuid]"]
  set saveForm ""
  if {[dict get $record text]} {
    set saveForm [format {
      <section class="mutation-stack">
        <h3>Edit content</h3>
        <form class="panel panel-body field-form mutation-form" action="" method="post">
          %s%s%s%s
          <label>File content
            <textarea name="content" rows="22" maxlength="1048576" required>%s</textarea>
          </label>
          <label>Commit message
            <input name="message" value="%s" maxlength="4096" required autocomplete="off">
          </label>
          <button class="btn" type="submit">Commit changes</button>
        </form>
      </section>} \
      [::fossilhub::views::hiddenField csrf [dict get $data csrf_save]] \
      [::fossilhub::views::hiddenField operation save] \
      [::fossilhub::views::hiddenField expected $head] \
      [::fossilhub::views::hiddenField branch $branch] \
      [::fossilhub::view::escape [dict get $values content]] \
      [::fossilhub::view::escape [dict get $values message]]]
  } else {
    set saveForm {
      <p class="private-transport">Binary content cannot be edited in the browser, but it can be renamed or deleted.</p>}
  }
  return [format {%s%s%s
    <section class="mutation-stack"><h3>Rename artifact</h3>
      <form class="panel panel-body field-form compact-form" action="" method="post">
        %s%s%s%s
        <label>New repository path
          <input name="next_filename" value="%s" maxlength="512" required autocomplete="off">
        </label>
        <label>Commit message
          <input name="message" value="Rename %s" maxlength="4096" required autocomplete="off">
        </label>
        <button class="btn btn-ghost" type="submit">Commit rename</button>
      </form>
    </section>
    <section class="mutation-stack danger-section"><h3>Delete artifact</h3>
      <p>The deletion is a new Fossil check-in; earlier versions remain in history.</p>
      <form class="field-form compact-form" action="" method="post">
        %s%s%s%s
        <input type="hidden" name="message" value="Delete %s">
        <button class="btn btn-danger" type="submit">Commit deletion</button>
      </form>
    </section>} \
    $heading $notice $saveForm \
    [::fossilhub::views::hiddenField csrf [dict get $data csrf_rename]] \
    [::fossilhub::views::hiddenField operation rename] \
    [::fossilhub::views::hiddenField expected $head] \
    [::fossilhub::views::hiddenField branch $branch] \
    [::fossilhub::view::escape [dict get $values next_filename]] \
    [::fossilhub::view::escape $filename] \
    [::fossilhub::views::hiddenField csrf [dict get $data csrf_delete]] \
    [::fossilhub::views::hiddenField operation delete] \
    [::fossilhub::views::hiddenField expected $head] \
    [::fossilhub::views::hiddenField branch $branch] \
    [::fossilhub::view::escape $filename]]
}

proc ::fossilhub::views::renderWikiCompose {repository data} {
  set values [dict get $data values]
  set title [dict get $values title]
  set operation [dict get $data operation]
  set label [expr {$operation eq "create" ? "Create Wiki page" : "Edit $title"}]
  set heading [::fossilhub::views::mutationHeader $repository \
    {Wiki workbench} $label wiki]
  set titleField [expr {$operation eq "create" ? [format {
    <label>Page title
      <input name="title" value="%s" maxlength="160" required autocomplete="off">
    </label>} [::fossilhub::view::escape $title]] :
    [::fossilhub::views::hiddenField title $title]}]
  set options ""
  foreach {value label} {
    markdown Markdown fossil {Fossil Wiki} plain {Plain text}
  } {
    set selected [expr {$value eq [dict get $values mimetype] ? " selected" : ""}]
    append options [format {<option value="%s"%s>%s</option>} \
      $value $selected $label]
  }
  return [format {%s%s
    <form class="panel panel-body field-form mutation-form" action="" method="post">
      %s%s%s
      %s
      <label>Markup <select name="mimetype">%s</select></label>
      <label>Page content
        <textarea name="content" rows="22" maxlength="262144" required>%s</textarea>
      </label>
      <button class="btn" type="submit">Publish Wiki revision</button>
    </form>} \
    $heading [::fossilhub::views::mutationNotice [dict get $data message]] \
    [::fossilhub::views::hiddenField csrf [dict get $data csrf]] \
    [::fossilhub::views::hiddenField expected [dict get $data expected]] \
    [::fossilhub::views::hiddenField operation $operation] \
    $titleField $options [::fossilhub::view::escape [dict get $values content]]]
}

proc ::fossilhub::views::renderTicketCompose {repository data} {
  set values [dict get $data values]
  set heading [::fossilhub::views::mutationHeader $repository \
    {Ticket cabinet} {Open a ticket} tickets]
  set options ""
  foreach {value label} {
    Code_Defect {Code defect} Feature_Request {Feature request}
    Incident Incident Task Task
  } {
    set selected [expr {$value eq [dict get $values type] ? " selected" : ""}]
    append options [format {<option value="%s"%s>%s</option>} \
      $value $selected $label]
  }
  return [format {%s%s
    <form class="panel panel-body field-form mutation-form" action="" method="post">
      %s
      <label>Title
        <input name="title" value="%s" maxlength="160" required autocomplete="off">
      </label>
      <label>Type <select name="type">%s</select></label>
      <label>Description
        <textarea name="comment" rows="12" maxlength="262144">%s</textarea>
      </label>
      <button class="btn" type="submit">Open ticket</button>
    </form>} \
    $heading [::fossilhub::views::mutationNotice [dict get $data message]] \
    [::fossilhub::views::hiddenField csrf [dict get $data csrf]] \
    [::fossilhub::view::escape [dict get $values title]] $options \
    [::fossilhub::view::escape [dict get $values comment]]]
}

proc ::fossilhub::views::renderTicketWorkbench {repository data} {
  set ticket [dict get $data ticket]
  set ticketId [dict get $ticket uuid]
  set status [dict get $ticket status]
  set nextAction [expr {[string tolower $status] in {closed fixed resolved} ? \
    "reopen" : "close"}]
  set nextLabel [string totitle $nextAction]
  set heading [::fossilhub::views::mutationHeader $repository \
    "Ticket [string range $ticketId 0 9] · $status" \
    [dict get $ticket title] tickets]
  set typeOptions ""
  foreach {value label} {
    Code_Defect {Code defect} Feature_Request {Feature request}
    Incident Incident Task Task
  } {
    set selected [expr {$value eq [dict get $ticket type] ? " selected" : ""}]
    append typeOptions [format {<option value="%s"%s>%s</option>} \
      $value $selected $label]
  }
  set fieldForm [format {
    <section class="mutation-stack"><h3>Edit Ticket fields</h3>
      <form class="panel panel-body field-form" action="" method="post">
        %s%s%s
        <label>Title
          <input name="title" value="%s" maxlength="160" required autocomplete="off">
        </label>
        <label>Type <select name="type">%s</select></label>
        <button class="btn btn-ghost" type="submit">Update Ticket</button>
      </form>
    </section>} \
    [::fossilhub::views::hiddenField csrf [dict get $data csrf_update]] \
    [::fossilhub::views::hiddenField action update] \
    [::fossilhub::views::hiddenField expected [dict get $data revision]] \
    [::fossilhub::view::escape [dict get $ticket title]] $typeOptions]
  return [format {%s%s
    <article class="panel panel-body ticket-detail">
      <p class="mono-label">%s · %s</p><p>%s</p>
    </article>
    %s
    <section class="mutation-stack"><h3>Add a comment</h3>
      <form class="panel panel-body field-form" action="" method="post">
        %s%s%s
        <textarea name="comment" rows="8" maxlength="262144" required>%s</textarea>
        <button class="btn" type="submit">Publish comment</button>
      </form>
    </section>
    <section class="mutation-stack"><h3>%s ticket</h3>
      <form class="field-form compact-form" action="" method="post">
        %s%s%s
        <label>Optional status note
          <textarea name="comment" rows="4" maxlength="262144"></textarea>
        </label>
        <button class="btn btn-ghost" type="submit">%s ticket</button>
      </form>
    </section>} \
    $heading [::fossilhub::views::mutationNotice [dict get $data message]] \
    [::fossilhub::view::escape [dict get $ticket type]] \
    [::fossilhub::view::escape [::fossilhub::view::formatDate \
      [dict get $ticket epoch]]] \
    [::fossilhub::view::escape [dict get $ticket comment]] \
    $fieldForm \
    [::fossilhub::views::hiddenField csrf [dict get $data csrf_comment]] \
    [::fossilhub::views::hiddenField action comment] \
    [::fossilhub::views::hiddenField expected [dict get $data revision]] \
    [::fossilhub::view::escape [dict get $data comment]] \
    $nextLabel \
    [::fossilhub::views::hiddenField csrf [dict get $data csrf_status]] \
    [::fossilhub::views::hiddenField action $nextAction] \
    [::fossilhub::views::hiddenField expected [dict get $data revision]] \
    $nextLabel]
}

proc ::fossilhub::views::renderForumCompose {repository data} {
  set values [dict get $data values]
  set operation [dict get $data operation]
  set isThread [expr {$operation eq "thread"}]
  set title [expr {$isThread ? "Start a discussion" : "Reply to a discussion"}]
  set heading [::fossilhub::views::mutationHeader $repository \
    {Forum borehole} $title forum]
  set titleField ""
  if {$isThread} {
    set titleField [format {
      <label>Discussion title
        <input name="title" value="%s" maxlength="125" required autocomplete="off">
      </label>} [::fossilhub::view::escape [dict get $values title]]]
  }
  set options ""
  foreach {value label} {
    markdown Markdown fossil {Fossil Wiki} plain {Plain text}
  } {
    set selected [expr {$value eq [dict get $values mimetype] ? " selected" : ""}]
    append options [format {<option value="%s"%s>%s</option>} \
      $value $selected $label]
  }
  return [format {%s%s
    <form class="panel panel-body field-form mutation-form" action="" method="post">
      %s%s%s
      %s
      <label>Post
        <textarea name="content" rows="14" maxlength="262144" required>%s</textarea>
      </label>
      <label>Markup
        <select name="mimetype">%s</select>
      </label>
      <button class="btn" type="submit">Publish %s</button>
    </form>} \
    $heading [::fossilhub::views::mutationNotice [dict get $data message]] \
    [::fossilhub::views::hiddenField csrf [dict get $data csrf]] \
    [::fossilhub::views::hiddenField operation $operation] \
    [::fossilhub::views::hiddenField parent [dict get $data parent]] \
    $titleField [::fossilhub::view::escape [dict get $values content]] $options \
    [expr {$isThread ? "discussion" : "reply"}]]
}

proc ::fossilhub::views::renderMutationSection {repository section data} {
  switch -- $section {
    file-compose { return [::fossilhub::views::renderFileCompose $repository $data] }
    wiki-compose { return [::fossilhub::views::renderWikiCompose $repository $data] }
    ticket-compose { return [::fossilhub::views::renderTicketCompose $repository $data] }
    ticket-workbench { return [::fossilhub::views::renderTicketWorkbench $repository $data] }
    forum-compose { return [::fossilhub::views::renderForumCompose $repository $data] }
  }
  error "unknown mutation section"
}
