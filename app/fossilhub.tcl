#!/usr/bin/env tclsh

namespace eval ::fossilhub {
  variable root [file dirname [file normalize [info script]]]
  variable mountName "fossilhub"
}

proc ::fossilhub::loadWapp {} {
  variable root
  set candidates [list \
    [file normalize [file join $root .. vendor wapp wapp.tcl]] \
    /opt/fossilhub/wapp.tcl]

  foreach candidate $candidates {
    if {[file isfile $candidate]} {
      uplevel #0 [list source $candidate]
      return
    }
  }
  error "unable to locate the vendored Wapp runtime"
}

::fossilhub::loadWapp

proc ::fossilhub::requestPath {} {
  set uri [wapp-param REQUEST_URI /]
  regsub {\?.*$} $uri {} uri
  if {$uri eq ""} {
    return /
  }
  return $uri
}

proc ::fossilhub::routeForPath {path} {
  variable mountName
  set clean [string trim $path /]

  if {$clean eq "" || $clean eq $mountName || $clean eq "index" ||
      [regexp {(^|/)index\.html$} $clean]} {
    return home
  }
  if {[regexp {(^|/)healthz$} $clean]} {
    return health
  }
  if {[regexp {(^|/)fh\.css$} $clean]} {
    return stylesheet
  }
  if {[regexp {(^|/)explore(?:\.html)?/?$} $clean]} {
    return explore
  }
  if {[regexp {(^|/)repo\.html$} $clean]} {
    return [list repository dig.fossil]
  }
  if {[regexp {(^|/)repo/([^/]+)/?$} $clean -> _ repository]} {
    return [list repository $repository]
  }
  return not-found
}

proc ::fossilhub::trustedFile {path mime cache} {
  if {![file isfile $path]} {
    wapp-reply-code "404 Not Found"
    wapp-mimetype text/plain
    wapp-subst {Not found\n}
    return
  }

  set channel [open $path r]
  fconfigure $channel -encoding utf-8 -translation lf
  try {
    set content [read $channel]
  } finally {
    close $channel
  }
  wapp-mimetype $mime
  wapp-cache-control $cache
  wapp-unsafe $content
}

proc ::fossilhub::htmlPolicy {} {
  wapp-content-security-policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; base-uri 'self'; frame-ancestors 'self'"
}

proc ::fossilhub::templatePage {filename} {
  variable root
  ::fossilhub::htmlPolicy
  ::fossilhub::trustedFile \
    [file join $root templates $filename] \
    "text/html; charset=utf-8" \
    no-cache
}

proc ::fossilhub::placeholder {title message} {
  ::fossilhub::htmlPolicy
  wapp-mimetype "text/html; charset=utf-8"
  wapp-cache-control no-cache
  wapp-trim {
    <!doctype html>
    <html lang="en">
    <head><meta charset="utf-8"><title>%html($title)</title></head>
    <body><main><h1>%html($title)</h1><p>%html($message)</p></main></body>
    </html>
  }
}

proc wapp-default {} {
  set route [::fossilhub::routeForPath [::fossilhub::requestPath]]
  switch -- [lindex $route 0] {
    health {
      wapp-mimetype text/plain
      wapp-cache-control no-cache
      wapp-subst {ok\n}
    }
    home {
      ::fossilhub::templatePage fossilhub.html
    }
    explore {
      ::fossilhub::templatePage explore.html
    }
    repository {
      if {[lindex $route 1] ne "dig.fossil"} {
        wapp-reply-code "404 Not Found"
        ::fossilhub::placeholder \
          "Repository not found — FossilHub" \
          "That repository is not in this dig."
      } else {
        ::fossilhub::templatePage repo.html
      }
    }
    stylesheet {
      variable ::fossilhub::root
      ::fossilhub::trustedFile \
        [file join $::fossilhub::root public fh.css] \
        "text/css; charset=utf-8" \
        max-age=3600
    }
    default {
      wapp-reply-code "404 Not Found"
      ::fossilhub::placeholder "Not found — FossilHub" "That layer is not in this dig."
    }
  }
}

if {[file normalize [info script]] eq [file normalize $::argv0]} {
  wapp-start $::argv
}
