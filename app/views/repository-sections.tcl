namespace eval ::fossilhub::views {}

proc ::fossilhub::views::repositoryPath {repository suffix} {
  set base "/repo/[::fossilhub::view::repositorySlug $repository]"
  if {$suffix eq ""} {
    return $base
  }
  return "$base/$suffix"
}

proc ::fossilhub::views::emptySection {title message} {
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede">
      <p class="eyebrow">%s</p>
    </div>
    <div class="panel"><div class="panel-body empty-stratum">%s</div></div>} \
    [::fossilhub::view::escape $title] \
    [::fossilhub::view::escape $message]]
}

proc ::fossilhub::views::repositoryAction {repository suffix label} {
  return [::fossilhub::views::localizedFormat {
    <a class="btn btn-sm" href="#" data-hub-path="%s">%s</a>} \
    [::fossilhub::views::repositoryPath $repository $suffix] \
    [::fossilhub::view::escape $label]]
}

proc ::fossilhub::views::renderTimelineSection {repository data} {
  if {![dict exists $data timeline]} {
    return [::fossilhub::views::localizedFormat {<div class="filters"></div><div class="panel rv-panel">%s</div>} \
      [::fossilhub::view::repositoryTimeline [dict get $data repository]]]
  }
  set request [dict get $data request_options]
  set filter [dict get $request type]
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
    append buttons [::fossilhub::views::localizedFormat {
      <a class="%s" href="#" data-hub-path="%s">%s</a>} \
      $class $path $label]
  }
  set branchOptions {<option value="">All branches</option>}
  foreach branch [dict get $data branches] {
    set value [dict get $branch name]
    set selected [expr {$value eq [dict get $request branch] ? " selected" : ""}]
    append branchOptions [::fossilhub::views::localizedFormat {<option value="%s"%s>%s</option>} \
      [::fossilhub::view::escape $value] $selected \
      [::fossilhub::view::escape $value]]
  }
  set tagOptions {<option value="">All tags</option>}
  foreach tag [dict get $data tags] {
    set value [dict get $tag name]
    set selected [expr {$value eq [dict get $request tag] ? " selected" : ""}]
    append tagOptions [::fossilhub::views::localizedFormat {<option value="%s"%s>%s</option>} \
      [::fossilhub::view::escape $value] $selected \
      [::fossilhub::view::escape $value]]
  }
  set form [::fossilhub::views::localizedFormat {
    <form class="timeline-filter-form" method="get" action="" data-hub-action="%s">
      <input type="hidden" name="event" value="%s">
      <label>Search<input name="q" value="%s" maxlength="200" placeholder="message, author, or hash"></label>
      <label>Author<input name="author" value="%s" maxlength="160" placeholder="any author"></label>
      <label>Branch<select name="branch">%s</select></label>
      <label>Tag<select name="tag">%s</select></label>
      <label>From<input type="date" name="from" value="%s"></label>
      <label>To<input type="date" name="to" value="%s"></label>
      <button class="btn btn-sm" type="submit">Survey</button>
    </form>} \
    [::fossilhub::views::repositoryPath $repository timeline] \
    [::fossilhub::view::escape $filter] \
    [::fossilhub::view::escape [dict get $request q]] \
    [::fossilhub::view::escape [dict get $request author]] \
    $branchOptions $tagOptions \
    [::fossilhub::view::escape [dict get $request from_date]] \
    [::fossilhub::view::escape [dict get $request to_date]]]
  set timeline [dict get $data timeline]
  set events [dict get $timeline events]
  if {[llength $events] == 0} {
    set eventRows {<div class="panel"><div class="panel-body empty-stratum">No events match this survey.</div></div>}
  } else {
    set eventRows {<div class="panel artifact-list timeline-results">}
    foreach event $events {
      lassign [::fossilhub::view::eventPresentation \
        [dict get $event type]] label _
      set path [::fossilhub::views::repositoryPath $repository timeline]
      if {[dict get $event type] eq "ci"} {
        set path [::fossilhub::views::repositoryPath $repository \
          "checkin/[dict get $event uuid]"]
      } elseif {[dict get $event type] eq "w"} {
        set path [::fossilhub::views::repositoryPath $repository \
          "wiki-revision/[dict get $event uuid]"]
      } elseif {[dict get $event type] eq "f"} {
        set path [::fossilhub::views::repositoryPath $repository \
          "discussion/[dict get $event uuid]"]
      } elseif {[dict get $event type] eq "t"} {
        set path [::fossilhub::views::repositoryPath $repository tickets]
      }
      set branch [dict get $event branch]
      if {$branch ne ""} {
        set branch " · $branch"
      }
      append eventRows [::fossilhub::views::localizedFormat {
        <a class="artifact-row" href="#" data-hub-path="%s">
          <span class="artifact-mark">%s</span>
          <span class="artifact-main"><b>%s</b><small>%s · %s%s</small></span>
          <span class="artifact-size">%s</span>
          <span class="artifact-hash">%s</span>
        </a>} \
        $path [::fossilhub::view::escape [string toupper [dict get $event type]]] \
        [::fossilhub::view::escape [dict get $event comment]] \
        [::fossilhub::view::escape $label] \
        [::fossilhub::view::escape [dict get $event user]] \
        [::fossilhub::view::escape $branch] \
        [::fossilhub::view::escape \
          [::fossilhub::view::formatDate [dict get $event epoch]]] \
        [::fossilhub::view::escape [string range [dict get $event uuid] 0 9]]]
    }
    append eventRows </div>
  }
  set deeper ""
  set cursor [dict get $timeline next_cursor]
  if {$cursor ne ""} {
    set query {}
    foreach {key parameter} {q q type event author author branch branch tag tag \
        from_date from to_date to} {
      set value [dict get $request $key]
      if {$value ne "" && !($key eq "type" && $value eq "all")} {
        lappend query "$parameter=[::fossilhub::view::queryEncode $value]"
      }
    }
    lappend query "cursor=[::fossilhub::view::queryEncode $cursor]"
    set deeper [::fossilhub::views::localizedFormat {
      <a class="deeper" href="#" data-hub-path="%s?%s">Load deeper strata ↓</a>} \
      [::fossilhub::views::repositoryPath $repository timeline] [join $query &]]
  }
  return [::fossilhub::views::localizedFormat {
    <div class="filters">%s
      <div class="tl-legend" aria-hidden="true">
        <span><i class="dot dot-azu"></i>check-in</span>
        <span><i class="dot dot-verdi"></i>wiki</span>
        <span><i class="dot dot-iron"></i>ticket</span>
        <span><i class="dot dot-hollow"></i>forum</span>
      </div>
    </div>%s%s%s} $buttons $form $eventRows $deeper]
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
    append html [::fossilhub::views::localizedFormat {
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
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">%s</p><p>%s</p></div>%s</div>%s} \
    $title [::fossilhub::view::escape $note] $action \
    [::fossilhub::views::renderFileRows $repository $files $empty]]
}

proc ::fossilhub::views::renderTreeSection {repository data} {
  set tree [dict get $data tree]
  set checkin [dict get $tree checkin]
  set revision [dict get $checkin uuid]
  set directory [dict get $tree directory]
  set crumbs [::fossilhub::views::localizedFormat {
    <a href="#" data-hub-path="%s">root</a>} \
    [::fossilhub::views::repositoryPath $repository "tree/$revision"]]
  set accumulated ""
  foreach segment [split $directory /] {
    if {$segment eq ""} continue
    set accumulated [expr {$accumulated eq "" ? $segment : "$accumulated/$segment"}]
    append crumbs [::fossilhub::views::localizedFormat {<span>/</span><a href="#" data-hub-path="%s?path=%s">%s</a>} \
      [::fossilhub::views::repositoryPath $repository "tree/$revision"] \
      [::fossilhub::view::queryEncode $accumulated] \
      [::fossilhub::view::escape $segment]]
  }
  set actions [::fossilhub::views::localizedFormat {
    <a class="btn btn-ghost btn-sm" href="#" data-hub-path="%s">Branches</a>
    <a class="btn btn-ghost btn-sm" href="#" data-hub-path="%s">Tags</a>
    <a class="btn btn-ghost btn-sm" href="#" data-hub-path="%s">Statistics</a>
    <a class="btn btn-sm" href="#" data-hub-path="%s">Download ZIP</a>} \
    [::fossilhub::views::repositoryPath $repository branches] \
    [::fossilhub::views::repositoryPath $repository tags] \
    [::fossilhub::views::repositoryPath $repository stats] \
    [::fossilhub::views::repositoryPath $repository "archive/$revision.zip"]]
  if {[dict exists $data can_write] && [dict get $data can_write]} {
    append actions [::fossilhub::views::repositoryAction \
      $repository files/new {Add file}]
  }
  set entries [dict get $tree entries]
  if {[llength $entries] == 0} {
    set rows {<div class="panel"><div class="panel-body empty-stratum">This directory contains no files.</div></div>}
  } else {
    set rows {<div class="panel artifact-list">}
    foreach entry $entries {
      if {[dict get $entry type] eq "directory"} {
        set mark DIR
        set detail {deeper stratum}
        set path [::fossilhub::views::localizedFormat {%s?path=%s} \
          [::fossilhub::views::repositoryPath $repository "tree/$revision"] \
          [::fossilhub::view::queryEncode [dict get $entry path]]]
        set size —
        set hash →
      } else {
        set extension [string trimleft [file extension [dict get $entry name]] .]
        set mark [expr {$extension eq "" ? "FILE" : $extension}]
        set detail [dict get $entry path]
        set path [::fossilhub::views::repositoryPath $repository \
          "blob/$revision/[dict get $entry uuid]"]
        set size [::fossilhub::view::formatBytes [dict get $entry size]]
        set hash [string range [dict get $entry uuid] 0 9]
      }
      append rows [::fossilhub::views::localizedFormat {
        <a class="artifact-row" href="#" data-hub-path="%s">
          <span class="artifact-mark">%s</span>
          <span class="artifact-main"><b>%s</b><small>%s</small></span>
          <span class="artifact-size">%s</span><span class="artifact-hash">%s</span>
        </a>} $path [::fossilhub::view::escape $mark] \
        [::fossilhub::view::escape [dict get $entry name]] \
        [::fossilhub::view::escape $detail] \
        [::fossilhub::view::escape $size] [::fossilhub::view::escape $hash]]
    }
    append rows </div>
  }
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede section-lede-actions"><div>
      <p class="eyebrow">Versioned source survey</p>
      <div class="tree-crumbs">%s</div>
      <p>%s · %s · %s</p>
    </div><div class="section-actions">%s</div></div>%s} \
    $crumbs [::fossilhub::view::escape [dict get $checkin branch]] \
    [::fossilhub::view::escape [string range $revision 0 11]] \
    [::fossilhub::view::escape [dict get $checkin comment]] $actions $rows]
}

proc ::fossilhub::views::renderDocsAtRevision {repository data} {
  set documentation [dict get $data documentation]
  set checkin [dict get $documentation checkin]
  set revision [dict get $checkin uuid]
  set options ""
  foreach branch [dict get $data branches] {
    set selected [expr {[string equal -nocase [dict get $branch uuid] $revision] ?
      " selected" : ""}]
    append options [::fossilhub::views::localizedFormat {<option value="%s"%s>%s · %s</option>} \
      [::fossilhub::view::escape [dict get $branch uuid]] $selected \
      [::fossilhub::view::escape [dict get $branch name]] \
      [::fossilhub::view::escape [string range [dict get $branch uuid] 0 9]]]
  }
  set selector [::fossilhub::views::localizedFormat {
    <form class="revision-selector" method="get" action="" data-hub-action="%s">
      <label>Check-in<select name="revision">%s</select></label>
      <button class="btn btn-sm" type="submit">Open</button>
    </form>} [::fossilhub::views::repositoryPath $repository docs] $options]
  set files [dict get $documentation files]
  if {[llength $files] == 0} {
    set rows {<div class="panel"><div class="panel-body empty-stratum">No documentation-shaped files exist at this check-in.</div></div>}
  } else {
    set rows {<div class="panel artifact-list">}
    foreach file $files {
      append rows [::fossilhub::views::localizedFormat {
        <a class="artifact-row" href="#" data-hub-path="%s">
          <span class="artifact-mark">DOC</span>
          <span class="artifact-main"><b>%s</b><small>rendered with strict safe markup</small></span>
          <span class="artifact-size">%s</span><span class="artifact-hash">%s</span>
        </a>} \
        [::fossilhub::views::repositoryPath $repository \
          "doc/$revision/[dict get $file uuid]"] \
        [::fossilhub::view::escape [dict get $file filename]] \
        [::fossilhub::view::escape \
          [::fossilhub::view::formatBytes [dict get $file size]]] \
        [::fossilhub::view::escape [string range [dict get $file uuid] 0 9]]]
    }
    append rows </div>
  }
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">Documentation strata</p>
    <p>%d guides at check-in %s.</p></div>%s</div>%s} \
    [llength $files] [::fossilhub::view::escape [string range $revision 0 11]] \
    $selector $rows]
}

proc ::fossilhub::views::renderVersionedFile {repository data rendered} {
  set file [dict get $data file]
  set checkin [dict get $file checkin]
  set revision [dict get $checkin uuid]
  set artifact [dict get $file uuid]
  set back [::fossilhub::views::repositoryPath $repository "tree/$revision"]
  set directory [file dirname [dict get $file filename]]
  if {$directory ne "."} {
    append back "?path=[::fossilhub::view::queryEncode $directory]"
  }
  set actions [::fossilhub::views::localizedFormat {
    <a class="btn btn-ghost btn-sm" href="#" data-hub-path="%s">History</a>
    <a class="btn btn-ghost btn-sm" href="#" data-hub-path="%s">Blame</a>
    <a class="btn btn-sm" href="#" data-hub-path="%s">Raw download</a>} \
    [::fossilhub::views::repositoryPath $repository "history/$revision/$artifact"] \
    [::fossilhub::views::repositoryPath $repository "blame/$revision/$artifact"] \
    [::fossilhub::views::repositoryPath $repository "raw/$revision/$artifact"]]
  if {![dict get $file text]} {
    set body {<div class="panel"><div class="panel-body empty-stratum">This artifact is binary and is available only as a raw download.</div></div>}
  } elseif {$rendered} {
    set extension [string tolower [file extension [dict get $file filename]]]
    set mimetype [expr {$extension eq ".wiki" ? "text/x-fossil-wiki" :
      ($extension in {.txt .html .htm} ? "text/plain" : "text/x-markdown")}]
    set body [::fossilhub::views::localizedFormat {<article class="panel prose-artifact">%s</article>} \
      [::fossilhub::markup::render [dict get $file content] $mimetype]]
  } else {
    set notice [expr {[dict get $file truncated] ?
      {<p class="content-note">Preview capped at the safe rendering limit.</p>} : ""}]
    set body [::fossilhub::views::localizedFormat {%s<div class="panel source-panel"><pre><code>%s</code></pre></div>} \
      $notice [::fossilhub::view::escape [dict get $file content]]]
  }
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← versioned tree</a>
      <p class="eyebrow">%s · %s · %s</p>
      <div class="section-title-actions"><h2>%s</h2><div class="section-actions">%s</div></div>
    </div>%s} $back \
    [::fossilhub::view::escape [string range $revision 0 11]] \
    [::fossilhub::view::escape [string range $artifact 0 11]] \
    [::fossilhub::view::escape \
      [::fossilhub::view::formatBytes [dict get $file size]]] \
    [::fossilhub::view::escape [dict get $file filename]] $actions $body]
}

proc ::fossilhub::views::renderFileHistory {repository data} {
  set file [dict get $data file]
  set revision [dict get $file checkin uuid]
  set artifact [dict get $file uuid]
  set rows {<div class="panel artifact-list">}
  foreach item [dict get $data history] {
    set target [dict get $item uuid]
    set path [::fossilhub::views::repositoryPath $repository \
      "checkin/[dict get $item checkin]"]
    if {$target ne ""} {
      set path [::fossilhub::views::repositoryPath $repository \
        "blob/[dict get $item checkin]/$target"]
    }
    append rows [::fossilhub::views::localizedFormat {
      <a class="artifact-row" href="#" data-hub-path="%s">
        <span class="artifact-mark">%s</span><span class="artifact-main"><b>%s</b>
        <small>%s · %s</small></span><span class="artifact-size">%s</span>
        <span class="artifact-hash">%s</span></a>} $path \
      [::fossilhub::view::escape [string toupper [dict get $item change]]] \
      [::fossilhub::view::escape [dict get $item filename]] \
      [::fossilhub::view::escape [dict get $item comment]] \
      [::fossilhub::view::escape [dict get $item user]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $item epoch]]] \
      [::fossilhub::view::escape [string range [dict get $item checkin] 0 9]]]
  }
  append rows </div>
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← file</a>
    <p class="eyebrow">File lineage</p><h2>%s</h2></div>%s} \
    [::fossilhub::views::repositoryPath $repository "blob/$revision/$artifact"] \
    [::fossilhub::view::escape [dict get $file filename]] $rows]
}

proc ::fossilhub::views::renderBlame {repository data} {
  set file [dict get $data file]
  set revision [dict get $file checkin uuid]
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← file</a>
    <p class="eyebrow">Line attribution · capped at 200 revisions</p><h2>%s</h2></div>
    <div class="panel source-panel"><pre><code>%s</code></pre></div>} \
    [::fossilhub::views::repositoryPath $repository \
      "blob/$revision/[dict get $file uuid]"] \
    [::fossilhub::view::escape [dict get $file filename]] \
    [::fossilhub::view::escape [dict get $data content]]]
}

proc ::fossilhub::views::renderCheckin {repository data} {
  set checkin [dict get $data checkin]
  set revision [dict get $checkin uuid]
  set relations ""
  foreach relation {parents children} {
    set links ""
    foreach item [dict get $checkin $relation] {
      append links [::fossilhub::views::localizedFormat {
        <a class="relation-chip" href="#" data-hub-path="%s">%s · %s</a>} \
        [::fossilhub::views::repositoryPath $repository \
          "checkin/[dict get $item uuid]"] \
        [::fossilhub::view::escape [string range [dict get $item uuid] 0 9]] \
        [::fossilhub::view::escape [dict get $item comment]]]
    }
    if {$links eq ""} {
      set links {<span class="muted-value">none</span>}
    }
    append relations [::fossilhub::views::localizedFormat {<div class="relation-row"><b>%s</b><div>%s</div></div>} \
      [string totitle $relation] $links]
  }
  set labels ""
  if {[dict get $checkin branch] ne ""} {
    append labels [::fossilhub::views::localizedFormat {<span class="chip chip-azu">branch · %s</span>} \
      [::fossilhub::view::escape [dict get $checkin branch]]]
  }
  foreach tag [dict get $checkin tags] {
    append labels [::fossilhub::views::localizedFormat {<span class="chip chip-verdi">tag · %s</span>} \
      [::fossilhub::view::escape $tag]]
  }
  set changes {<div class="panel artifact-list">}
  foreach change [dict get $checkin changes] {
    set target [dict get $change uuid]
    set path [::fossilhub::views::repositoryPath $repository \
      "tree/$revision"]
    if {$target ne ""} {
      set path [::fossilhub::views::repositoryPath $repository \
        "blob/$revision/$target"]
    }
    set stat ""
    if {[dict get $change additions] ne ""} {
      set stat "+[dict get $change additions] −[dict get $change deletions]"
    }
    set prior [dict get $change previous_filename]
    if {$prior ne "" && $prior ne [dict get $change filename]} {
      set prior "$prior → "
    } else {
      set prior ""
    }
    append changes [::fossilhub::views::localizedFormat {
      <a class="artifact-row" href="#" data-hub-path="%s">
        <span class="artifact-mark">%s</span><span class="artifact-main"><b>%s%s</b>
        <small>%s</small></span><span class="artifact-size">%s</span>
        <span class="artifact-hash">%s</span></a>} $path \
      [::fossilhub::view::escape [string toupper [dict get $change change]]] \
      [::fossilhub::view::escape $prior] \
      [::fossilhub::view::escape [dict get $change filename]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatBytes [dict get $change size]]] \
      [::fossilhub::view::escape $stat] \
      [::fossilhub::view::escape [string range $target 0 9]]]
  }
  if {[llength [dict get $checkin changes]] == 0} {
    append changes {<div class="panel-body empty-stratum">This check-in records topology or metadata without file changes.</div>}
  }
  append changes </div>
  set diff [dict get $data diff]
  if {[dict get $diff content] eq ""} {
    set diffHtml [::fossilhub::views::localizedFormat {<div class="panel"><div class="panel-body empty-stratum">%s</div></div>} \
      [::fossilhub::view::escape [dict get $diff reason]]]
  } else {
    set diffHtml [::fossilhub::views::localizedFormat {<div class="panel source-panel diff-panel"><pre><code>%s</code></pre></div>} \
      [::fossilhub::view::escape [dict get $diff content]]]
  }
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← timeline</a>
      <p class="eyebrow">Check-in · %s · %s</p><h2>%s</h2>
      <div class="chip-row">%s</div>
      <p>%s · +%s −%s</p>
    </div><div class="panel panel-body relation-panel">%s</div>
    <div class="section-lede"><p class="eyebrow">Changed files</p></div>%s
    <div class="section-lede"><p class="eyebrow">Unified diff</p></div>%s} \
    [::fossilhub::views::repositoryPath $repository timeline] \
    [::fossilhub::view::escape [string range $revision 0 15]] \
    [::fossilhub::view::escape \
      [::fossilhub::view::formatDate [dict get $checkin epoch]]] \
    [::fossilhub::view::escape [dict get $checkin comment]] $labels \
    [::fossilhub::view::escape [dict get $checkin user]] \
    [::fossilhub::view::formatCount [dict get $checkin additions]] \
    [::fossilhub::view::formatCount [dict get $checkin deletions]] \
    $relations $changes $diffHtml]
}

proc ::fossilhub::views::renderBranchIndex {repository data} {
  set rows {<div class="panel artifact-list">}
  foreach branch [dict get $data branches] {
    append rows [::fossilhub::views::localizedFormat {
      <div class="artifact-row">
        <span class="artifact-mark">BR</span><span class="artifact-main"><b><a href="#" data-hub-path="%s">%s</a></b>
        <small>%s check-ins · updated %s</small></span><a class="artifact-size" href="#" data-hub-path="%s">tree</a>
        <span class="artifact-hash">%s</span></div>} \
      [::fossilhub::views::localizedFormat {%s?branch=%s} \
        [::fossilhub::views::repositoryPath $repository timeline] \
        [::fossilhub::view::queryEncode [dict get $branch name]]] \
      [::fossilhub::view::escape [dict get $branch name]] \
      [::fossilhub::view::formatCount [dict get $branch checkins]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $branch epoch]]] \
      [::fossilhub::views::repositoryPath $repository \
        "tree/[dict get $branch uuid]"] \
      [::fossilhub::view::escape [string range [dict get $branch uuid] 0 9]]]
  }
  append rows </div>
  return [::fossilhub::views::localizedFormat {<div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← files</a>
    <p class="eyebrow">Branch index</p><h2>Parallel strata</h2></div>%s} \
    [::fossilhub::views::repositoryPath $repository files] $rows]
}

proc ::fossilhub::views::renderTagIndex {repository data} {
  set tags [dict get $data tags]
  if {[llength $tags] == 0} {
    set rows {<div class="panel"><div class="panel-body empty-stratum">No symbolic tags have been attached to check-ins.</div></div>}
  } else {
    set rows {<div class="panel artifact-list">}
    foreach tag $tags {
      append rows [::fossilhub::views::localizedFormat {
        <a class="artifact-row" href="#" data-hub-path="%s">
          <span class="artifact-mark">TAG</span><span class="artifact-main"><b>%s</b>
          <small>%s · %s</small></span><span class="artifact-size">check-in</span>
          <span class="artifact-hash">%s</span></a>} \
        [::fossilhub::views::repositoryPath $repository \
          "checkin/[dict get $tag uuid]"] \
        [::fossilhub::view::escape [dict get $tag name]] \
        [::fossilhub::view::escape [dict get $tag user]] \
        [::fossilhub::view::escape [dict get $tag comment]] \
        [::fossilhub::view::escape [string range [dict get $tag uuid] 0 9]]]
    }
    append rows </div>
  }
  return [::fossilhub::views::localizedFormat {<div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← files</a>
    <p class="eyebrow">Tag index</p><h2>Named horizons</h2></div>%s} \
    [::fossilhub::views::repositoryPath $repository files] $rows]
}

proc ::fossilhub::views::renderStatistics {repository data} {
  set labels [dict create repository_bytes {Repository file} artifacts Artifacts \
    artifact_bytes {Artifact bytes} checkins Check-ins branches Branches files Filenames \
    wiki_revisions {Wiki revisions} tickets Tickets forum_posts {Forum posts} \
    contributors Contributors]
  set rows ""
  dict for {key label} $labels {
    set value [dict get [dict get $data statistics] $key]
    if {$key in {repository_bytes artifact_bytes}} {
      set value [::fossilhub::view::formatBytes $value]
    } else {
      set value [::fossilhub::view::formatCount $value]
    }
    append rows [::fossilhub::views::localizedFormat {<div class="stat-card"><span>%s</span><b>%s</b></div>} \
      [::fossilhub::view::escape $label] [::fossilhub::view::escape $value]]
  }
  set revision [dict get $data checkin uuid]
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← files</a>
    <p class="eyebrow">Repository statistics</p><h2>Measured strata</h2></div>
    <div class="statistics-grid">%s</div>
    <a class="btn btn-sm" href="#" data-hub-path="%s">Download current ZIP</a>} \
    [::fossilhub::views::repositoryPath $repository files] $rows \
    [::fossilhub::views::repositoryPath $repository "archive/$revision.zip"]]
}

proc ::fossilhub::views::renderFileSection {repository data} {
  set record [dict get $data file]
  set filename [dict get $record filename]
  set back [::fossilhub::views::repositoryPath $repository files]
  if {![dict get $record text]} {
    set body [::fossilhub::views::localizedFormat {
      <div class="panel"><div class="panel-body empty-stratum">This artifact is binary. FossilHub preserves it but does not render it as text.</div></div>}]
  } else {
    set truncation ""
    if {[dict get $record truncated]} {
      set truncation {<p class="content-note">Preview capped at 256 KiB.</p>}
    }
    set body [::fossilhub::views::localizedFormat {
      %s<div class="panel source-panel"><pre><code>%s</code></pre></div>} \
      $truncation [::fossilhub::view::escape [dict get $record content]]]
  }
  set editAction ""
  if {[dict exists $data can_write] && [dict get $data can_write]} {
    set editAction [::fossilhub::views::repositoryAction $repository \
      "file/[dict get $record uuid]/edit" {Edit artifact}]
  }
  return [::fossilhub::views::localizedFormat {
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
    return [::fossilhub::views::localizedFormat {
      <div class="section-lede section-lede-actions"><p class="eyebrow">Wiki field notes</p>%s</div>
      <div class="panel"><div class="panel-body empty-stratum">No Wiki pages have been recorded in this repository.</div></div>} \
      $action]
  }
  set html [::fossilhub::views::localizedFormat {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">Wiki field notes</p><p>%d current pages, read from their latest Fossil artifacts.</p></div>%s</div>
    <div class="panel artifact-list">} [llength $pages] $action]
  foreach page $pages {
    set path [::fossilhub::views::repositoryPath $repository \
      "wiki-revision/[dict get $page uuid]"]
    append html [::fossilhub::views::localizedFormat {
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
  if {[dict exists $data can_write] && [dict get $data can_write] &&
      (![dict exists $page latest] || [dict get $page latest])} {
    set editAction [::fossilhub::views::repositoryAction $repository \
      "wiki-page/[dict get $page uuid]/edit" {Edit Wiki page}]
  }
  set historyAction [::fossilhub::views::repositoryAction $repository \
    "wiki-revision/[dict get $page uuid]/history" {Revision history}]
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede">
      <a class="back-link" href="#" data-hub-path="%s">← wiki field notes</a>
      <p class="eyebrow">Wiki artifact %s · %s</p>
      <div class="section-title-actions"><h2>%s</h2><div class="section-actions">%s%s</div></div>
    </div>
    <article class="panel prose-artifact">%s</article>} \
    $back \
    [::fossilhub::view::escape [string range [dict get $page uuid] 0 11]] \
    [::fossilhub::view::escape \
      [::fossilhub::view::formatDate [dict get $page epoch]]] \
    [::fossilhub::view::escape [dict get $page title]] $historyAction $editAction \
    [::fossilhub::markup::render [dict get $page content] \
      [expr {[dict exists $page mimetype] ? [dict get $page mimetype] :
        "text/x-markdown"}]]]
}

proc ::fossilhub::views::renderWikiHistory {repository data} {
  set page [dict get $data page]
  set history [dict get $data history]
  set rows {<div class="panel artifact-list">}
  set newer ""
  foreach revision $history {
    set compare ""
    if {$newer ne ""} {
      set compare [::fossilhub::views::localizedFormat { · <a href="#" data-hub-path="%s">compare with newer</a>} \
        [::fossilhub::views::repositoryPath $repository \
          "wiki-compare/[dict get $revision uuid]/$newer"]]
    }
    append rows [::fossilhub::views::localizedFormat {
      <div class="artifact-row">
        <span class="artifact-mark">W</span><span class="artifact-main"><b><a href="#" data-hub-path="%s">%s</a></b>
        <small>%s · %s%s</small></span><span class="artifact-size">%s</span>
        <span class="artifact-hash">%s</span></div>} \
      [::fossilhub::views::repositoryPath $repository \
        "wiki-revision/[dict get $revision uuid]"] \
      [::fossilhub::view::escape [dict get $revision title]] \
      [::fossilhub::view::escape [dict get $revision user]] \
      [::fossilhub::view::escape [dict get $revision comment]] $compare \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $revision epoch]]] \
      [::fossilhub::view::escape [string range [dict get $revision uuid] 0 9]]]
    set newer [dict get $revision uuid]
  }
  append rows </div>
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← Wiki page</a>
    <p class="eyebrow">Wiki revision history</p><h2>%s</h2></div>%s} \
    [::fossilhub::views::repositoryPath $repository \
      "wiki-revision/[dict get $page uuid]"] \
    [::fossilhub::view::escape [dict get $page title]] $rows]
}

proc ::fossilhub::views::renderWikiComparison {repository data} {
  set before [dict get $data before]
  set after [dict get $data after]
  set comparison [dict get $data comparison]
  if {[dict get $comparison too_large]} {
    set body {<div class="panel"><div class="panel-body empty-stratum">These revisions exceed the interactive comparison line budget.</div></div>}
  } else {
    set lines ""
    foreach line [dict get $comparison lines] {
      set kind [dict get $line kind]
      set prefix [dict get [dict create equal { } added + deleted −] $kind]
      append lines [::fossilhub::views::localizedFormat {<span class="diff-line diff-%s"><i>%s</i>%s</span>} \
        $kind $prefix [::fossilhub::view::escape [dict get $line content]]]
    }
    set body [::fossilhub::views::localizedFormat {<div class="panel source-panel wiki-diff"><pre><code>%s</code></pre></div>} $lines]
  }
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← revision history</a>
    <p class="eyebrow">Wiki comparison</p><h2>%s</h2><p>%s → %s</p></div>%s} \
    [::fossilhub::views::repositoryPath $repository \
      "wiki-revision/[dict get $after uuid]/history"] \
    [::fossilhub::view::escape [dict get $after title]] \
    [::fossilhub::view::escape [string range [dict get $before uuid] 0 9]] \
    [::fossilhub::view::escape [string range [dict get $after uuid] 0 9]] $body]
}

proc ::fossilhub::views::renderTicketsSection {repository data} {
  set tickets [dict get $data tickets]
  set action ""
  if {[dict exists $data can_triage] && [dict get $data can_triage]} {
    set action [::fossilhub::views::repositoryAction \
      $repository tickets/new {Open ticket}]
  }
  if {[llength $tickets] == 0} {
    return [::fossilhub::views::localizedFormat {
      <div class="section-lede section-lede-actions"><p class="eyebrow">Ticket cabinet</p>%s</div>
      <div class="panel"><div class="panel-body empty-stratum">No tickets have been recorded in this repository.</div></div>} \
      $action]
  }
  set html [::fossilhub::views::localizedFormat {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">Ticket cabinet</p><p>%d tickets from Fossil's current ticket state.</p></div>%s</div>
    <div class="panel artifact-list">} [llength $tickets] $action]
  foreach ticket $tickets {
    set status [dict get $ticket status]
    set statusClass ticket-open
    if {[string tolower $status] in {closed fixed resolved}} {
      set statusClass ticket-closed
    }
    append html [::fossilhub::views::localizedFormat {
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

proc ::fossilhub::views::renderTicketDetail {repository data} {
  set ticket [dict get $data ticket]
  set action ""
  if {[dict exists $data can_triage] && [dict get $data can_triage]} {
    set action [::fossilhub::views::repositoryAction $repository \
      "ticket/[dict get $ticket uuid]/manage" {Manage ticket}]
  }
  set statusClass ticket-open
  if {[string tolower [dict get $ticket status]] in {closed fixed resolved}} {
    set statusClass ticket-closed
  }
  set fields ""
  foreach {key label} {status Status type Type severity Severity priority Priority \
      resolution Resolution} {
    set value [dict get $ticket $key]
    if {$value eq ""} { set value — }
    append fields [::fossilhub::views::localizedFormat {<div><span>%s</span><b>%s</b></div>} \
      $label [::fossilhub::view::escape $value]]
  }
  set history ""
  foreach event [dict get $ticket history] {
    set changes ""
    foreach change [dict get $event changes] {
      set field [dict get $change field]
      set value [dict get $change value]
      if {$field in {comment +comment}} {
        set rendered [::fossilhub::markup::render $value text/x-fossil-wiki]
      } else {
        set rendered [::fossilhub::views::localizedFormat {<p><b>%s</b> → %s</p>} \
          [::fossilhub::view::escape [string trimleft $field +]] \
          [::fossilhub::view::escape $value]]
      }
      append changes [::fossilhub::views::localizedFormat {<div class="ticket-change">%s</div>} $rendered]
    }
    append history [::fossilhub::views::localizedFormat {
      <article class="history-event"><header><b>%s</b><span>%s · %s</span></header>%s</article>} \
      [::fossilhub::view::escape [dict get $event user]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $event epoch]]] \
      [::fossilhub::view::escape [string range [dict get $event uuid] 0 9]] $changes]
  }
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← tickets</a>
      <p class="eyebrow">Ticket %s</p><div class="section-title-actions"><h2>%s</h2>%s</div>
      <span class="ticket-state %s">%s</span>
    </div><div class="ticket-facts">%s</div>
    <article class="panel prose-artifact">%s</article>
    <div class="section-lede"><p class="eyebrow">Change history</p></div>
    <div class="panel history-list">%s</div>} \
    [::fossilhub::views::repositoryPath $repository tickets] \
    [::fossilhub::view::escape [string range [dict get $ticket uuid] 0 11]] \
    [::fossilhub::view::escape [dict get $ticket title]] $action $statusClass \
    [::fossilhub::view::escape [dict get $ticket status]] $fields \
    [::fossilhub::markup::render [dict get $ticket comment] text/x-fossil-wiki] \
    $history]
}

proc ::fossilhub::views::renderForumSection {repository data} {
  set threads [dict get $data threads]
  set action ""
  if {[dict exists $data can_triage] && [dict get $data can_triage]} {
    set action [::fossilhub::views::repositoryAction \
      $repository forum/new {New discussion}]
  }
  if {[llength $threads] == 0} {
    return [::fossilhub::views::localizedFormat {
      <div class="section-lede section-lede-actions"><p class="eyebrow">Forum boreholes</p>%s</div>
      <div class="panel"><div class="panel-body empty-stratum">No forum posts have been recorded in this repository.</div></div>} \
      $action]
  }
  set html [::fossilhub::views::localizedFormat {
    <div class="section-lede section-lede-actions"><div><p class="eyebrow">Forum boreholes</p><p>%d threaded discussions preserved as Fossil artifacts.</p></div>%s</div>
    <div class="panel forum-list">} [llength $threads] $action]
  foreach thread $threads {
    append html [::fossilhub::views::localizedFormat {
      <a class="forum-post" href="#" data-hub-path="%s">
        <div class="avatar" aria-hidden="true">%s</div>
        <div><h3>%s</h3><p>%s · %s posts · <span class="hash">%s</span></p></div>
        <div class="forum-post-end"><time>%s</time></div>
      </a>} \
      [::fossilhub::views::repositoryPath $repository \
        "discussion/[dict get $thread uuid]"] \
      [::fossilhub::view::escape \
        [::fossilhub::view::initials [dict get $thread user]]] \
      [::fossilhub::view::escape [dict get $thread title]] \
      [::fossilhub::view::escape [dict get $thread user]] \
      [::fossilhub::view::formatCount [dict get $thread posts]] \
      [::fossilhub::view::escape [string range [dict get $thread uuid] 0 9]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $thread epoch]]]]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::views::renderDiscussion {repository data} {
  set thread [dict get $data thread]
  set posts ""
  foreach post [dict get $thread posts] {
    set reply ""
    if {[dict exists $data can_triage] && [dict get $data can_triage]} {
      set reply [::fossilhub::views::localizedFormat {<a class="back-link forum-reply" href="#" data-hub-path="%s">Reply</a>} \
        [::fossilhub::views::repositoryPath $repository \
          "forum/[dict get $post uuid]/reply"]]
    }
    append posts [::fossilhub::views::localizedFormat {
      <article class="forum-thread-post"><header><div class="avatar" aria-hidden="true">%s</div>
        <div><b>%s</b><span>%s · %s</span></div>%s</header>
        %s</article>} \
      [::fossilhub::view::escape \
        [::fossilhub::view::initials [dict get $post user]]] \
      [::fossilhub::view::escape [dict get $post user]] \
      [::fossilhub::view::escape \
        [::fossilhub::view::formatDate [dict get $post epoch]]] \
      [::fossilhub::view::escape [string range [dict get $post uuid] 0 9]] \
      $reply [::fossilhub::markup::render [dict get $post content] \
        [dict get $post mimetype]]]
  }
  return [::fossilhub::views::localizedFormat {
    <div class="section-lede"><a class="back-link" href="#" data-hub-path="%s">← forum</a>
      <p class="eyebrow">Thread %s</p><h2>%s</h2></div>
    <div class="panel forum-thread">%s</div>} \
    [::fossilhub::views::repositoryPath $repository forum] \
    [::fossilhub::view::escape [string range [dict get $thread uuid] 0 11]] \
    [::fossilhub::view::escape [dict get $thread title]] $posts]
}

proc ::fossilhub::views::renderRepositorySection {repository section data} {
  switch -- $section {
    timeline { return [::fossilhub::views::renderTimelineSection $repository $data] }
    files {
      if {[dict exists $data tree]} {
        return [::fossilhub::views::renderTreeSection $repository $data]
      }
      return [::fossilhub::views::renderFilesSection $repository $data 0]
    }
    tree { return [::fossilhub::views::renderTreeSection $repository $data] }
    docs {
      if {[dict exists $data documentation]} {
        return [::fossilhub::views::renderDocsAtRevision $repository $data]
      }
      return [::fossilhub::views::renderFilesSection $repository $data 1]
    }
    file { return [::fossilhub::views::renderFileSection $repository $data] }
    blob { return [::fossilhub::views::renderVersionedFile $repository $data 0] }
    doc { return [::fossilhub::views::renderVersionedFile $repository $data 1] }
    history { return [::fossilhub::views::renderFileHistory $repository $data] }
    blame { return [::fossilhub::views::renderBlame $repository $data] }
    checkin { return [::fossilhub::views::renderCheckin $repository $data] }
    branches { return [::fossilhub::views::renderBranchIndex $repository $data] }
    tags { return [::fossilhub::views::renderTagIndex $repository $data] }
    stats { return [::fossilhub::views::renderStatistics $repository $data] }
    wiki { return [::fossilhub::views::renderWikiSection $repository $data] }
    wiki-page - wiki-revision {
      return [::fossilhub::views::renderWikiPage $repository $data]
    }
    wiki-history { return [::fossilhub::views::renderWikiHistory $repository $data] }
    wiki-compare { return [::fossilhub::views::renderWikiComparison $repository $data] }
    tickets { return [::fossilhub::views::renderTicketsSection $repository $data] }
    ticket-detail { return [::fossilhub::views::renderTicketDetail $repository $data] }
    forum { return [::fossilhub::views::renderForumSection $repository $data] }
    discussion { return [::fossilhub::views::renderDiscussion $repository $data] }
    file-compose - wiki-compose - ticket-compose - ticket-workbench -
    forum-compose {
      return [::fossilhub::views::renderMutationSection \
        $repository $section $data]
    }
  }
  error "unknown repository section"
}
