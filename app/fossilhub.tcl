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
      source $candidate
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

  if {$clean eq "" || $clean eq $mountName || $clean eq "index"} {
    return home
  }
  if {[regexp {(^|/)healthz$} $clean]} {
    return health
  }
  if {[regexp {(^|/)fh\.css$} $clean]} {
    return stylesheet
  }
  if {[regexp {(^|/)explore/?$} $clean]} {
    return explore
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

  set channel [open $path rb]
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

proc ::fossilhub::placeholder {title message} {
  ::fossilhub::htmlPolicy
  wapp-mimetype text/html
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
      ::fossilhub::placeholder FossilHub "Landing page port in progress."
    }
    explore {
      ::fossilhub::placeholder "Explore digs — FossilHub" "Catalogue port in progress."
    }
    repository {
      ::fossilhub::placeholder "Repository — FossilHub" "Repository view port in progress."
    }
    stylesheet {
      variable ::fossilhub::root
      ::fossilhub::trustedFile \
        [file join $::fossilhub::root public fh.css] \
        text/css \
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

