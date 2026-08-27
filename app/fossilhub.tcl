#!/usr/bin/env tclsh

namespace eval ::fossilhub {
  variable root [file dirname [file normalize [info script]]]
  variable mountName "fossilhub"
}

foreach sourceFile {
  lib/fossil-model.tcl
  lib/view.tcl
  views/home.tcl
  views/explore.tcl
  views/repository.tcl
} {
  source [file join $::fossilhub::root $sourceFile]
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

  if {$clean eq "" || $clean eq $mountName ||
      [regexp [format {(^|/)%s$} $mountName] $clean] ||
      $clean eq "index" ||
      [regexp {(^|/)index\.html$} $clean]} {
    return home
  }
  if {[regexp {(^|/)healthz$} $clean]} {
    return health
  }
  if {[regexp {(^|/)fh\.css$} $clean]} {
    return stylesheet
  }
  if {[regexp {(^|/)fossilhub-live\.js$} $clean]} {
    return live-script
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

proc ::fossilhub::renderPage {content} {
  ::fossilhub::htmlPolicy
  wapp-mimetype "text/html; charset=utf-8"
  wapp-cache-control no-cache
  wapp-unsafe $content
}

proc ::fossilhub::catalog {{eventLimit 8}} {
  return [::fossilhub::model::catalogRepositories $eventLimit]
}

proc ::fossilhub::primaryRepository {} {
  set repositories [::fossilhub::catalog 5]
  if {[llength $repositories] == 0} {
    return [::fossilhub::view::emptyRepository]
  }
  return [lindex $repositories 0]
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
      ::fossilhub::renderPage [::fossilhub::views::renderHome \
        [::fossilhub::primaryRepository]]
    }
    explore {
      ::fossilhub::renderPage [::fossilhub::views::renderExplore \
        [::fossilhub::catalog 8]]
    }
    repository {
      set name [lindex $route 1]
      if {![::fossilhub::model::validRepositoryName $name] ||
          ![file isfile [::fossilhub::model::repositoryPath $name]]} {
        wapp-reply-code "404 Not Found"
        ::fossilhub::placeholder \
          "Repository not found — FossilHub" \
          "That repository is not in this dig."
      } elseif {[catch {
        set repository [::fossilhub::model::repository $name 40]
      }]} {
        wapp-reply-code "503 Service Unavailable"
        ::fossilhub::placeholder \
          "Repository unavailable — FossilHub" \
          "Fossil could not read this stratum. Try again shortly."
      } else {
        ::fossilhub::renderPage \
          [::fossilhub::views::renderRepository $repository]
      }
    }
    stylesheet {
      variable ::fossilhub::root
      ::fossilhub::trustedFile \
        [file join $::fossilhub::root public fh.css] \
        "text/css; charset=utf-8" \
        max-age=3600
    }
    live-script {
      variable ::fossilhub::root
      ::fossilhub::trustedFile \
        [file join $::fossilhub::root public fossilhub-live.js] \
        "text/javascript; charset=utf-8" \
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
