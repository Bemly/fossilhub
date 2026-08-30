#!/usr/bin/env tclsh

namespace eval ::fossilhub {
  variable root [file dirname [file normalize [info script]]]
  variable mountName "fossilhub"
}

foreach sourceFile {
  lib/repository-manifest.tcl
  lib/fossil-model.tcl
  lib/history-model.tcl
  lib/platform-model.tcl
  lib/auth-model.tcl
  lib/i18n.tcl
  lib/catalog-model.tcl
  lib/repository-service.tcl
  lib/workspace-model.tcl
  lib/admin-model.tcl
  lib/mutation-service.tcl
  lib/view.tcl
  lib/markup.tcl
  views/home.tcl
  views/explore.tcl
  views/repository-sections.tcl
  views/repository.tcl
  views/account.tcl
  views/admin.tcl
  views/public.tcl
  views/repository-management.tcl
  views/mutations.tcl
  lib/account-controller.tcl
  lib/admin-controller.tcl
  lib/repository-controller.tcl
  lib/mutation-controller.tcl
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
  if {[regexp {(^|/)fossilhub-hub-lockup-v1\.png$} $clean]} {
    return brand-lockup
  }
  if {[regexp {(^|/)catalog-fragment$} $clean]} {
    return catalog-fragment
  }
  if {[regexp {(^|/)locale/?$} $clean]} {
    return locale
  }
  if {[regexp {(^|/)login/?$} $clean]} {
    return login
  }
  if {[regexp {(^|/)register/?$} $clean]} {
    return register
  }
  if {[regexp {(^|/)logout/?$} $clean]} {
    return logout
  }
  if {[regexp {(^|/)dashboard/?$} $clean]} {
    return dashboard
  }
  if {![regexp {(^|/)admin/} $clean] &&
      [regexp {(^|/)users/([a-z0-9](?:[a-z0-9-]{0,37}[a-z0-9])?)/?$} \
      $clean -> _ username]} {
    return [list public-profile $username]
  }
  if {[regexp {(^|/)account/security/?$} $clean]} {
    return account-security
  }
  if {[regexp {(^|/)account/session/revoke/?$} $clean]} {
    return account-session-revoke
  }
  if {[regexp {(^|/)account/repositories/new/?$} $clean]} {
    return repository-new
  }
  if {[regexp {(^|/)repositories/new/?$} $clean]} {
    return repository-new
  }
  if {[regexp {(^|/)account/repositories/([^/]+)/(member-remove|member|transfer|archive|restore)/?$} \
      $clean -> _ slug action]} {
    return [list repository-management-action $slug $action]
  }
  if {[regexp {(^|/)account/repositories/([^/]+)/settings/?$} \
      $clean -> _ slug]} {
    return [list repository-settings $slug]
  }
  if {[regexp {(^|/)account/repositories/?$} $clean]} {
    return repository-workspace
  }
  if {![regexp {(^|/)admin/} $clean] &&
      ([regexp {(^|/)settings/?$} $clean] ||
      [regexp {(^|/)settings/profile/?$} $clean])} {
    return account-settings
  }
  if {[regexp {(^|/)settings/security/?$} $clean]} {
    return account-security
  }
  if {[regexp {(^|/)settings/session/revoke/?$} $clean]} {
    return account-session-revoke
  }
  if {[regexp {(^|/)settings/deactivate/?$} $clean]} {
    return account-deactivate
  }
  if {[regexp {(^|/)admin/reauth/?$} $clean]} {
    return admin-reauth
  }
  if {[regexp {(^|/)admin/users/([[:xdigit:]]{32})/(role|status|sessions)/?$} \
      $clean -> _ id action]} {
    return [list admin-user-action $id $action]
  }
  if {[regexp {(^|/)admin/users/([[:xdigit:]]{32})/?$} $clean -> _ id]} {
    return [list admin-user $id]
  }
  if {[regexp {(^|/)admin/users/?$} $clean]} {
    return admin-users
  }
  if {[regexp {(^|/)admin/repositories/([a-z0-9](?:[a-z0-9-]{0,37}[a-z0-9])?)/(archive|restore|integrity)/?$} \
      $clean -> _ slug action]} {
    return [list admin-repository-action $slug $action]
  }
  if {[regexp {(^|/)admin/repositories/([a-z0-9](?:[a-z0-9-]{0,37}[a-z0-9])?)/?$} \
      $clean -> _ slug]} {
    return [list admin-repository $slug]
  }
  if {[regexp {(^|/)admin/repositories/?$} $clean]} {
    return admin-repositories
  }
  if {[regexp {(^|/)admin/audit\.csv$} $clean]} {
    return admin-audit-export
  }
  if {[regexp {(^|/)admin/audit/?$} $clean]} {
    return admin-audit
  }
  if {[regexp {(^|/)admin/health/reindex/?$} $clean]} {
    return admin-reindex
  }
  if {[regexp {(^|/)admin/health/?$} $clean]} {
    return admin-health
  }
  if {[regexp {(^|/)admin/settings/?$} $clean]} {
    return admin-settings
  }
  if {[regexp {(^|/)admin/?$} $clean]} {
    return admin-overview
  }
  if {[regexp {(^|/)(manual|hosting|upstream|releases|rules|status|privacy|security|contact)/?$} \
      $clean -> _ page]} {
    return [list public-information $page]
  }
  if {[regexp {(^|/)explore(?:\.html)?/?$} $clean]} {
    return explore
  }
  if {[regexp {(^|/)repo\.html$} $clean]} {
    return [list repository bedrock.fossil timeline]
  }
  if {[regexp {(^|/)repo/([^/]+)/files/new/?$} \
      $clean -> _ repository]} {
    return [list repository-mutation $repository file-new]
  }
  if {[regexp {(^|/)repo/([^/]+)/file/([[:xdigit:]]{10,64})/edit/?$} \
      $clean -> _ repository artifactId]} {
    return [list repository-mutation $repository file-edit $artifactId]
  }
  if {[regexp {(^|/)repo/([^/]+)/wiki/new/?$} \
      $clean -> _ repository]} {
    return [list repository-mutation $repository wiki-new]
  }
  if {[regexp {(^|/)repo/([^/]+)/wiki-page/([[:xdigit:]]{10,64})/edit/?$} \
      $clean -> _ repository artifactId]} {
    return [list repository-mutation $repository wiki-edit $artifactId]
  }
  if {[regexp {(^|/)repo/([^/]+)/tickets/new/?$} \
      $clean -> _ repository]} {
    return [list repository-mutation $repository ticket-new]
  }
  if {[regexp {(^|/)repo/([^/]+)/ticket/([[:xdigit:]]{40,64})/manage/?$} \
      $clean -> _ repository ticketId]} {
    return [list repository-mutation $repository ticket $ticketId]
  }
  if {[regexp {(^|/)repo/([^/]+)/ticket/([[:xdigit:]]{40,64})/?$} \
      $clean -> _ repository ticketId]} {
    return [list repository-ticket $repository $ticketId]
  }
  if {[regexp {(^|/)repo/([^/]+)/forum/new/?$} \
      $clean -> _ repository]} {
    return [list repository-mutation $repository forum-new]
  }
  if {[regexp {(^|/)repo/([^/]+)/forum/([[:xdigit:]]{10,64})/reply/?$} \
      $clean -> _ repository postId]} {
    return [list repository-mutation $repository forum-reply $postId]
  }
  if {[regexp {(^|/)repo/([^/]+)/archive/([[:xdigit:]]{10,64})\.zip$} \
      $clean -> _ repository revision]} {
    return [list repository $repository archive $revision]
  }
  if {[regexp {(^|/)repo/([^/]+)/(tree|checkin)/([[:xdigit:]]{10,64})/?$} \
      $clean -> _ repository section revision]} {
    return [list repository $repository $section $revision]
  }
  if {[regexp {(^|/)repo/([^/]+)/(blob|raw|history|blame|doc)/([[:xdigit:]]{10,64})/([[:xdigit:]]{10,64})/?$} \
      $clean -> _ repository section revision artifactId]} {
    return [list repository $repository $section $revision $artifactId]
  }
  if {[regexp {(^|/)repo/([^/]+)/wiki-revision/([[:xdigit:]]{10,64})/(history)/?$} \
      $clean -> _ repository revision section]} {
    return [list repository $repository wiki-history $revision]
  }
  if {[regexp {(^|/)repo/([^/]+)/wiki-revision/([[:xdigit:]]{10,64})/?$} \
      $clean -> _ repository revision]} {
    return [list repository $repository wiki-revision $revision]
  }
  if {[regexp {(^|/)repo/([^/]+)/wiki-compare/([[:xdigit:]]{10,64})/([[:xdigit:]]{10,64})/?$} \
      $clean -> _ repository before after]} {
    return [list repository $repository wiki-compare $before $after]
  }
  if {[regexp {(^|/)repo/([^/]+)/discussion/([[:xdigit:]]{10,64})/?$} \
      $clean -> _ repository revision]} {
    return [list repository $repository discussion $revision]
  }
  if {[regexp {(^|/)repo/([^/]+)/(file|wiki-page)/([[:xdigit:]]{10,64})/?$} \
      $clean -> _ repository section artifactId]} {
    return [list repository $repository $section $artifactId]
  }
  if {[regexp {(^|/)repo/([^/]+)/(timeline|files|docs|wiki|tickets|forum|branches|tags|stats)/?$} \
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

proc ::fossilhub::trustedBinaryFile {path mime cache} {
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
  wapp-content-security-policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; form-action 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'"
  wapp-reply-extra X-Content-Type-Options nosniff
  wapp-reply-extra Referrer-Policy strict-origin-when-cross-origin
  wapp-reply-extra Permissions-Policy \
    {camera=(), microphone=(), geolocation=(), payment=(), usb=()}
  set forwarded [wapp-param HTTP_X_FORWARDED_PROTO ""]
  if {$forwarded eq ""} {
    set forwarded [wapp-param {.hdr:X-FORWARDED-PROTO} ""]
  }
  set forwarded [string tolower $forwarded]
  if {[string tolower [wapp-param HTTPS ""]] in {on 1 true} ||
      [lindex [split $forwarded ,] 0] eq "https"} {
    wapp-reply-extra Strict-Transport-Security {max-age=31536000}
  }
}

proc ::fossilhub::renderPage {content} {
  ::fossilhub::htmlPolicy
  wapp-mimetype "text/html; charset=utf-8"
  wapp-cache-control no-cache
  wapp-unsafe [::fossilhub::decoratePage $content]
}

proc ::fossilhub::requestUri {} {
  set uri [wapp-param REQUEST_URI /]
  return [::fossilhub::i18n::returnTo $uri]
}

proc ::fossilhub::handleLocale {} {
  if {[string toupper [wapp-param REQUEST_METHOD GET]] ne "POST"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Language changes accept POST requests only.}
    return
  }
  set locale [::fossilhub::i18n::normalize [wapp-param locale ""]]
  if {$locale eq ""} {
    wapp-reply-code "400 Bad Request"
    ::fossilhub::placeholder {Invalid language — FossilHub} \
      {Choose English or Simplified Chinese.}
    return
  }
  ::fossilhub::account::setLocaleCookie $locale
  wapp-redirect [::fossilhub::i18n::returnTo [wapp-param return_to /]]
}

proc ::fossilhub::maintenanceBanner {} {
  if {![file isfile [::fossilhub::platform::databasePath]]} {
    return ""
  }
  return [::fossilhub::platform::setting maintenance_banner ""]
}

proc ::fossilhub::decoratePage {content} {
  set banner [::fossilhub::maintenanceBanner]
  if {$banner eq ""} {
    return $content
  }
  set body [string first {<body} $content]
  if {$body < 0} {
    return $content
  }
  set finish [string first > $content $body]
  if {$finish < 0} {
    return $content
  }
  set notice [format {<div class="maintenance-banner" role="status"><b>%s</b><span>%s</span></div>} \
    [::fossilhub::view::escape [::fossilhub::i18n::t maintenance_notice]] \
    [::fossilhub::view::escape $banner]]
  return [string replace $content $finish $finish ">$notice"]
}

proc ::fossilhub::version {} {
  if {[info exists ::env(FOSSILHUB_VERSION)] &&
      [regexp {^[A-Za-z0-9._-]{1,80}$} $::env(FOSSILHUB_VERSION)]} {
    return $::env(FOSSILHUB_VERSION)
  }
  variable root
  set candidate [file normalize [file join $root .. VERSION]]
  if {[file isfile $candidate]} {
    set channel [open $candidate r]
    try {
      set value [string trim [read $channel 100]]
    } finally {
      close $channel
    }
    if {[regexp {^[A-Za-z0-9._-]{1,80}$} $value]} {
      return $value
    }
  }
  return development
}

proc ::fossilhub::releaseNotes {} {
  variable root
  foreach candidate [list \
      [file normalize [file join $root .. docs releases.md]] \
      /opt/fossilhub/releases.md] {
    if {[file isfile $candidate]} {
      set channel [open $candidate r]
      fconfigure $channel -encoding utf-8 -translation lf
      try {
        return [read $channel]
      } finally {
        close $channel
      }
    }
  }
  return {# Release notes unavailable

The maintained release document is not present in this runtime image.}
}

proc ::fossilhub::handlePublicInformation {context slug} {
  if {[string toupper [wapp-param REQUEST_METHOD GET]] ne "GET"} {
    wapp-reply-code "405 Method Not Allowed"
    ::fossilhub::placeholder {Method not allowed — FossilHub} \
      {Information pages are read-only.}
    return
  }
  set context [::fossilhub::account::withLogoutChallenge $context]
  if {$slug eq "releases"} {
    set page [::fossilhub::views::renderReleases $context \
      [::fossilhub::releaseNotes] [::fossilhub::version]]
  } elseif {$slug eq "status"} {
    set page [::fossilhub::views::renderPublicStatus $context \
      [::fossilhub::admin::health] [::fossilhub::version] \
      [::fossilhub::maintenanceBanner]]
  } else {
    set definition [::fossilhub::views::publicDefinition $slug]
    if {$definition eq ""} {
      wapp-reply-code "404 Not Found"
      ::fossilhub::placeholder {Not found — FossilHub} \
        {That information layer is unavailable.}
      return
    }
    set page [::fossilhub::views::renderPublicInformation \
      $context $slug $definition]
  }
  ::fossilhub::renderPage $page
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

proc ::fossilhub::publishedRepository {name} {
  if {[file isfile [::fossilhub::platform::databasePath]]} {
    return [::fossilhub::platform::publicContains $name]
  }
  return [::fossilhub::manifest::contains $name]
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

proc ::fossilhub::dateFilterEpoch {value endOfDay} {
  set value [string trim $value]
  if {$value eq ""} {
    return ""
  }
  if {![regexp {^[0-9]{4}-[0-9]{2}-[0-9]{2}$} $value] ||
      [catch {set epoch [clock scan $value -format %Y-%m-%d]}]} {
    error "invalid timeline date"
  }
  if {$endOfDay} {
    incr epoch 86399
  }
  return $epoch
}

proc ::fossilhub::timelineRequestOptions {} {
  set fromDate [string range [wapp-param from ""] 0 10]
  set toDate [string range [wapp-param to ""] 0 10]
  return [dict create \
    q [string range [wapp-param q ""] 0 200] \
    type [string range [wapp-param event all] 0 12] \
    author [string range [wapp-param author ""] 0 160] \
    branch [string range [wapp-param branch ""] 0 160] \
    tag [string range [wapp-param tag ""] 0 160] \
    from [::fossilhub::dateFilterEpoch $fromDate 0] \
    to [::fossilhub::dateFilterEpoch $toDate 1] \
    from_date $fromDate to_date $toDate \
    cursor [string range [wapp-param cursor ""] 0 64] limit 30]
}

proc ::fossilhub::defaultCheckin {repository registry} {
  set branch [dict get $registry default_branch]
  if {[catch {set checkin [::fossilhub::history::branchHead \
      [dict get $repository name] $branch]}]} {
    set events [dict get [::fossilhub::history::timeline \
      [dict get $repository name] [dict create type ci limit 1]] events]
    if {[llength $events] == 0} {
      error "repository has no check-in"
    }
    set checkin [::fossilhub::history::resolveCheckin \
      [dict get $repository name] [dict get [lindex $events 0] uuid]]
    dict set checkin branch $branch
  }
  return $checkin
}

proc ::fossilhub::repositorySectionData {repository registry section route} {
  set name [dict get $repository name]
  switch -- $section {
    timeline {
      set requestOptions [::fossilhub::timelineRequestOptions]
      set historyOptions [dict remove $requestOptions from_date to_date]
      return [dict create timeline [::fossilhub::history::timeline \
        $name $historyOptions] request_options $requestOptions \
        branches [::fossilhub::history::branches $name] \
        tags [::fossilhub::history::tags $name]]
    }
    files {
      set checkin [::fossilhub::defaultCheckin $repository $registry]
      return [dict create tree [::fossilhub::history::tree \
        $name [dict get $checkin uuid]] branches \
        [::fossilhub::history::branches $name]]
    }
    tree {
      return [dict create tree [::fossilhub::history::tree $name \
        [lindex $route 3] [string range [wapp-param path ""] 0 512]] \
        branches [::fossilhub::history::branches $name]]
    }
    docs {
      set requested [string range [wapp-param revision ""] 0 64]
      if {$requested eq ""} {
        set requested [dict get [::fossilhub::defaultCheckin \
          $repository $registry] uuid]
      }
      return [dict create documentation \
        [::fossilhub::history::documentationAtRevision $name $requested] \
        branches [::fossilhub::history::branches $name]]
    }
    file {
      return [dict create file [::fossilhub::model::fileRecord \
        $name [lindex $route 3]]]
    }
    blob - doc {
      return [dict create file [::fossilhub::history::fileAtRevision \
        $name [lindex $route 3] [lindex $route 4]]]
    }
    history {
      return [::fossilhub::history::fileHistory $name \
        [lindex $route 3] [lindex $route 4]]
    }
    blame {
      return [::fossilhub::history::blame $name \
        [lindex $route 3] [lindex $route 4]]
    }
    checkin {
      set checkin [::fossilhub::history::checkin $name [lindex $route 3]]
      return [dict create checkin $checkin diff \
        [::fossilhub::history::checkinDiff $name [dict get $checkin uuid]]]
    }
    branches {
      return [dict create branches [::fossilhub::history::branches $name]]
    }
    tags {
      return [dict create tags [::fossilhub::history::tags $name]]
    }
    stats {
      set head [::fossilhub::defaultCheckin $repository $registry]
      return [dict create statistics [::fossilhub::history::statistics $name] \
        checkin $head]
    }
    wiki {
      return [dict create pages [::fossilhub::model::wikiPages $name]]
    }
    wiki-page {
      set page [::fossilhub::history::wikiArtifact $name [lindex $route 3]]
      set history [::fossilhub::history::wikiHistory $name [dict get $page title]]
      dict set page latest [expr {[llength $history] > 0 && [string equal -nocase \
        [dict get $page uuid] [dict get [lindex $history 0] uuid]]}]
      return [dict create page $page]
    }
    wiki-revision {
      set page [::fossilhub::history::wikiArtifact $name [lindex $route 3]]
      set history [::fossilhub::history::wikiHistory $name [dict get $page title]]
      dict set page latest [expr {[llength $history] > 0 && [string equal -nocase \
        [dict get $page uuid] [dict get [lindex $history 0] uuid]]}]
      return [dict create page $page]
    }
    wiki-history {
      set page [::fossilhub::history::wikiArtifact $name [lindex $route 3]]
      return [dict create page $page history [::fossilhub::history::wikiHistory \
        $name [dict get $page title]]]
    }
    wiki-compare {
      return [::fossilhub::history::wikiComparison $name \
        [lindex $route 3] [lindex $route 4]]
    }
    tickets {
      return [dict create tickets [::fossilhub::model::tickets $name]]
    }
    ticket-detail {
      return [dict create ticket [::fossilhub::history::ticket \
        $name [lindex $route 3]]]
    }
    forum {
      return [dict create threads [::fossilhub::history::forumThreads $name]]
    }
    discussion {
      return [dict create thread [::fossilhub::history::forumThread \
        $name [lindex $route 3]]]
    }
    default {
      error "unknown repository section"
    }
  }
}

proc ::fossilhub::downloadName {filename fallback} {
  set filename [file tail $filename]
  regsub -all {[^A-Za-z0-9._-]} $filename _ filename
  if {$filename eq "" || $filename in {. ..}} {
    return $fallback
  }
  return [string range $filename 0 180]
}

proc ::fossilhub::serveRawFile {name revision artifactId} {
  set file [::fossilhub::history::rawFile $name $revision $artifactId]
  set filename [::fossilhub::downloadName [dict get $file filename] \
    "artifact-[string range [dict get $file uuid] 0 11]"]
  wapp-mimetype application/octet-stream
  wapp-cache-control {no-store, private}
  wapp-reply-extra X-Content-Type-Options nosniff
  wapp-reply-extra Content-Disposition "attachment; filename=\"$filename\""
  wapp-unsafe [dict get $file content]
}

proc ::fossilhub::serveArchive {name revision} {
  set archive [::fossilhub::history::createArchive $name $revision]
  set path [dict get $archive path]
  try {
    set channel [open $path rb]
    try {
      set content [read $channel]
    } finally {
      close $channel
    }
    set filename [::fossilhub::downloadName [dict get $archive filename] \
      repository.zip]
    wapp-mimetype application/zip
    wapp-cache-control {no-store, private}
    wapp-reply-extra X-Content-Type-Options nosniff
    wapp-reply-extra Content-Disposition "attachment; filename=\"$filename\""
    wapp-unsafe $content
  } finally {
    ::fossilhub::history::deleteArchive $path
  }
}

proc ::fossilhub::handleRepositoryRead {accountContext route} {
  set name [lindex $route 1]
  set section [lindex $route 2]
  set registry ""
  if {[::fossilhub::model::validRepositoryName $name]} {
    set registry [::fossilhub::repositories::byName $name]
  }
  if {$registry eq "" ||
      ![::fossilhub::repositories::allows $registry $accountContext read] ||
      ![file isfile [::fossilhub::model::repositoryPath $name]]} {
    wapp-reply-code "404 Not Found"
    ::fossilhub::placeholder \
      "Repository not found — FossilHub" \
      "That repository is not in this dig."
    return
  }
  if {$section in {raw archive}} {
    if {[catch {
      if {$section eq "raw"} {
        ::fossilhub::serveRawFile $name [lindex $route 3] [lindex $route 4]
      } else {
        ::fossilhub::serveArchive $name [lindex $route 3]
      }
    }]} {
      puts stderr "FossilHub: repository download failed for [file tail $name]"
      wapp-reply-code "503 Service Unavailable"
      ::fossilhub::placeholder \
        "Repository download unavailable — FossilHub" \
        "Fossil could not prepare this download. Try again shortly."
    }
    return
  }
  if {[catch {
    set repository [::fossilhub::model::repository $name 40]
    dict set repository project_name [dict get $registry title]
    dict set repository description [dict get $registry description]
    dict set repository visibility [dict get $registry visibility]
    set sectionData [::fossilhub::repositorySectionData \
      $repository $registry $section $route]
    dict set sectionData can_write [::fossilhub::repositories::allows \
      $registry $accountContext write]
    dict set sectionData can_triage [::fossilhub::repositories::allows \
      $registry $accountContext triage]
  } readError]} {
    puts stderr "FossilHub: first-party repository read failed for [file tail $name]"
    if {[regexp -nocase {invalid|not found|ambiguous|required} $readError]} {
      wapp-reply-code "404 Not Found"
      ::fossilhub::placeholder \
        "Repository artifact not found — FossilHub" \
        "That artifact is not present in this stratum."
    } else {
      wapp-reply-code "503 Service Unavailable"
      ::fossilhub::placeholder \
        "Repository unavailable — FossilHub" \
        "Fossil could not read this stratum. Try again shortly."
    }
    return
  }
  set accountContext [::fossilhub::account::withLogoutChallenge $accountContext]
  if {[catch {set page [::fossilhub::views::renderRepository \
      $repository $section $sectionData $accountContext]}]} {
    puts stderr "FossilHub: first-party repository render failed for [file tail $name]"
    wapp-reply-code "503 Service Unavailable"
    ::fossilhub::placeholder \
      "Repository unavailable — FossilHub" \
      "FossilHub could not render this stratum. Try again shortly."
    return
  }
  ::fossilhub::renderPage $page
}

proc wapp-default {} {
  set locale [::fossilhub::i18n::useRequest]
  set route [::fossilhub::routeForPath [::fossilhub::requestPath]]
  set accountContext [::fossilhub::account::requestContext]
  dict set accountContext locale $locale
  dict set accountContext return_to [::fossilhub::requestUri]
  switch -- [lindex $route 0] {
    health {
      wapp-mimetype text/plain
      wapp-cache-control no-cache
      wapp-subst {ok\n}
    }
    home {
      set accountContext [::fossilhub::account::withLogoutChallenge \
        $accountContext]
      ::fossilhub::renderPage [::fossilhub::views::renderHome \
        [::fossilhub::primaryRepository] $accountContext]
    }
    locale {
      ::fossilhub::handleLocale
    }
    login {
      ::fossilhub::account::handleLogin $accountContext
    }
    register {
      ::fossilhub::account::handleRegister $accountContext
    }
    logout {
      ::fossilhub::account::handleLogout $accountContext
    }
    dashboard {
      ::fossilhub::account::handleDashboard $accountContext
    }
    public-profile {
      ::fossilhub::account::handlePublicProfile $accountContext \
        [lindex $route 1]
    }
    account-settings {
      ::fossilhub::account::handleSettings $accountContext
    }
    account-security {
      ::fossilhub::account::handleSecurity $accountContext
    }
    account-session-revoke {
      ::fossilhub::account::handleSessionRevoke $accountContext
    }
    account-deactivate {
      ::fossilhub::account::handleDeactivate $accountContext
    }
    admin-overview {
      ::fossilhub::adminController::handleOverview $accountContext
    }
    admin-users {
      ::fossilhub::adminController::handleUsers $accountContext
    }
    admin-user {
      ::fossilhub::adminController::handleUser $accountContext [lindex $route 1]
    }
    admin-user-action {
      ::fossilhub::adminController::handleUserAction $accountContext \
        [lindex $route 1] [lindex $route 2]
    }
    admin-repositories {
      ::fossilhub::adminController::handleRepositories $accountContext
    }
    admin-repository {
      ::fossilhub::adminController::handleRepository $accountContext \
        [lindex $route 1]
    }
    admin-repository-action {
      ::fossilhub::adminController::handleRepositoryAction $accountContext \
        [lindex $route 1] [lindex $route 2]
    }
    admin-audit {
      ::fossilhub::adminController::handleAudit $accountContext 0
    }
    admin-audit-export {
      ::fossilhub::adminController::handleAudit $accountContext 1
    }
    admin-health {
      ::fossilhub::adminController::handleHealth $accountContext
    }
    admin-reindex {
      ::fossilhub::adminController::handleReindex $accountContext
    }
    admin-settings {
      ::fossilhub::adminController::handleSettings $accountContext
    }
    admin-reauth {
      ::fossilhub::adminController::handleReauth $accountContext
    }
    public-information {
      ::fossilhub::handlePublicInformation $accountContext [lindex $route 1]
    }
    repository-workspace {
      ::fossilhub::repositoryController::handleWorkspace $accountContext
    }
    repository-new {
      ::fossilhub::repositoryController::handleNew $accountContext
    }
    repository-settings {
      ::fossilhub::repositoryController::handleSettings \
        $accountContext [lindex $route 1]
    }
    repository-management-action {
      set slug [lindex $route 1]
      switch -- [lindex $route 2] {
        member {
          ::fossilhub::repositoryController::handleMember \
            $accountContext $slug 0
        }
        member-remove {
          ::fossilhub::repositoryController::handleMember \
            $accountContext $slug 1
        }
        transfer {
          ::fossilhub::repositoryController::handleTransfer \
            $accountContext $slug
        }
        archive {
          ::fossilhub::repositoryController::handleArchive \
            $accountContext $slug 0
        }
        restore {
          ::fossilhub::repositoryController::handleArchive \
            $accountContext $slug 1
        }
      }
    }
    repository-mutation {
      ::fossilhub::mutationController::handle $accountContext \
        [lindex $route 1] [lindex $route 2] [lindex $route 3]
    }
    repository-ticket {
      if {[string toupper [wapp-param REQUEST_METHOD GET]] eq "GET"} {
        ::fossilhub::handleRepositoryRead $accountContext [list repository \
          [lindex $route 1] ticket-detail [lindex $route 2]]
      } else {
        ::fossilhub::mutationController::handle $accountContext \
          [lindex $route 1] ticket [lindex $route 2]
      }
    }
    explore {
      set options [::fossilhub::catalogOptions]
      set accountContext [::fossilhub::account::withLogoutChallenge \
        $accountContext]
      ::fossilhub::renderPage [::fossilhub::views::renderExplore \
        [::fossilhub::catalog::repositories $options] $options $accountContext]
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
      ::fossilhub::handleRepositoryRead $accountContext $route
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
    brand-lockup {
      variable ::fossilhub::root
      ::fossilhub::trustedBinaryFile \
        [file join $::fossilhub::root public fossilhub-hub-lockup-v1.png] \
        image/png \
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
