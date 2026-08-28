namespace eval ::fossilhub::views {}

proc ::fossilhub::views::repositoryPath {repository suffix} {
  set base "/repo/[dict get $repository name]"
  if {$suffix eq ""} {
    return $base
  }
  return "$base/$suffix"
}

proc ::fossilhub::views::emptySection {title message} {
  return [format {
    <div class="section-lede">
      <p class="eyebrow">%s</p>
    </div>
    <div class="panel"><div class="panel-body empty-stratum">%s</div></div>} \
    [::fossilhub::view::escape $title] \
    [::fossilhub::view::escape $message]]
}

proc ::fossilhub::views::repositoryAction {repository suffix label} {
  return [format {
    <a class="btn btn-sm" href="#" data-hub-path="%s">%s</a>} \
    [::fossilhub::views::repositoryPath $repository $suffix] \
    [::fossilhub::view::escape $label]]
}

proc ::fossilhub::views::renderTimelineSection {repository data} {
  set filter [dict get $data event_filter]
  set filters [list \
    [list all {All events}] \
    [list ci Check-ins] \
    [list w Wiki] \
    [list t Tickets] \
    [list f Forum]]
  set buttons ""
  foreach item $filters {
    lassign $item value label
    set class fchip
    if {$value eq $filter} {
      append class { sel}
    }
    set path [::fossilhub::views::repositoryPath $repository timeline]
    if {$value ne "all"} {
      append path "?event=$value"
    }
    append buttons [format {
      <a class="%s" href="#" data-hub-path="%s">%s</a>} \
      $class $path $label]
  }
  set filteredRepository [dict get $data repository]
  return [format {
    <div class="filters">%s
      <div class="tl-legend" aria-hidden="true">
        <span><i class="dot dot-azu"></i>check-in</span>
        <span><i class="dot dot-verdi"></i>wiki</span>
        <span><i class="dot dot-iron"></i>ticket</span>
        <span><i class="dot dot-hollow"></i>forum</span>
      </div>
    </div>
    <div class="panel rv-panel">%s</div>} \
    $buttons [::fossilhub::view::repositoryTimeline $filteredRepository]]
}

proc ::fossilhub::views::renderFileRows {repository files emptyMessage} {
  if {[llength $files] == 0} {
    return [::fossilhub::views::emptySection {Trunk survey} $emptyMessage]
  }
  set html {<div class="panel artifact-list">}
  foreach record $files {
    set filename [dict get $record filename]
    set path [::fossilhub::views::repositoryPath $repository \
      "file/[dict get $record uuid]"]
    set directory [file dirname $filename]
    if {$directory eq "."} {
      set directory {root stratum}
    }
    append html [format {
      <a class="artifact-row" href="#" data-hub-path="%s">
        <span class="artifact-mark">%s</span>
        <span class="artifact-main"><b>%s</b><small>%s</small></span>
        <span class="artifact-size">%s</span>
        <span class="artifact-hash">%s</span>
      </a>} \
      $path \
      [::fossilhub::view::escape [string trimleft [dict get $record extension] .]] \
      [::fossilhub::view::escape $filename] \
      [::fossilhub::view::escape $directory] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatBytes [dict get $record size]]] \
      [::fossilhub::view::escape [string range [dict get $record uuid] 0 9]]]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::views::renderFilesSection {repository data docsOnly} {
  set files [dict get $data files]
  if {$docsOnly} {
    set title {Documentation strata}
    set note "[llength $files] readable guides on trunk, selected from README, docs, www, and text formats."
    set empty {No documentation-shaped files are present on trunk.}
  } else {
    set title {Trunk source survey}
    set note "[llength $files] files read from Fossil's trunk manifest."
    set empty {No files are present on trunk.}
  }
  set action ""
  if {!$docsOnly && [dict exists $data can_write] &&
      [dict get $data can_write]} {
    set action [::fossilhub::views::repositoryAction \
      $repository files/new {Add file}]
  }
  return [format {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">%s</p><p>%s</p></div>%s</div>%s} \
    $title [::fossilhub::view::escape $note] $action \
    [::fossilhub::views::renderFileRows $repository $files $empty]]
}

proc ::fossilhub::views::renderFileSection {repository data} {
  set record [dict get $data file]
  set filename [dict get $record filename]
  set back [::fossilhub::views::repositoryPath $repository files]
  if {![dict get $record text]} {
    set body [format {
      <div class="panel"><div class="panel-body empty-stratum">This artifact is binary. FossilHub preserves it but does not render it as text.</div></div>}]
  } else {
    set truncation ""
    if {[dict get $record truncated]} {
      set truncation {<p class="content-note">Preview capped at 256 KiB.</p>}
    }
    set body [format {
      %s<div class="panel source-panel"><pre><code>%s</code></pre></div>} \
      $truncation [::fossilhub::view::escape [dict get $record content]]]
  }
  set editAction ""
  if {[dict exists $data can_write] && [dict get $data can_write]} {
    set editAction [::fossilhub::views::repositoryAction $repository \
      "file/[dict get $record uuid]/edit" {Edit artifact}]
  }
  return [format {
    <div class="section-lede">
      <a class="back-link" href="#" data-hub-path="%s">← trunk files</a>
      <p class="eyebrow">Artifact %s · %s</p>
      <div class="section-title-actions"><h2>%s</h2>%s</div>
    </div>%s} \
    $back \
    [::fossilhub::view::escape [string range [dict get $record uuid] 0 11]] \
    [::fossilhub::view::escape \
      [::fossilhub::view::formatBytes [dict get $record size]]] \
    [::fossilhub::view::escape $filename] $editAction $body]
}

proc ::fossilhub::views::renderWikiSection {repository data} {
  set pages [dict get $data pages]
  set action ""
  if {[dict exists $data can_write] && [dict get $data can_write]} {
    set action [::fossilhub::views::repositoryAction \
      $repository wiki/new {New Wiki page}]
  }
  if {[llength $pages] == 0} {
    return [format {
      <div class="section-lede section-lede-actions"><p class="eyebrow">Wiki field notes</p>%s</div>
      <div class="panel"><div class="panel-body empty-stratum">No Wiki pages have been recorded in this repository.</div></div>} \
      $action]
  }
  set html [format {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">Wiki field notes</p><p>%d current pages, read from their latest Fossil artifacts.</p></div>%s</div>
    <div class="panel artifact-list">} [llength $pages] $action]
  foreach page $pages {
    set path [::fossilhub::views::repositoryPath $repository \
      "wiki-page/[dict get $page uuid]"]
    append html [format {
      <a class="artifact-row" href="#" data-hub-path="%s">
        <span class="artifact-mark wiki-mark">W</span>
        <span class="artifact-main"><b>%s</b><small>%s · %s</small></span>
        <span class="artifact-size">%s</span>
        <span class="artifact-hash">%s</span>
      </a>} \
      $path \
      [::fossilhub::view::escape [dict get $page title]] \
      [::fossilhub::view::escape [dict get $page user]] \
      [::fossilhub::view::escape [dict get $page comment]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $page epoch]]] \
      [::fossilhub::view::escape [string range [dict get $page uuid] 0 9]]]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::views::renderWikiPage {repository data} {
  set page [dict get $data page]
  set back [::fossilhub::views::repositoryPath $repository wiki]
  set editAction ""
  if {[dict exists $data can_write] && [dict get $data can_write]} {
    set editAction [::fossilhub::views::repositoryAction $repository \
      "wiki-page/[dict get $page uuid]/edit" {Edit Wiki page}]
  }
  return [format {
    <div class="section-lede">
      <a class="back-link" href="#" data-hub-path="%s">← wiki field notes</a>
      <p class="eyebrow">Wiki artifact %s · %s</p>
      <div class="section-title-actions"><h2>%s</h2>%s</div>
    </div>
    <article class="panel prose-artifact"><pre>%s</pre></article>} \
    $back \
    [::fossilhub::view::escape [string range [dict get $page uuid] 0 11]] \
    [::fossilhub::view::escape \
      [::fossilhub::view::formatDate [dict get $page epoch]]] \
    [::fossilhub::view::escape [dict get $page title]] $editAction \
    [::fossilhub::view::escape [dict get $page content]]]
}

proc ::fossilhub::views::renderTicketsSection {repository data} {
  set tickets [dict get $data tickets]
  set action ""
  if {[dict exists $data can_triage] && [dict get $data can_triage]} {
    set action [::fossilhub::views::repositoryAction \
      $repository tickets/new {Open ticket}]
  }
  if {[llength $tickets] == 0} {
    return [format {
      <div class="section-lede section-lede-actions"><p class="eyebrow">Ticket cabinet</p>%s</div>
      <div class="panel"><div class="panel-body empty-stratum">No tickets have been recorded in this repository.</div></div>} \
      $action]
  }
  set html [format {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">Ticket cabinet</p><p>%d tickets from Fossil's current ticket state.</p></div>%s</div>
    <div class="panel artifact-list">} [llength $tickets] $action]
  foreach ticket $tickets {
    set status [dict get $ticket status]
    set statusClass ticket-open
    if {[string tolower $status] in {closed fixed resolved}} {
      set statusClass ticket-closed
    }
    append html [format {
      <a class="artifact-row ticket-row" href="#" data-hub-path="%s">
        <span class="ticket-state %s">%s</span>
        <span class="artifact-main"><b>%s</b><small>%s · %s · %s</small></span>
        <span class="artifact-size">%s</span>
        <span class="artifact-hash">%s</span>
      </a>} \
      [::fossilhub::views::repositoryPath $repository \
        "ticket/[dict get $ticket uuid]"] \
      $statusClass [::fossilhub::view::escape $status] \
      [::fossilhub::view::escape [dict get $ticket title]] \
      [::fossilhub::view::escape [dict get $ticket type]] \
      [::fossilhub::view::escape [dict get $ticket severity]] \
      [::fossilhub::view::escape [dict get $ticket comment]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $ticket epoch]]] \
      [::fossilhub::view::escape [string range [dict get $ticket uuid] 0 9]]]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::views::renderForumSection {repository data} {
  set posts [dict get $data posts]
  set action ""
  if {[dict exists $data can_triage] && [dict get $data can_triage]} {
    set action [::fossilhub::views::repositoryAction \
      $repository forum/new {New discussion}]
  }
  if {[llength $posts] == 0} {
    return [format {
      <div class="section-lede section-lede-actions"><p class="eyebrow">Forum boreholes</p>%s</div>
      <div class="panel"><div class="panel-body empty-stratum">No forum posts have been recorded in this repository.</div></div>} \
      $action]
  }
  set html [format {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">Forum boreholes</p><p>%d recent posts preserved as Fossil artifacts.</p></div>%s</div>
    <div class="panel forum-list">} [llength $posts] $action]
  foreach post $posts {
    set reply ""
    if {[dict exists $data can_triage] && [dict get $data can_triage]} {
      set reply [format {
        <a class="back-link forum-reply" href="#" data-hub-path="%s">Reply</a>} \
        [::fossilhub::views::repositoryPath $repository \
          "forum/[dict get $post uuid]/reply"]]
    }
    append html [format {
      <article class="forum-post">
        <div class="avatar" aria-hidden="true">%s</div>
        <div><h3>%s</h3><p>%s · <span class="hash">%s</span></p></div>
        <div class="forum-post-end"><time>%s</time>%s</div>
      </article>} \
      [::fossilhub::view::escape \
        [::fossilhub::view::initials [dict get $post user]]] \
      [::fossilhub::view::escape [dict get $post comment]] \
      [::fossilhub::view::escape [dict get $post user]] \
      [::fossilhub::view::escape [dict get $post uuid]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $post epoch]]] $reply]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::views::renderRepositorySection {repository section data} {
  switch -- $section {
    timeline { return [::fossilhub::views::renderTimelineSection $repository $data] }
    files { return [::fossilhub::views::renderFilesSection $repository $data 0] }
    docs { return [::fossilhub::views::renderFilesSection $repository $data 1] }
    file { return [::fossilhub::views::renderFileSection $repository $data] }
    wiki { return [::fossilhub::views::renderWikiSection $repository $data] }
    wiki-page { return [::fossilhub::views::renderWikiPage $repository $data] }
    tickets { return [::fossilhub::views::renderTicketsSection $repository $data] }
    forum { return [::fossilhub::views::renderForumSection $repository $data] }
    file-compose - wiki-compose - ticket-compose - ticket-workbench -
    forum-compose {
      return [::fossilhub::views::renderMutationSection \
        $repository $section $data]
    }
  }
  error "unknown repository section"
}
