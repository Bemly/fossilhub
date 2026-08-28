namespace eval ::fossilhub::markup {}

proc ::fossilhub::markup::safeUrl {url} {
  set url [string trim $url]
  if {$url eq "" || [string first "\u0000" $url] >= 0 ||
      [string length [encoding convertto utf-8 $url]] > 1000 ||
      [regexp {[[:cntrl:]]} $url]} {
    return ""
  }
  if {[string match {//*} $url] || [string index $url 0] eq "\\"} {
    return ""
  }
  if {[regexp -nocase {^(https?://|mailto:)} $url] ||
      [string index $url 0] in {/ #} ||
      ![regexp {^[A-Za-z][A-Za-z0-9+.-]*:} $url]} {
    return $url
  }
  return ""
}

proc ::fossilhub::markup::renderInline {text} {
  set result ""
  set remaining $text
  while {[regexp -indices {\[([^\]\r\n]{1,200})\]\(([^)\r\n]+)\)} \
      $remaining match labelIndices urlIndices]} {
    lassign $match start finish
    append result [::fossilhub::view::escape \
      [string range $remaining 0 [expr {$start - 1}]]]
    set label [string range $remaining {*}$labelIndices]
    set url [string range $remaining {*}$urlIndices]
    set safe [::fossilhub::markup::safeUrl $url]
    if {$safe eq ""} {
      append result [::fossilhub::view::escape \
        [string range $remaining $start $finish]]
    } else {
      append result [format {<a href="%s" rel="nofollow noopener">%s</a>} \
        [::fossilhub::view::escape $safe] \
        [::fossilhub::view::escape $label]]
    }
    set remaining [string range $remaining [expr {$finish + 1}] end]
  }
  append result [::fossilhub::view::escape $remaining]
  return $result
}

proc ::fossilhub::markup::flushParagraph {htmlVar paragraphVar} {
  upvar 1 $htmlVar html $paragraphVar paragraph
  if {[llength $paragraph] == 0} {
    return
  }
  append html "<p>[::fossilhub::markup::renderInline [join $paragraph { }]]</p>"
  set paragraph {}
}

proc ::fossilhub::markup::render {content mimetype} {
  if {$mimetype eq "text/plain"} {
    return [format {<div class="rendered-markup"><pre><code>%s</code></pre></div>} \
      [::fossilhub::view::escape $content]]
  }
  set fossilWiki [expr {$mimetype eq "text/x-fossil-wiki"}]
  set html {<div class="rendered-markup">}
  set paragraph {}
  set inCode 0
  set code {}
  set listType ""
  foreach line [split $content "\n"] {
    if {!$fossilWiki && [regexp {^[[:space:]]*```(?:[^`]*)$} $line]} {
      ::fossilhub::markup::flushParagraph html paragraph
      if {$listType ne ""} {
        append html "</${listType}>"
        set listType ""
      }
      if {$inCode} {
        append html [format {<pre><code>%s</code></pre>} \
          [::fossilhub::view::escape [join $code "\n"]]]
        set code {}
        set inCode 0
      } else {
        set inCode 1
      }
      continue
    }
    if {$inCode} {
      lappend code $line
      continue
    }
    set heading 0
    set headingText ""
    if {!$fossilWiki && [regexp {^(#{1,6})[[:space:]]+(.+)$} \
        $line -> hashes headingText]} {
      set heading [string length $hashes]
    } elseif {$fossilWiki && [regexp {^(={1,6})[[:space:]]*(.*?)[[:space:]]*\1$} \
        $line -> equals headingText]} {
      set heading [string length $equals]
    }
    if {$heading > 0} {
      ::fossilhub::markup::flushParagraph html paragraph
      if {$listType ne ""} {
        append html "</${listType}>"
        set listType ""
      }
      append html [format {<h%d>%s</h%d>} $heading \
        [::fossilhub::markup::renderInline $headingText] $heading]
      continue
    }
    if {[regexp {^[[:space:]]*[-*+][[:space:]]+(.+)$} $line -> item]} {
      ::fossilhub::markup::flushParagraph html paragraph
      if {$listType ne "ul"} {
        if {$listType ne ""} {
          append html "</${listType}>"
        }
        append html <ul>
        set listType ul
      }
      append html "<li>[::fossilhub::markup::renderInline $item]</li>"
      continue
    }
    if {[regexp {^[[:space:]]*[0-9]+\.[[:space:]]+(.+)$} $line -> item]} {
      ::fossilhub::markup::flushParagraph html paragraph
      if {$listType ne "ol"} {
        if {$listType ne ""} {
          append html "</${listType}>"
        }
        append html <ol>
        set listType ol
      }
      append html "<li>[::fossilhub::markup::renderInline $item]</li>"
      continue
    }
    if {$listType ne ""} {
      append html "</${listType}>"
      set listType ""
    }
    if {[regexp {^[[:space:]]*>[[:space:]]?(.*)$} $line -> quote]} {
      ::fossilhub::markup::flushParagraph html paragraph
      append html "<blockquote><p>[::fossilhub::markup::renderInline $quote]</p></blockquote>"
      continue
    }
    if {[string trim $line] eq ""} {
      ::fossilhub::markup::flushParagraph html paragraph
    } else {
      lappend paragraph [string trim $line]
    }
  }
  if {$inCode} {
    append html [format {<pre><code>%s</code></pre>} \
      [::fossilhub::view::escape [join $code "\n"]]]
  }
  ::fossilhub::markup::flushParagraph html paragraph
  if {$listType ne ""} {
    append html "</${listType}>"
  }
  append html </div>
  return $html
}
