#!/usr/bin/env tclsh

namespace eval ::fossilhub {
  variable root [file dirname [file normalize [info script]]]
  variable mountName "fossilhub"
}

foreach sourceFile {
  lib/repository-manifest.tcl
  lib/fossil-model.tcl
  lib/catalog-model.tcl
  lib/view.tcl
  views/home.tcl
  views/explore.tcl
  views/repository-sections.tcl
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
  if {[regexp {(^|/)catalog-search\.js$} $clean]} {
    return catalog-script
  }
  if {[regexp {(^|/)catalog-fragment$} $clean]} {
    return catalog-fragment
  }
  if {[regexp {(^|/)explore(?:\.html)?/?$} $clean]} {
    return explore
  }
  if {[regexp {(^|/)repo\.html$} $clean]} {
    return [list repository bedrock.fossil timeline]
  }
  if {[regexp {(^|/)repo/([^/]+)/(file|wiki-page)/([[:xdigit:]]{10,64})/?$} \
      $clean -> _ repository section artifactId]} {
    return [list repository $repository $section $artifactId]
  }
  if {[regexp {(^|/)repo/([^/]+)/(timeline|files|docs|wiki|tickets|forum)/?$} \
      $clean -> _ repository section]} {
    return [list repository $repository $section]
  }
  if {[regexp {(^|/)repo/([^/]+)/?$} $clean -> _ repository]} {
    return [list repository $repository timeline]
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

proc ::fossilhub::catalogOptions {} {
  return [::fossilhub::catalog::searchOptions [dict create \
    q [wapp-param q ""] \
    kind [wapp-param kind all] \
    sort [wapp-param sort recent] \
    limit 100]]
}

proc ::fossilhub::primaryRepository {} {
  set repositories [::fossilhub::catalog::repositories \
    [dict create limit 1]]
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

proc ::fossilhub::repositorySectionData {repository section route} {
  set name [dict get $repository name]
  switch -- $section {
    timeline {
      set filter [wapp-param event all]
      if {$filter ni {all ci w t f}} {
        set filter all
      }
      if {$filter ne "all"} {
        set events {}
        foreach event [dict get $repository events] {
          if {[dict get $event type] eq $filter} {
            lappend events $event
          }
        }
        dict set repository events $events
      }
      return [dict create repository $repository event_filter $filter]
    }
    files {
      return [dict create files [::fossilhub::model::files $name]]
    }
    docs {
      return [dict create files \
        [::fossilhub::model::documentationFiles $name]]
    }
    file {
      return [dict create file [::fossilhub::model::fileRecord \
        $name [lindex $route 3]]]
    }
    wiki {
      return [dict create pages [::fossilhub::model::wikiPages $name]]
    }
    wiki-page {
      return [dict create page [::fossilhub::model::wikiContent \
        $name [lindex $route 3]]]
    }
    tickets {
      return [dict create tickets [::fossilhub::model::tickets $name]]
    }
    forum {
      return [dict create posts [::fossilhub::model::forumPosts $name]]
    }
    default {
      error "unknown repository section"
    }
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
      set options [::fossilhub::catalogOptions]
      ::fossilhub::renderPage [::fossilhub::views::renderExplore \
        [::fossilhub::catalog::repositories $options] $options]
    }
    catalog-fragment {
      set options [::fossilhub::catalogOptions]
      ::fossilhub::htmlPolicy
      wapp-mimetype "text/html; charset=utf-8"
      wapp-cache-control no-cache
      wapp-unsafe [::fossilhub::views::renderExploreResults \
        [::fossilhub::catalog::repositories $options]]
    }
    repository {
      set name [lindex $route 1]
      set section [lindex $route 2]
      if {![::fossilhub::manifest::contains $name] ||
          ![::fossilhub::model::validRepositoryName $name] ||
          ![file isfile [::fossilhub::model::repositoryPath $name]]} {
        wapp-reply-code "404 Not Found"
        ::fossilhub::placeholder \
          "Repository not found — FossilHub" \
          "That repository is not in this dig."
      } elseif {[catch {
        set repository [::fossilhub::model::repository $name 200]
        set sectionData [::fossilhub::repositorySectionData \
          $repository $section $route]
      } message]} {
        puts stderr "FossilHub: repository request failed for [file tail $name]: $message"
        wapp-reply-code "503 Service Unavailable"
        ::fossilhub::placeholder \
          "Repository unavailable — FossilHub" \
          "Fossil could not read this stratum. Try again shortly."
      } else {
        ::fossilhub::renderPage \
          [::fossilhub::views::renderRepository \
            $repository $section $sectionData]
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
    catalog-script {
      variable ::fossilhub::root
      ::fossilhub::trustedFile \
        [file join $::fossilhub::root public catalog-search.js] \
        "text/javascript; charset=utf-8" \
        max-age=3600
    }
    default {
      wapp-reply-code "404 Not Found"
      ::fossilhub::placeholder "Not found — FossilHub" "That layer is not in this dig."
    }
  }
}

proc wapp-before-dispatch-hook {} {
  wapp-allow-xorigin-params
}

if {[file normalize [info script]] eq [file normalize $::argv0]} {
  wapp-start $::argv
}
