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
    --nocgi \
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

proc ::fossilhub::model::validArtifactId {artifactId} {
  expr {[regexp {^[[:xdigit:]]{10,64}$} $artifactId]}
}

proc ::fossilhub::model::textLiteral {value} {
  return "CAST(X'[binary encode hex [encoding convertto utf-8 $value]]' AS TEXT)"
}

proc ::fossilhub::model::validatedLimit {limit {maximum 500}} {
  if {![string is integer -strict $limit] || $limit < 1 || $limit > $maximum} {
    error "invalid result limit"
  }
  return $limit
}

proc ::fossilhub::model::filesSql {} {
  return {
    SELECT hex(CAST(f.filename AS TEXT)),
           hex(CAST(f.uuid AS TEXT)),
           hex(CAST(COALESCE(b.size,0) AS TEXT))
      FROM files_of_checkin('trunk') AS f
      JOIN blob AS b ON b.uuid=f.uuid
     ORDER BY f.filename COLLATE NOCASE;
  }
}

proc ::fossilhub::model::files {name} {
  set repository [::fossilhub::model::repositoryPath $name]
  if {![file isfile $repository]} {
    error "repository not found"
  }
  set checkinRows [::fossilhub::model::sqlRows $repository {
    SELECT hex(CAST(COUNT(*) AS TEXT)) FROM event WHERE type='ci';
  } 1]
  if {[llength $checkinRows] == 0 || [lindex [lindex $checkinRows 0] 0] == 0} {
    return {}
  }
  set result {}
  foreach row [::fossilhub::model::sqlRows \
      $repository [::fossilhub::model::filesSql] 3] {
    lassign $row filename uuid size
    lappend result [dict create \
      filename $filename uuid $uuid size $size extension \
      [string tolower [file extension $filename]]]
  }
  return $result
}

proc ::fossilhub::model::documentationFiles {name} {
  set result {}
  foreach record [::fossilhub::model::files $name] {
    set filename [dict get $record filename]
    set tail [string tolower [file tail $filename]]
    set extension [dict get $record extension]
    if {[string match readme* $tail] ||
        [string match license* $tail] ||
        [string match {docs/*} [string tolower $filename]] ||
        [string match {www/*} [string tolower $filename]] ||
        $extension in {.md .markdown .wiki .txt .html}} {
      lappend result $record
    }
  }
  return $result
}

proc ::fossilhub::model::fileMetadataSql {artifactId} {
  if {![::fossilhub::model::validArtifactId $artifactId]} {
    error "invalid artifact id"
  }
  set literal [::fossilhub::model::textLiteral [string tolower $artifactId]]
  return [format {
    SELECT hex(CAST(f.filename AS TEXT)),
           hex(CAST(f.uuid AS TEXT)),
           hex(CAST(COALESCE(b.size,0) AS TEXT))
      FROM files_of_checkin('trunk') AS f
      JOIN blob AS b ON b.uuid=f.uuid
     WHERE lower(f.uuid)=lower(%s)
     LIMIT 1;
  } $literal]
}

proc ::fossilhub::model::textFilename {filename} {
  set extension [string tolower [file extension $filename]]
  if {$extension in {
      .c .cc .cpp .h .hh .hpp .tcl .tm .md .markdown .txt .wiki .html .htm
      .css .js .mjs .json .yaml .yml .xml .sql .sh .bash .zsh .mk .ac .in
      .toml .ini .cfg .conf .java .rs .go .py .rb .pl}} {
    return 1
  }
  set tail [string tolower [file tail $filename]]
  expr {$tail in {readme license makefile manifest configure}}
}

proc ::fossilhub::model::artifactText {repository artifactId} {
  if {![::fossilhub::model::validArtifactId $artifactId]} {
    error "invalid artifact id"
  }
  return [exec -keepnewline \
    [::fossilhub::model::fossilBinary] --nocgi artifact \
    --repository $repository $artifactId]
}

proc ::fossilhub::model::fileRecord {name artifactId {maximumBytes 262144}} {
  set repository [::fossilhub::model::repositoryPath $name]
  if {![file isfile $repository]} {
    error "repository not found"
  }
  set rows [::fossilhub::model::sqlRows $repository \
    [::fossilhub::model::fileMetadataSql $artifactId] 3]
  if {[llength $rows] == 0} {
    error "file artifact not found on trunk"
  }
  lassign [lindex $rows 0] filename uuid size
  set result [dict create filename $filename uuid $uuid size $size \
    text 0 truncated 0 content ""]
  if {![::fossilhub::model::textFilename $filename]} {
    return $result
  }
  set content [::fossilhub::model::artifactText $repository $uuid]
  dict set result text 1
  if {[string length [encoding convertto utf-8 $content]] > $maximumBytes} {
    set content [string range $content 0 [expr {$maximumBytes - 1}]]
    dict set result truncated 1
  }
  dict set result content $content
  return $result
}

proc ::fossilhub::model::wikiSql {{limit 200}} {
  set limit [::fossilhub::model::validatedLimit $limit]
  return [format {
    SELECT hex(CAST(substr(t.tagname,6) AS TEXT)),
           hex(CAST(b.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',tx.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,'') AS TEXT))
      FROM tag AS t
      JOIN tagxref AS tx ON tx.tagid=t.tagid
      JOIN blob AS b ON b.rid=tx.rid
      LEFT JOIN event AS e ON e.objid=tx.rid
     WHERE t.tagname GLOB 'wiki-*'
       AND tx.tagtype>0
       AND tx.rid=(
         SELECT newest.rid FROM tagxref AS newest
          WHERE newest.tagid=t.tagid AND newest.tagtype>0
          ORDER BY newest.mtime DESC, newest.rid DESC LIMIT 1
       )
     ORDER BY tx.mtime DESC, t.tagname COLLATE NOCASE
     LIMIT %d;
  } $limit]
}

proc ::fossilhub::model::wikiPages {name {limit 200}} {
  set repository [::fossilhub::model::repositoryPath $name]
  set result {}
  foreach row [::fossilhub::model::sqlRows \
      $repository [::fossilhub::model::wikiSql $limit] 5] {
    lassign $row title uuid epoch user comment
    lappend result [dict create \
      title $title uuid $uuid epoch $epoch user $user comment $comment]
  }
  return $result
}

proc ::fossilhub::model::wikiContent {name artifactId} {
  set repository [::fossilhub::model::repositoryPath $name]
  set page ""
  foreach candidate [::fossilhub::model::wikiPages $name 500] {
    if {[string equal -nocase [dict get $candidate uuid] $artifactId]} {
      set page $candidate
      break
    }
  }
  if {$page eq ""} {
    error "wiki artifact not found"
  }
  set artifact [::fossilhub::model::artifactText $repository $artifactId]
  if {![regexp -indices {\nW [0-9]+\n} $artifact marker]} {
    error "invalid wiki artifact"
  }
  set contentStart [expr {[lindex $marker 1] + 1}]
  set checksumStart [string last "\nZ " $artifact]
  if {$checksumStart < $contentStart} {
    error "invalid wiki artifact checksum boundary"
  }
  dict set page content [string range $artifact $contentStart \
    [expr {$checksumStart - 1}]]
  return $page
}

proc ::fossilhub::model::ticketsSql {{limit 200}} {
  set limit [::fossilhub::model::validatedLimit $limit]
  return [format {
    SELECT hex(CAST(tkt_uuid AS TEXT)),
           hex(CAST(COALESCE(title,'Untitled ticket') AS TEXT)),
           hex(CAST(COALESCE(status,'') AS TEXT)),
           hex(CAST(COALESCE(type,'') AS TEXT)),
           hex(CAST(COALESCE(severity,'') AS TEXT)),
           hex(CAST(COALESCE(CAST(strftime('%%s',tkt_mtime) AS INTEGER),0) AS TEXT)),
           hex(CAST(COALESCE(comment,'') AS TEXT))
      FROM ticket
     ORDER BY tkt_mtime DESC, tkt_id DESC
     LIMIT %d;
  } $limit]
}

proc ::fossilhub::model::tickets {name {limit 200}} {
  set repository [::fossilhub::model::repositoryPath $name]
  set result {}
  foreach row [::fossilhub::model::sqlRows \
      $repository [::fossilhub::model::ticketsSql $limit] 7] {
    lassign $row uuid title status type severity epoch comment
    lappend result [dict create uuid $uuid title $title status $status \
      type $type severity $severity epoch $epoch comment $comment]
  }
  return $result
}

proc ::fossilhub::model::forumPosts {name {limit 200}} {
  set repository [::fossilhub::model::repositoryPath $name]
  set limit [::fossilhub::model::validatedLimit $limit]
  set sql [format {
    SELECT hex(CAST(e.type AS TEXT)),
           hex(CAST(CAST(strftime('%%s',e.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(substr(b.uuid,1,10) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,e.brief,'') AS TEXT))
      FROM event AS e
      JOIN blob AS b ON b.rid=e.objid
     WHERE e.type='f'
     ORDER BY e.mtime DESC, e.objid DESC
     LIMIT %d;
  } $limit]
  set result {}
  foreach row [::fossilhub::model::sqlRows $repository \
      $sql 5] {
    lassign $row type epoch uuid user comment
    lappend result [dict create type $type epoch $epoch uuid $uuid \
      user $user comment $comment]
  }
  return $result
}
