namespace eval ::fossilhub::manifest {
  variable repositories [list \
    [dict create \
      name sqlite.fossil \
      slug sqlite \
      title SQLite \
      description {The canonical SQLite source tree and its complete development history.} \
      source_url https://sqlite.org/src \
      category database \
      language C \
      featured 1] \
    [dict create \
      name fossil.fossil \
      slug fossil \
      title {Fossil SCM} \
      description {The self-hosting distributed software configuration management system.} \
      source_url https://sqlite.org/fossil \
      category scm \
      language C \
      featured 0] \
    [dict create \
      name wapp.fossil \
      slug wapp \
      title Wapp \
      description {The compact Tcl web-application framework used by FossilHub.} \
      source_url https://sqlite.org/wapp \
      category framework \
      language Tcl \
      featured 0] \
    [dict create \
      name althttpd.fossil \
      slug althttpd \
      title Althttpd \
      description {The small, security-focused web server behind sqlite.org and FossilHub.} \
      source_url https://sqlite.org/althttpd \
      category server \
      language C \
      featured 0]]
}

proc ::fossilhub::manifest::all {} {
  variable repositories
  return $repositories
}

proc ::fossilhub::manifest::find {name} {
  foreach repository [::fossilhub::manifest::all] {
    if {[dict get $repository name] eq $name} {
      return $repository
    }
  }
  return ""
}

proc ::fossilhub::manifest::contains {name} {
  expr {[::fossilhub::manifest::find $name] ne ""}
}
