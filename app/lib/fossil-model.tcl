namespace eval ::fossilhub::model {
  variable defaultRepositoryRoot /data/repositories
  variable defaultFossilBinary /usr/local/bin/fossil
}

proc ::fossilhub::model::repositoryRoot {} {
  variable defaultRepositoryRoot
  if {[info exists ::env(FOSSILHUB_REPOSITORY_DIR)] &&
      $::env(FOSSILHUB_REPOSITORY_DIR) ne ""} {
    return [file normalize $::env(FOSSILHUB_REPOSITORY_DIR)]
  }
  return [file normalize $defaultRepositoryRoot]
}

proc ::fossilhub::model::fossilBinary {} {
  variable defaultFossilBinary
  if {[info exists ::env(FOSSILHUB_FOSSIL)] &&
      $::env(FOSSILHUB_FOSSIL) ne ""} {
    return $::env(FOSSILHUB_FOSSIL)
  }
  return $defaultFossilBinary
}

proc ::fossilhub::model::validRepositoryName {name} {
  expr {
    [file tail $name] eq $name &&
    [regexp {^[A-Za-z0-9][A-Za-z0-9._-]*\.fossil$} $name]
  }
}

proc ::fossilhub::model::repositoryPath {name} {
  if {![::fossilhub::model::validRepositoryName $name]} {
    error "invalid repository name"
  }

  set root [::fossilhub::model::repositoryRoot]
  set path [file normalize [file join $root $name]]
  if {[file dirname $path] ne $root} {
    error "repository escaped its configured root"
  }
  return $path
}

proc ::fossilhub::model::repositoryNames {} {
  set root [::fossilhub::model::repositoryRoot]
  if {![file isdirectory $root]} {
    return {}
  }

  set names {}
  foreach path [glob -nocomplain -types f -directory $root *.fossil] {
    set name [file tail $path]
    if {[::fossilhub::model::validRepositoryName $name]} {
      lappend names $name
    }
  }
  return [lsort -dictionary $names]
}

proc ::fossilhub::model::decodeHex {value} {
  if {[string length $value] % 2 != 0 ||
      ![regexp {^[[:xdigit:]]*$} $value]} {
    error "invalid hexadecimal field from Fossil"
  }
  return [encoding convertfrom utf-8 [binary format H* $value]]
}

proc ::fossilhub::model::decodeRows {raw columnCount} {
  set rows {}
  foreach line [split [string trimright $raw "\r\n"] "\n"] {
    if {$line eq ""} {
      continue
    }
    set encoded [split [string trimright $line "\r"] "\t"]
    if {[llength $encoded] != $columnCount} {
      error "unexpected Fossil query column count"
    }
    set row {}
    foreach value $encoded {
      lappend row [::fossilhub::model::decodeHex $value]
    }
    lappend rows $row
  }
  return $rows
}

proc ::fossilhub::model::sqlRows {repository sql columnCount} {
  set command [list \
    [::fossilhub::model::fossilBinary] \
    sql \
    --readonly \
    -R $repository \
    -batch \
    -noheader \
    -separator "\t" \
    $sql]
  set raw [exec {*}$command]
  return [::fossilhub::model::decodeRows $raw $columnCount]
}

proc ::fossilhub::model::metadataSql {} {
  return {
    SELECT hex('project_name'),
           hex(CAST(COALESCE(
             (SELECT value FROM config WHERE name='project-name'),
             'Untitled Fossil repository') AS TEXT))
    UNION ALL
    SELECT hex('description'),
           hex(CAST(COALESCE(
             (SELECT value FROM config WHERE name='project-description'),
             '') AS TEXT))
    UNION ALL
    SELECT hex('project_code'),
           hex(CAST(COALESCE(
             (SELECT value FROM config WHERE name='project-code'),
             '') AS TEXT))
    UNION ALL
    SELECT hex('artifacts'), hex(CAST(COUNT(*) AS TEXT))
      FROM blob WHERE size >= 0
    UNION ALL
    SELECT hex('checkins'), hex(CAST(COUNT(*) AS TEXT))
      FROM event WHERE type='ci'
    UNION ALL
    SELECT hex('wiki_events'), hex(CAST(COUNT(*) AS TEXT))
      FROM event WHERE type='w'
    UNION ALL
    SELECT hex('ticket_events'), hex(CAST(COUNT(*) AS TEXT))
      FROM event WHERE type='t'
    UNION ALL
    SELECT hex('forum_events'), hex(CAST(COUNT(*) AS TEXT))
      FROM event WHERE type='f'
    UNION ALL
    SELECT hex('contributors'), hex(CAST(COUNT(DISTINCT
      CASE WHEN COALESCE(euser,user,'')='' THEN NULL
           ELSE COALESCE(euser,user) END) AS TEXT))
      FROM event
    UNION ALL
    SELECT hex('open_tickets'), hex(CAST(COUNT(*) AS TEXT))
      FROM ticket
     WHERE lower(COALESCE(status,'')) NOT IN ('closed','fixed','resolved')
    UNION ALL
    SELECT hex('opened_epoch'), hex(CAST(COALESCE(
      CAST(strftime('%s',MIN(mtime)) AS INTEGER), 0) AS TEXT))
      FROM event
    UNION ALL
    SELECT hex('latest_epoch'), hex(CAST(COALESCE(
      CAST(strftime('%s',MAX(mtime)) AS INTEGER), 0) AS TEXT))
      FROM event;
  }
}

proc ::fossilhub::model::timelineSql {{limit 40}} {
  if {![string is integer -strict $limit] || $limit < 1 || $limit > 200} {
    error "invalid timeline limit"
  }
  return [format {
    SELECT hex(CAST(e.type AS TEXT)),
           hex(CAST(CAST(strftime('%%s',e.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(substr(b.uuid,1,10) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,e.brief,'') AS TEXT))
      FROM event AS e
      JOIN blob AS b ON b.rid=e.objid
     WHERE e.type IN ('ci','w','t','f')
     ORDER BY e.mtime DESC, e.objid DESC
     LIMIT %d;
  } $limit]
}

proc ::fossilhub::model::repositoryFromRows {name path metadataRows eventRows} {
  set result [dict create \
    available 1 \
    name $name \
    slug [file rootname $name] \
    path $path \
    bytes [file size $path] \
    project_name "Untitled Fossil repository" \
    description "" \
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

  foreach row $metadataRows {
    lassign $row key value
    if {[dict exists $result $key]} {
      dict set result $key $value
    }
  }

  set events {}
  foreach row $eventRows {
    lassign $row type epoch uuid user comment
    lappend events [dict create \
      type $type \
      epoch $epoch \
      uuid $uuid \
      user $user \
      comment $comment]
  }
  dict set result events $events
  return $result
}

proc ::fossilhub::model::repository {name {eventLimit 40}} {
  set path [::fossilhub::model::repositoryPath $name]
  if {![file isfile $path]} {
    error "repository not found"
  }

  set metadataRows [::fossilhub::model::sqlRows \
    $path [::fossilhub::model::metadataSql] 2]
  set eventRows [::fossilhub::model::sqlRows \
    $path [::fossilhub::model::timelineSql $eventLimit] 5]
  return [::fossilhub::model::repositoryFromRows \
    $name $path $metadataRows $eventRows]
}

proc ::fossilhub::model::catalog {{eventLimit 8}} {
  set repositories {}
  foreach name [::fossilhub::model::repositoryNames] {
    if {[catch {
      set repository [::fossilhub::model::repository $name $eventLimit]
    } message]} {
      puts stderr "FossilHub: unable to read repository [file tail $name]"
      continue
    }
    lappend repositories $repository
  }
  set indexed {}
  foreach repository $repositories {
    lappend indexed [list $repository [dict get $repository latest_epoch]]
  }
  return [lsort -integer -decreasing -index 1 $indexed]
}

proc ::fossilhub::model::catalogRepositories {{eventLimit 8}} {
  set result {}
  foreach pair [::fossilhub::model::catalog $eventLimit] {
    lappend result [lindex $pair 0]
  }
  return $result
}
