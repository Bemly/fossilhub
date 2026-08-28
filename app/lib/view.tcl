namespace eval ::fossilhub::view {}

proc ::fossilhub::view::replaceRegion {document startMarker endMarker content} {
  set start [string first $startMarker $document]
  if {$start < 0} {
    error "missing SSR start marker"
  }
  set contentStart [expr {$start + [string length $startMarker]}]
  set finish [string first $endMarker $document $contentStart]
  if {$finish < 0} {
    error "missing SSR end marker"
  }
  return [string replace $document $start \
    [expr {$finish + [string length $endMarker] - 1}] \
    $content]
}

proc ::fossilhub::view::escape {value} {
  return [string map [list \
    & &amp\; \
    < &lt\; \
    > &gt\; \
    {"} &quot\; \
    ' &#39\;] $value]
}

proc ::fossilhub::view::queryEncode {value} {
  binary scan [encoding convertto utf-8 $value] c* bytes
  set result ""
  foreach byte $bytes {
    set unsigned [expr {$byte & 0xff}]
    if {($unsigned >= 0x41 && $unsigned <= 0x5a) ||
        ($unsigned >= 0x61 && $unsigned <= 0x7a) ||
        ($unsigned >= 0x30 && $unsigned <= 0x39) ||
        $unsigned in {45 46 95 126}} {
      append result [format %c $unsigned]
    } else {
      append result %[format %02X $unsigned]
    }
  }
  return $result
}

proc ::fossilhub::view::formatCount {value} {
  if {![string is wideinteger -strict $value]} {
    return 0
  }
  set sign ""
  if {$value < 0} {
    set sign -
    set value [expr {abs($value)}]
  }
  set digits [string reverse $value]
  set groups {}
  for {set index 0} {$index < [string length $digits]} {incr index 3} {
    lappend groups [string reverse [string range $digits $index [expr {$index + 2}]]]
  }
  return "$sign[join [lreverse $groups] ,]"
}

proc ::fossilhub::view::formatBytes {bytes} {
  if {![string is wideinteger -strict $bytes] || $bytes < 0} {
    return "—"
  }
  foreach {unit divisor} {GB 1073741824 MB 1048576 KB 1024} {
    if {$bytes >= $divisor} {
      return [format "%.1f %s" [expr {$bytes / double($divisor)}] $unit]
    }
  }
  return "$bytes B"
}

proc ::fossilhub::view::formatDate {epoch} {
  if {![string is wideinteger -strict $epoch] || $epoch <= 0} {
    return "—"
  }
  return [clock format $epoch -format %Y-%m-%d]
}

proc ::fossilhub::view::formatTime {epoch} {
  if {![string is wideinteger -strict $epoch] || $epoch <= 0} {
    return "—"
  }
  return [clock format $epoch -format %H:%M]
}

proc ::fossilhub::view::dayLabel {epoch} {
  if {![string is wideinteger -strict $epoch] || $epoch <= 0} {
    return "UNDATED"
  }
  return [string toupper [clock format $epoch -format {%A — %b %d}]]
}

proc ::fossilhub::view::relativeTime {epoch {now ""}} {
  if {![string is wideinteger -strict $epoch] || $epoch <= 0} {
    return "no activity yet"
  }
  if {$now eq ""} {
    set now [clock seconds]
  }
  set delta [expr {$now - $epoch}]
  if {$delta < 0} {
    return "just now"
  }
  if {$delta < 60} {
    return "just now"
  }
  if {$delta < 3600} {
    return "[expr {$delta / 60}]m ago"
  }
  if {$delta < 86400} {
    return "[expr {$delta / 3600}]h ago"
  }
  if {$delta < 604800} {
    return "[expr {$delta / 86400}]d ago"
  }
  return [::fossilhub::view::formatDate $epoch]
}

proc ::fossilhub::view::initials {user} {
  set letters ""
  foreach part [regexp -all -inline {[[:alnum:]]+} $user] {
    append letters [string index $part 0]
    if {[string length $letters] == 2} {
      break
    }
  }
  if {$letters eq ""} {
    set letters FH
  }
  return [string toupper $letters]
}

proc ::fossilhub::view::eventPresentation {type} {
  switch -- $type {
    ci { return [list check-in dot-azu] }
    w  { return [list {wiki edit} dot-verdi] }
    t  { return [list {ticket change} dot-iron] }
    f  { return [list {forum post} dot-hollow] }
    default { return [list activity dot-hollow] }
  }
}

proc ::fossilhub::view::repositoryDescription {repository} {
  set description [string trim [dict get $repository description]]
  if {$description eq ""} {
    return "No project description has been recorded in Fossil."
  }
  return $description
}

proc ::fossilhub::view::projectId {repository} {
  set projectCode [dict get $repository project_code]
  if {$projectCode eq ""} {
    return "—"
  }
  return [string range $projectCode 0 7]
}

proc ::fossilhub::view::percentage {value total} {
  if {![string is wideinteger -strict $value] ||
      ![string is wideinteger -strict $total] || $total <= 0} {
    return 0
  }
  return [expr {max(2, round(($value * 100.0) / $total))}]
}

proc ::fossilhub::view::homeTimeline {repository} {
  if {$repository eq "" || [llength [dict get $repository events]] == 0} {
    return {<div class="tl-list"><p class="panel-body">No repository activity has been recorded yet.</p></div>}
  }

  set events [lrange [dict get $repository events] 0 4]
  set height [expr {max(120, [llength $events] * 56)}]
  set html [format {<div class="tl-list">
            <svg class="tl-svg" viewBox="0 0 44 %d" preserveAspectRatio="none" aria-hidden="true">
              <path d="M22 0V%d" stroke="rgba(28,35,44,.28)" stroke-width="1.5" fill="none"/>
            </svg>} $height $height]
  foreach event $events {
    lassign [::fossilhub::view::eventPresentation [dict get $event type]] label dotClass
    append html [format {
            <div class="tl-row">
              <i class="tl-dot %s"></i>
              <span class="tl-time">%s</span>
              <div><p class="tl-title">%s</p>
              <p class="tl-meta">%s <span class="hash">%s</span> · %s</p></div>
            </div>} \
      $dotClass \
      [::fossilhub::view::escape [::fossilhub::view::formatTime [dict get $event epoch]]] \
      [::fossilhub::view::escape [dict get $event comment]] \
      [::fossilhub::view::escape $label] \
      [::fossilhub::view::escape [dict get $event uuid]] \
      [::fossilhub::view::escape [dict get $event user]]]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::view::repositoryTimeline {repository} {
  set events [dict get $repository events]
  if {[llength $events] == 0} {
    return {<div class="rv-list"><p class="panel-body">No events have reached this stratum yet.</p></div>}
  }

  set rowHeight 52
  set dayHeight 40
  set dayCount 0
  set previousDay ""
  foreach event $events {
    set day [::fossilhub::view::dayLabel [dict get $event epoch]]
    if {$day ne $previousDay} {
      incr dayCount
      set previousDay $day
    }
  }
  set height [expr {max(120,
    ([llength $events] * $rowHeight) + ($dayCount * $dayHeight))}]
  set html [format {<div class="rv-list">
            <svg class="rv-svg" viewBox="0 0 56 %d" style="height:%dpx" aria-hidden="true">
              <path d="M28 0V%d" stroke="rgba(28,35,44,.45)" stroke-width="1.5" fill="none"/>} $height $height $height]
  set y 26
  set previousDay ""
  foreach event $events {
    set day [::fossilhub::view::dayLabel [dict get $event epoch]]
    if {$day ne $previousDay} {
      incr y $dayHeight
      set previousDay $day
    }
    lassign [::fossilhub::view::eventPresentation [dict get $event type]] _ dotClass
    switch -- $dotClass {
      dot-azu   { set fill #205297; set extra "" }
      dot-verdi { set fill #2F6E5A; set extra "" }
      dot-iron  { set fill #A64B22; set extra "" }
      default   { set fill #F4F5EC; set extra { stroke="#1C232C" stroke-width="1.4"} }
    }
    append html [format {<circle cx="28" cy="%d" r="4.5" fill="%s"%s/>} $y $fill $extra]
    incr y $rowHeight
  }
  append html {</svg>}

  set activeDay ""
  foreach event $events {
    set day [::fossilhub::view::dayLabel [dict get $event epoch]]
    if {$day ne $activeDay} {
      append html [format {<div class="day-h">%s</div>} \
        [::fossilhub::view::escape $day]]
      set activeDay $day
    }
    lassign [::fossilhub::view::eventPresentation [dict get $event type]] label _
    append html [format {
            <div class="rv-row">
              <span aria-hidden="true"></span>
              <span class="rv-time">%s</span>
              <div><p class="rv-title">%s</p>
              <p class="rv-meta">%s · %s</p></div>
              <div class="rv-end"><span class="rv-hash">%s</span><span class="rv-user">%s</span></div>
            </div>} \
      [::fossilhub::view::escape [::fossilhub::view::formatTime [dict get $event epoch]]] \
      [::fossilhub::view::escape [dict get $event comment]] \
      [::fossilhub::view::escape $label] \
      [::fossilhub::view::escape [dict get $event user]] \
      [::fossilhub::view::escape [dict get $event uuid]] \
      [::fossilhub::view::escape [::fossilhub::view::initials [dict get $event user]]]]
  }
  append html {</div>}
  return $html
}

proc ::fossilhub::view::composition {repository} {
  set checkins [dict get $repository checkins]
  set wiki [dict get $repository wiki_events]
  set tickets [dict get $repository ticket_events]
  set forum [dict get $repository forum_events]
  set total [expr {$checkins + $wiki + $tickets + $forum}]
  if {$total <= 0} {
    set total 1
  }

  return [format {
            <div class="comp-seg" aria-hidden="true">
              <span class="cb-code" style="width:%d%%"></span>
              <span class="cb-wiki" style="width:%d%%"></span>
              <span class="cb-tkt" style="width:%d%%"></span>
              <span class="cb-forum" style="width:%d%%"></span>
            </div>
            <div class="comp-rows">
              <div class="comp-row"><span class="l"><i class="cb-code"></i>check-ins</span><span>%s</span></div>
              <div class="comp-row"><span class="l"><i class="cb-wiki"></i>wiki edits</span><span>%s</span></div>
              <div class="comp-row"><span class="l"><i class="cb-tkt"></i>ticket changes</span><span>%s</span></div>
              <div class="comp-row"><span class="l"><i class="cb-forum"></i>forum posts</span><span>%s</span></div>
            </div>
            <p class="comp-note">Four kinds of history, one stone — all queried from Fossil at request time.</p>} \
    [::fossilhub::view::percentage $checkins $total] \
    [::fossilhub::view::percentage $wiki $total] \
    [::fossilhub::view::percentage $tickets $total] \
    [::fossilhub::view::percentage $forum $total] \
    [::fossilhub::view::formatCount $checkins] \
    [::fossilhub::view::formatCount $wiki] \
    [::fossilhub::view::formatCount $tickets] \
    [::fossilhub::view::formatCount $forum]]
}

proc ::fossilhub::view::repositoryCard {repository index} {
  set name [::fossilhub::view::escape [dict get $repository name]]
  set description [::fossilhub::view::escape \
    [::fossilhub::view::repositoryDescription $repository]]
  set user "Fossil"
  if {[llength [dict get $repository events]] > 0} {
    set firstUser [dict get [lindex [dict get $repository events] 0] user]
    if {$firstUser ne ""} {
      set user $firstUser
    }
  }
  return [format {
        <a class="rcard reveal" href="repo/%s">
          <div class="holo" aria-hidden="true"></div>
          <span class="glare" aria-hidden="true"></span>
          <div class="card-top"><span class="name">%s</span><span class="spec-tag" aria-hidden="true">&#8470; %03d</span></div>
          <div class="badge-row"><span class="chip chip-azu"><span class="sdot"></span>Fossil</span><span class="chip chip-verdi"><span class="sdot"></span>live SSR</span></div>
          <svg class="core-art" viewBox="0 0 96 128" aria-hidden="true">
            <rect x="18" y="7" width="60" height="114" rx="8" fill="rgba(32,82,151,.06)" stroke="currentColor" stroke-opacity=".28"/>
            <path d="M28 8V120M28 31H78M28 60H78M28 91H78" stroke="currentColor" stroke-opacity=".22"/>
            <path d="M48 18V108C48 114 53 118 59 118" fill="none" stroke="#205297" stroke-width="2"/>
            <circle cx="48" cy="32" r="4" fill="#205297"/><circle cx="48" cy="61" r="4" fill="#2F6E5A"/><circle cx="48" cy="92" r="4" fill="#A64B22"/>
          </svg>
          <svg class="seismo" viewBox="0 0 100 26" preserveAspectRatio="none" aria-hidden="true"><polyline points="0,20 10,17 20,19 30,12 40,15 50,8 60,12 70,6 80,9 100,4"/></svg>
          <p class="desc">%s</p>
          <div class="counts"><span>%s artifacts</span><span>%s wiki</span><span>%s tickets</span><span>%s</span></div>
          <div class="foot"><span class="avatar avatar-sm" aria-hidden="true">%s</span>%s<span class="peers">%s</span></div>
        </a>} \
    [dict get $repository name] \
    $name \
    $index \
    $description \
    [::fossilhub::view::formatCount [dict get $repository artifacts]] \
    [::fossilhub::view::formatCount [dict get $repository wiki_events]] \
    [::fossilhub::view::formatCount [dict get $repository open_tickets]] \
    [::fossilhub::view::escape [::fossilhub::view::relativeTime [dict get $repository latest_epoch]]] \
    [::fossilhub::view::escape [::fossilhub::view::initials $user]] \
    [::fossilhub::view::escape $user] \
    [::fossilhub::view::escape [::fossilhub::view::formatBytes [dict get $repository bytes]]]]
}

proc ::fossilhub::view::featuredRepository {repository} {
  set name [::fossilhub::view::escape [dict get $repository name]]
  set description [::fossilhub::view::escape \
    [::fossilhub::view::repositoryDescription $repository]]
  return [format {
    <a class="feat-card reveal" href="repo/%s">
      <svg class="mini-core" viewBox="0 0 120 190" aria-hidden="true">
        <defs><clipPath id="mcClip"><rect x="8" y="6" width="104" height="178" rx="12"/></clipPath></defs>
        <g clip-path="url(#mcClip)">
          <rect x="8" y="6" width="104" height="42" fill="rgba(32,82,151,.09)"/>
          <rect x="8" y="48" width="104" height="46" fill="rgba(47,110,90,.10)"/>
          <rect x="8" y="94" width="104" height="38" fill="rgba(166,75,34,.07)"/>
          <rect x="8" y="132" width="104" height="52" fill="#DEE1D3"/>
        </g>
        <rect x="8" y="6" width="104" height="178" rx="12" fill="none" stroke="#1C232C" stroke-width="1.5"/>
        <path d="M40 18C39 46 41 74 40 102C39 136 41 160 40 176" fill="none" stroke="rgba(28,35,44,.5)" stroke-width="1.4"/>
        <circle cx="40" cy="34" r="3.6" fill="#205297"/>
        <circle cx="40" cy="72" r="3.6" fill="#2F6E5A"/>
        <circle cx="40" cy="118" r="3.6" fill="#A64B22"/>
        <circle cx="40" cy="156" r="3.6" fill="#F4F5EC" stroke="#1C232C" stroke-width="1.3"/>
      </svg>
      <div>
        <p class="feat-name">%s</p>
        <p class="feat-desc">%s</p>
        <div class="feat-chips">
          <span class="chip chip-azu"><span class="sdot"></span>Fossil repository</span>
          <span class="chip chip-verdi"><span class="sdot"></span>Tcl SSR</span>
          <span class="chip chip-plain"><span class="sdot"></span>one artifact</span>
        </div>
        <p class="feat-metrics"><span>%s artifacts</span><span>%s contributors</span><span>%s check-ins</span></p>
      </div>
      <div class="feat-side">
        <p class="spark-cap">Unified activity · current artifact</p>
        <svg viewBox="0 0 220 64" aria-hidden="true">
          <polyline points="0,50 12,44 24,47 36,38 48,41 60,30 72,34 84,24 96,29 108,18 120,23 132,14 144,20 156,12 168,17 180,9 192,15 204,7 220,11" fill="none" stroke="#205297" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>
          <line x1="0" y1="61" x2="220" y2="61" stroke="rgba(28,35,44,.2)" stroke-width="1"/>
        </svg>
        <p class="last-find">● last find — %s</p>
      </div>
    </a>} \
    [dict get $repository name] \
    $name \
    $description \
    [::fossilhub::view::formatCount [dict get $repository artifacts]] \
    [::fossilhub::view::formatCount [dict get $repository contributors]] \
    [::fossilhub::view::formatCount [dict get $repository checkins]] \
    [::fossilhub::view::escape \
      [::fossilhub::view::relativeTime [dict get $repository latest_epoch]]]]
}

proc ::fossilhub::view::surfaceFeed {repositories} {
  set indexed {}
  foreach repository $repositories {
    foreach event [dict get $repository events] {
      lappend indexed [list [dict get $event epoch] $repository $event]
    }
  }
  set indexed [lrange [lsort -integer -decreasing -index 0 $indexed] 0 11]
  if {[llength $indexed] == 0} {
    return {<span class="pill"><span class="t">—</span><i class="dot dot-hollow"></i>No activity recorded yet</span>}
  }

  set html ""
  foreach item $indexed {
    lassign $item _ repository event
    lassign [::fossilhub::view::eventPresentation [dict get $event type]] label dotClass
    append html [format {
        <a class="pill" href="repo/%s"><span class="t">%s</span><i class="dot %s"></i><b>%s</b>&nbsp;%s · %s</a>} \
      [dict get $repository name] \
      [::fossilhub::view::escape [::fossilhub::view::formatTime [dict get $event epoch]]] \
      $dotClass \
      [::fossilhub::view::escape [dict get $repository name]] \
      [::fossilhub::view::escape $label] \
      [::fossilhub::view::escape [dict get $event comment]]]
  }
  return $html
}

proc ::fossilhub::view::emptyRepository {} {
  return [dict create \
    available 0 \
    name bedrock.fossil \
    slug bedrock \
    path "" \
    bytes 0 \
    project_name "No repositories yet" \
    description "Create a .fossil artifact in the repository directory to begin this dig." \
    project_code "" \
    artifacts 0 \
    checkins 0 \
    wiki_events 0 \
    ticket_events 0 \
    forum_events 0 \
    contributors 0 \
    open_tickets 0 \
    opened_epoch 0 \
    latest_epoch 0 \
    events {}]
}
