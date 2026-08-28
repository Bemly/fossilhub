namespace eval ::fossilhub::history {
  variable maximumTimelineLimit 100
  variable maximumTreeEntries 5000
  variable maximumDiffBytes 2097152
  variable maximumRenderedBytes 524288
  variable maximumRawBytes 16777216
  variable maximumArchiveBytes 67108864
}

proc ::fossilhub::history::repository {name} {
  set path [::fossilhub::model::repositoryPath $name]
  if {![file isfile $path]} {
    error "repository not found"
  }
  return $path
}

proc ::fossilhub::history::utf8Length {value} {
  string length [encoding convertto utf-8 $value]
}

proc ::fossilhub::history::validateFilter {value label {maximum 160}} {
  set value [string trim $value]
  if {[::fossilhub::history::utf8Length $value] > $maximum ||
      [string first "\u0000" $value] >= 0 || [regexp {[[:cntrl:]]} $value]} {
    error "$label filter is invalid"
  }
  return $value
}

proc ::fossilhub::history::validateRevision {revision} {
  set revision [string tolower [string trim $revision]]
  if {![regexp {^[[:xdigit:]]{10,64}$} $revision]} {
    error "invalid check-in identifier"
  }
  return $revision
}

proc ::fossilhub::history::validatePath {path {allowEmpty 0}} {
  set path [string trim $path]
  if {$allowEmpty && $path eq ""} {
    return ""
  }
  if {$path eq "" || [::fossilhub::history::utf8Length $path] > 512 ||
      [string first "\u0000" $path] >= 0 || [string first "\\" $path] >= 0 ||
      [string index $path 0] eq "/" || [string index $path end] eq "/"} {
    error "invalid repository path"
  }
  foreach segment [split $path /] {
    if {$segment in {{} . ..} ||
        [::fossilhub::history::utf8Length $segment] > 255 ||
        [regexp {[[:cntrl:]]} $segment]} {
      error "invalid repository path"
    }
  }
  return $path
}

proc ::fossilhub::history::validateEpoch {value label} {
  if {$value eq ""} {
    return ""
  }
  if {![string is wideinteger -strict $value] || $value < 0 ||
      $value > 253402300799} {
    error "$label time filter is invalid"
  }
  return $value
}

proc ::fossilhub::history::resolveCheckin {name revision} {
  set repository [::fossilhub::history::repository $name]
  set revision [::fossilhub::history::validateRevision $revision]
  set literal [::fossilhub::model::textLiteral $revision]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(e.objid AS TEXT)),
           hex(CAST(b.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',e.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,e.brief,'') AS TEXT))
      FROM event AS e
      JOIN blob AS b ON b.rid=e.objid
     WHERE e.type='ci' AND lower(b.uuid) GLOB (lower(%s) || '*')
     ORDER BY b.uuid
     LIMIT 2;
  } $literal] 5]
  if {[llength $rows] != 1} {
    error "check-in not found or identifier is ambiguous"
  }
  lassign [lindex $rows 0] rid uuid epoch user comment
  return [dict create rid $rid uuid $uuid epoch $epoch user $user \
    comment $comment]
}

proc ::fossilhub::history::branchHead {name branch} {
  set repository [::fossilhub::history::repository $name]
  set branch [::fossilhub::history::validateFilter $branch branch 160]
  if {$branch eq ""} {
    error "branch name is required"
  }
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(e.objid AS TEXT)),hex(CAST(b.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',e.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,'') AS TEXT))
      FROM event AS e JOIN blob AS b ON b.rid=e.objid
      JOIN tagxref AS tx ON tx.rid=e.objid AND tx.tagtype>0
      JOIN tag AS t ON t.tagid=tx.tagid AND t.tagname='branch'
     WHERE e.type='ci' AND tx.value=%s COLLATE NOCASE
     ORDER BY e.mtime DESC,e.objid DESC LIMIT 1;
  } [::fossilhub::model::textLiteral $branch]] 5]
  if {[llength $rows] != 1} {
    error "branch not found"
  }
  lassign [lindex $rows 0] rid uuid epoch user comment
  return [dict create rid $rid uuid $uuid epoch $epoch user $user \
    comment $comment branch $branch]
}

proc ::fossilhub::history::normalizeTimelineOptions {options} {
  variable maximumTimelineLimit
  set defaults [dict create q "" type all author "" branch "" tag "" \
    from "" to "" cursor "" limit 30]
  foreach key [dict keys $options] {
    if {![dict exists $defaults $key]} {
      error "unknown timeline option"
    }
  }
  set normalized [dict merge $defaults $options]
  dict set normalized q [::fossilhub::history::validateFilter \
    [dict get $normalized q] search 200]
  set type [dict get $normalized type]
  if {$type ni {all ci w t f}} {
    error "invalid timeline event type"
  }
  foreach key {author branch tag} {
    dict set normalized $key [::fossilhub::history::validateFilter \
      [dict get $normalized $key] $key]
  }
  dict set normalized from [::fossilhub::history::validateEpoch \
    [dict get $normalized from] start]
  dict set normalized to [::fossilhub::history::validateEpoch \
    [dict get $normalized to] end]
  if {[dict get $normalized from] ne "" && [dict get $normalized to] ne "" &&
      [dict get $normalized from] > [dict get $normalized to]} {
    error "timeline time range is invalid"
  }
  set limit [dict get $normalized limit]
  if {![string is integer -strict $limit] || $limit < 1 ||
      $limit > $maximumTimelineLimit} {
    error "invalid timeline limit"
  }
  set cursor [dict get $normalized cursor]
  if {$cursor ne "" && ![regexp {^([0-9]{1,15}):([0-9]+)$} \
      $cursor -> cursorEpoch cursorRid]} {
    error "invalid timeline cursor"
  }
  return $normalized
}

proc ::fossilhub::history::timeline {name {options {}}} {
  set repository [::fossilhub::history::repository $name]
  set options [::fossilhub::history::normalizeTimelineOptions $options]
  set where [list {e.type IN ('ci','w','t','f')}]
  set q [dict get $options q]
  if {$q ne ""} {
    set escaped [string map [list "\\" "\\\\" "%" "\\%" "_" "\\_"] $q]
    set pattern [::fossilhub::model::textLiteral "%${escaped}%"]
    lappend where [format {(
      COALESCE(e.ecomment,e.comment,e.brief,'') LIKE %1$s ESCAPE '\'
      OR COALESCE(e.euser,e.user,'') LIKE %1$s ESCAPE '\'
      OR b.uuid LIKE %1$s ESCAPE '\')} $pattern]
  }
  if {[dict get $options type] ne "all"} {
    lappend where [format {e.type=%s} [::fossilhub::model::textLiteral \
      [dict get $options type]]]
  }
  if {[dict get $options author] ne ""} {
    lappend where [format {COALESCE(e.euser,e.user,'')=%s COLLATE NOCASE} \
      [::fossilhub::model::textLiteral [dict get $options author]]]
  }
  if {[dict get $options from] ne ""} {
    lappend where [format {CAST(strftime('%%s',e.mtime) AS INTEGER)>=%s} \
      [dict get $options from]]
  }
  if {[dict get $options to] ne ""} {
    lappend where [format {CAST(strftime('%%s',e.mtime) AS INTEGER)<=%s} \
      [dict get $options to]]
  }
  foreach key {branch tag} {
    set value [dict get $options $key]
    if {$value eq ""} {
      continue
    }
    if {$key eq "branch"} {
      set tagName branch
      set condition [format {tx.value=%s COLLATE NOCASE} \
        [::fossilhub::model::textLiteral $value]]
    } else {
      set tagName "sym-$value"
      set condition {1=1}
    }
    lappend where [format {EXISTS(
      SELECT 1 FROM tagxref AS tx JOIN tag AS t ON t.tagid=tx.tagid
       WHERE tx.rid=e.objid AND tx.tagtype>0 AND t.tagname=%s AND %s)} \
      [::fossilhub::model::textLiteral $tagName] \
      $condition]
  }
  set cursor [dict get $options cursor]
  if {$cursor ne ""} {
    regexp {^([0-9]{1,15}):([0-9]+)$} $cursor -> cursorEpoch cursorRid
    lappend where [format {(
      CAST((julianday(e.mtime)-2440587.5)*86400000 AS INTEGER)<%s OR
      (CAST((julianday(e.mtime)-2440587.5)*86400000 AS INTEGER)=%s AND e.objid<%d))} \
      $cursorEpoch $cursorEpoch $cursorRid]
  }
  set queryLimit [expr {[dict get $options limit] + 1}]
  set sql [format {
    SELECT hex(CAST(e.objid AS TEXT)),
           hex(CAST(e.type AS TEXT)),
           hex(CAST(CAST(strftime('%%s',e.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(b.uuid AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,e.brief,'') AS TEXT)),
           hex(CAST(COALESCE((
             SELECT tx.value FROM tagxref AS tx JOIN tag AS t ON t.tagid=tx.tagid
              WHERE tx.rid=e.objid AND tx.tagtype>0 AND t.tagname='branch'
              ORDER BY tx.mtime DESC LIMIT 1),'') AS TEXT)),
           hex(CAST(CAST((julianday(e.mtime)-2440587.5)*86400000 AS INTEGER) AS TEXT))
      FROM event AS e JOIN blob AS b ON b.rid=e.objid
     WHERE %s
     ORDER BY e.mtime DESC,e.objid DESC
     LIMIT %d;
  } [join $where " AND "] $queryLimit]
  set rows [::fossilhub::model::sqlRows $repository $sql 8]
  set hasMore [expr {[llength $rows] > [dict get $options limit]}]
  if {$hasMore} {
    set rows [lrange $rows 0 [expr {[dict get $options limit] - 1}]]
  }
  set events {}
  foreach row $rows {
    lassign $row rid type epoch uuid user comment branch sortMilliseconds
    lappend events [dict create rid $rid type $type epoch $epoch uuid $uuid \
      user $user comment $comment branch $branch sort_milliseconds $sortMilliseconds]
  }
  set nextCursor ""
  if {$hasMore && [llength $events] > 0} {
    set last [lindex $events end]
    set nextCursor "[dict get $last sort_milliseconds]:[dict get $last rid]"
  }
  return [dict create events $events next_cursor $nextCursor options $options]
}

proc ::fossilhub::history::branches {name} {
  set repository [::fossilhub::history::repository $name]
  set rows [::fossilhub::model::sqlRows $repository {
    WITH memberships AS (
      SELECT e.objid,e.mtime,b.uuid,COALESCE(NULLIF(tx.value,''),'trunk') AS name
        FROM event AS e JOIN blob AS b ON b.rid=e.objid
        JOIN tagxref AS tx ON tx.rid=e.objid AND tx.tagtype>0
        JOIN tag AS t ON t.tagid=tx.tagid AND t.tagname='branch'
       WHERE e.type='ci'
    )
    SELECT hex(CAST(m.name AS TEXT)),
           hex(CAST(COUNT(*) AS TEXT)),
           hex(CAST((SELECT newest.uuid FROM memberships AS newest
                      WHERE newest.name=m.name COLLATE NOCASE
                      ORDER BY newest.mtime DESC,newest.objid DESC LIMIT 1) AS TEXT)),
           hex(CAST(CAST(strftime('%s',MAX(m.mtime)) AS INTEGER) AS TEXT))
      FROM memberships AS m
     GROUP BY m.name COLLATE NOCASE
     ORDER BY m.name COLLATE NOCASE;
  } 4]
  set result {}
  foreach row $rows {
    lassign $row branch count uuid epoch
    lappend result [dict create name $branch checkins $count uuid $uuid epoch $epoch]
  }
  return $result
}

proc ::fossilhub::history::tags {name} {
  set repository [::fossilhub::history::repository $name]
  set rows [::fossilhub::model::sqlRows $repository {
    WITH branch_names AS (
      SELECT DISTINCT COALESCE(NULLIF(value,''),'trunk') AS name
        FROM tagxref AS bx JOIN tag AS bt ON bt.tagid=bx.tagid
       WHERE bt.tagname='branch' AND bx.tagtype>0
    )
    SELECT hex(CAST(substr(t.tagname,5) AS TEXT)),
           hex(CAST(b.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%s',e.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,'') AS TEXT))
      FROM tag AS t JOIN tagxref AS tx ON tx.tagid=t.tagid AND tx.tagtype>0
      JOIN event AS e ON e.objid=tx.rid AND e.type='ci'
      JOIN blob AS b ON b.rid=e.objid
     WHERE t.tagname GLOB 'sym-*'
       AND NOT EXISTS(SELECT 1 FROM branch_names AS names
                       WHERE names.name=substr(t.tagname,5) COLLATE NOCASE)
     ORDER BY e.mtime DESC,t.tagname COLLATE NOCASE;
  } 5]
  set result {}
  foreach row $rows {
    lassign $row tag uuid epoch user comment
    lappend result [dict create name $tag uuid $uuid epoch $epoch \
      user $user comment $comment]
  }
  return $result
}

proc ::fossilhub::history::checkinRelations {repository rid direction} {
  if {$direction eq "parents"} {
    set join {p.pid=related.objid}
    set predicate {p.cid=%d}
  } elseif {$direction eq "children"} {
    set join {p.cid=related.objid}
    set predicate {p.pid=%d}
  } else {
    error "invalid check-in relation"
  }
  set sql [format {
    SELECT hex(CAST(b.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',related.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(related.ecomment,related.comment,'') AS TEXT)),
           hex(CAST(COALESCE(related.euser,related.user,'') AS TEXT)),
           hex(CAST(p.isprim AS TEXT))
      FROM plink AS p JOIN event AS related ON %s
      JOIN blob AS b ON b.rid=related.objid
     WHERE %s
     ORDER BY p.isprim DESC,related.mtime DESC,related.objid DESC;
  } $join [format $predicate $rid]]
  set result {}
  foreach row [::fossilhub::model::sqlRows $repository $sql 5] {
    lassign $row uuid epoch comment user primary
    lappend result [dict create uuid $uuid epoch $epoch comment $comment \
      user $user primary $primary]
  }
  return $result
}

proc ::fossilhub::history::checkinLabels {repository rid} {
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(t.tagname AS TEXT)),hex(CAST(COALESCE(tx.value,'') AS TEXT))
      FROM tagxref AS tx JOIN tag AS t ON t.tagid=tx.tagid
     WHERE tx.rid=%d AND tx.tagtype>0
       AND (t.tagname='branch' OR t.tagname GLOB 'sym-*')
     ORDER BY t.tagname COLLATE NOCASE;
  } $rid] 2]
  set branch ""
  set symbols {}
  foreach row $rows {
    lassign $row tag value
    if {$tag eq "branch"} {
      set branch $value
    } else {
      lappend symbols [string range $tag 4 end]
    }
  }
  return [dict create branch $branch symbols $symbols]
}

proc ::fossilhub::history::checkinChanges {repository rid} {
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(COALESCE(oldname.name,'') AS TEXT)),
           hex(CAST(newname.name AS TEXT)),
           hex(CAST(COALESCE(oldblob.uuid,'') AS TEXT)),
           hex(CAST(COALESCE(newblob.uuid,'') AS TEXT)),
           hex(CAST(COALESCE(oldblob.size,0) AS TEXT)),
           hex(CAST(COALESCE(newblob.size,0) AS TEXT)),
           hex(CAST(m.mperm AS TEXT))
      FROM mlink AS m JOIN filename AS newname ON newname.fnid=m.fnid
      LEFT JOIN filename AS oldname ON oldname.fnid=m.pfnid
      LEFT JOIN blob AS oldblob ON oldblob.rid=m.pid
      LEFT JOIN blob AS newblob ON newblob.rid=m.fid
     WHERE m.mid=%d ORDER BY newname.name COLLATE NOCASE;
  } $rid] 7]
  set result {}
  foreach row $rows {
    lassign $row oldName filename oldUuid uuid oldSize size permissions
    if {$uuid eq ""} {
      set change deleted
    } elseif {$oldUuid eq ""} {
      set change added
    } elseif {$oldName ne "" && $oldName ne $filename} {
      set change renamed
    } else {
      set change modified
    }
    lappend result [dict create change $change filename $filename \
      previous_filename $oldName uuid $uuid previous_uuid $oldUuid size $size \
      previous_size $oldSize permissions $permissions additions "" deletions ""]
  }
  return $result
}

proc ::fossilhub::history::diffStats {repository uuid} {
  if {[catch {set output [exec -keepnewline \
      [::fossilhub::model::fossilBinary] --nocgi diff --repository $repository \
      --checkin $uuid --internal --numstat]}]} {
    return [dict create additions 0 deletions 0 files {}]
  }
  set files {}
  set additions 0
  set deletions 0
  foreach line [split $output "\n"] {
    if {[regexp {^[[:space:]]*([0-9]+)[[:space:]]+([0-9]+)[[:space:]]+(.+)$} \
        $line -> added deleted filename]} {
      if {[string match {TOTAL over *} $filename]} {
        set additions $added
        set deletions $deleted
      } else {
        dict set files $filename [list $added $deleted]
      }
    }
  }
  return [dict create additions $additions deletions $deletions files $files]
}

proc ::fossilhub::history::checkin {name revision} {
  set repository [::fossilhub::history::repository $name]
  set result [::fossilhub::history::resolveCheckin $name $revision]
  set rid [dict get $result rid]
  dict set result parents [::fossilhub::history::checkinRelations \
    $repository $rid parents]
  dict set result children [::fossilhub::history::checkinRelations \
    $repository $rid children]
  set labels [::fossilhub::history::checkinLabels $repository $rid]
  dict set result branch [dict get $labels branch]
  dict set result tags [dict get $labels symbols]
  set changes [::fossilhub::history::checkinChanges $repository $rid]
  set stats [::fossilhub::history::diffStats $repository [dict get $result uuid]]
  set enriched {}
  foreach change $changes {
    set candidates [list [dict get $change filename]]
    if {[dict get $change previous_filename] ne ""} {
      lappend candidates [dict get $change previous_filename]
    }
    foreach filename $candidates {
      if {[dict exists $stats files $filename]} {
        lassign [dict get $stats files $filename] additions deletions
        dict set change additions $additions
        dict set change deletions $deletions
        break
      }
    }
    lappend enriched $change
  }
  dict set result changes $enriched
  dict set result additions [dict get $stats additions]
  dict set result deletions [dict get $stats deletions]
  return $result
}

proc ::fossilhub::history::checkinDiff {name revision} {
  variable maximumDiffBytes
  variable maximumRenderedBytes
  set repository [::fossilhub::history::repository $name]
  set checkin [::fossilhub::history::resolveCheckin $name $revision]
  set total 0
  foreach change [::fossilhub::history::checkinChanges $repository \
      [dict get $checkin rid]] {
    incr total [dict get $change size]
    incr total [dict get $change previous_size]
    if {$total > $maximumDiffBytes} {
      return [dict create content "" truncated 1 reason \
        "Changed files exceed the safe diff rendering budget."]
    }
  }
  if {[catch {set output [exec -keepnewline \
      [::fossilhub::model::fossilBinary] --nocgi diff --repository $repository \
      --checkin [dict get $checkin uuid] --internal --unified --versions]}]} {
    return [dict create content "" truncated 0 reason \
      "This check-in has no parent diff to display."]
  }
  set truncated 0
  if {[::fossilhub::history::utf8Length $output] > $maximumRenderedBytes} {
    set output [string range $output 0 [expr {$maximumRenderedBytes - 1}]]
    set truncated 1
  }
  return [dict create content $output truncated $truncated reason ""]
}

proc ::fossilhub::history::tree {name revision {directory ""}} {
  variable maximumTreeEntries
  set repository [::fossilhub::history::repository $name]
  set checkin [::fossilhub::history::resolveCheckin $name $revision]
  set labels [::fossilhub::history::checkinLabels $repository [dict get $checkin rid]]
  dict set checkin branch [dict get $labels branch]
  dict set checkin tags [dict get $labels symbols]
  set directory [::fossilhub::history::validatePath $directory 1]
  set uuid [dict get $checkin uuid]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(f.filename AS TEXT)),hex(CAST(f.uuid AS TEXT)),
           hex(CAST(COALESCE(b.size,0) AS TEXT))
      FROM files_of_checkin(%s) AS f JOIN blob AS b ON b.uuid=f.uuid
     ORDER BY f.filename COLLATE NOCASE LIMIT %d;
  } [::fossilhub::model::textLiteral $uuid] [expr {$maximumTreeEntries + 1}]] 3]
  if {[llength $rows] > $maximumTreeEntries} {
    error "repository tree exceeds the browsing entry budget"
  }
  set prefix ""
  if {$directory ne ""} {
    set prefix "${directory}/"
  }
  set entries {}
  set directories {}
  foreach row $rows {
    lassign $row filename artifact size
    if {![string match "${prefix}*" $filename]} {
      continue
    }
    set remainder [string range $filename [string length $prefix] end]
    if {$remainder eq ""} {
      continue
    }
    set separator [string first / $remainder]
    if {$separator >= 0} {
      set child [string range $remainder 0 [expr {$separator - 1}]]
      if {![dict exists $directories $child]} {
        dict set directories $child 1
        set path [expr {$directory eq "" ? $child : "${directory}/${child}"}]
        lappend entries [dict create type directory name $child path $path \
          uuid "" size 0]
      }
    } else {
      lappend entries [dict create type file name $remainder path $filename \
        uuid $artifact size $size]
    }
  }
  set indexed {}
  foreach entry $entries {
    set weight [expr {[dict get $entry type] eq "directory" ? 0 : 1}]
    lappend indexed [list $weight [string tolower [dict get $entry name]] $entry]
  }
  set entries {}
  foreach item [lsort -dictionary -index 1 [lsort -integer -index 0 $indexed]] {
    lappend entries [lindex $item 2]
  }
  return [dict create checkin $checkin directory $directory entries $entries]
}

proc ::fossilhub::history::filesAtRevision {name revision} {
  variable maximumTreeEntries
  set repository [::fossilhub::history::repository $name]
  set checkin [::fossilhub::history::resolveCheckin $name $revision]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(f.filename AS TEXT)),hex(CAST(f.uuid AS TEXT)),
           hex(CAST(COALESCE(b.size,0) AS TEXT))
      FROM files_of_checkin(%s) AS f JOIN blob AS b ON b.uuid=f.uuid
     ORDER BY f.filename COLLATE NOCASE LIMIT %d;
  } [::fossilhub::model::textLiteral [dict get $checkin uuid]] \
    [expr {$maximumTreeEntries + 1}]] 3]
  if {[llength $rows] > $maximumTreeEntries} {
    error "repository tree exceeds the browsing entry budget"
  }
  set files {}
  foreach row $rows {
    lassign $row filename uuid size
    lappend files [dict create filename $filename uuid $uuid size $size \
      extension [string tolower [file extension $filename]]]
  }
  return [dict create checkin $checkin files $files]
}

proc ::fossilhub::history::documentationAtRevision {name revision} {
  set result [::fossilhub::history::filesAtRevision $name $revision]
  set documentation {}
  foreach record [dict get $result files] {
    set filename [dict get $record filename]
    set tail [string tolower [file tail $filename]]
    set extension [dict get $record extension]
    if {[string match readme* $tail] || [string match license* $tail] ||
        [string match {docs/*} [string tolower $filename]] ||
        [string match {www/*} [string tolower $filename]] ||
        $extension in {.md .markdown .wiki .txt .html}} {
      lappend documentation $record
    }
  }
  dict set result files $documentation
  return $result
}

proc ::fossilhub::history::fileAtRevision {name revision artifactId \
    {maximumBytes 524288}} {
  set repository [::fossilhub::history::repository $name]
  set checkin [::fossilhub::history::resolveCheckin $name $revision]
  if {![::fossilhub::model::validArtifactId $artifactId]} {
    error "invalid file artifact identifier"
  }
  if {![string is integer -strict $maximumBytes] || $maximumBytes < 1 ||
      $maximumBytes > 4194304} {
    error "invalid file rendering budget"
  }
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(f.filename AS TEXT)),hex(CAST(f.uuid AS TEXT)),
           hex(CAST(COALESCE(b.size,0) AS TEXT))
      FROM files_of_checkin(%s) AS f JOIN blob AS b ON b.uuid=f.uuid
     WHERE lower(f.uuid) GLOB (lower(%s) || '*') LIMIT 2;
  } [::fossilhub::model::textLiteral [dict get $checkin uuid]] \
    [::fossilhub::model::textLiteral $artifactId]] 3]
  if {[llength $rows] != 1} {
    error "file artifact not found at check-in"
  }
  lassign [lindex $rows 0] filename uuid size
  set result [dict create checkin $checkin filename $filename uuid $uuid \
    size $size text [::fossilhub::model::textFilename $filename] truncated 0 \
    content ""]
  if {![dict get $result text]} {
    return $result
  }
  set content [::fossilhub::model::artifactText $repository $uuid]
  if {[string first "\u0000" $content] >= 0} {
    dict set result text 0
    return $result
  }
  if {[::fossilhub::history::utf8Length $content] > $maximumBytes} {
    set content [string range $content 0 [expr {$maximumBytes - 1}]]
    dict set result truncated 1
  }
  dict set result content $content
  return $result
}

proc ::fossilhub::history::rawFile {name revision artifactId} {
  variable maximumRawBytes
  set repository [::fossilhub::history::repository $name]
  set file [::fossilhub::history::fileAtRevision $name $revision $artifactId 1]
  if {[dict get $file size] > $maximumRawBytes} {
    error "file exceeds the direct download budget"
  }
  dict set file content [::fossilhub::model::artifactText \
    $repository [dict get $file uuid]]
  dict set file truncated 0
  return $file
}

proc ::fossilhub::history::fileHistory {name revision artifactId {limit 100}} {
  set repository [::fossilhub::history::repository $name]
  set file [::fossilhub::history::fileAtRevision $name $revision $artifactId 1]
  set limit [::fossilhub::model::validatedLimit $limit 200]
  set currentNames [dict create [dict get $file filename] 1]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(newname.name AS TEXT)),
           hex(CAST(COALESCE(oldname.name,'') AS TEXT)),
           hex(CAST(COALESCE(newblob.uuid,'') AS TEXT)),
           hex(CAST(COALESCE(oldblob.uuid,'') AS TEXT)),
           hex(CAST(checkin.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',e.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,'') AS TEXT)),
           hex(CAST(e.objid AS TEXT))
      FROM mlink AS m JOIN filename AS newname ON newname.fnid=m.fnid
      LEFT JOIN filename AS oldname ON oldname.fnid=m.pfnid
      LEFT JOIN blob AS newblob ON newblob.rid=m.fid
      LEFT JOIN blob AS oldblob ON oldblob.rid=m.pid
      JOIN event AS e ON e.objid=m.mid AND e.type='ci'
      JOIN blob AS checkin ON checkin.rid=e.objid
     WHERE e.mtime<(SELECT target.mtime FROM event AS target WHERE target.objid=%d)
        OR (e.mtime=(SELECT target.mtime FROM event AS target WHERE target.objid=%d)
            AND e.objid<=%d)
     ORDER BY e.mtime DESC,e.objid DESC;
  } [dict get $file checkin rid] [dict get $file checkin rid] \
    [dict get $file checkin rid]] 9]
  set result {}
  foreach row $rows {
    lassign $row filename previousFilename uuid previousUuid checkinUuid epoch \
      user comment rid
    if {![dict exists $currentNames $filename] &&
        ($previousFilename eq "" || ![dict exists $currentNames $previousFilename])} {
      continue
    }
    if {$previousFilename ne "" && [dict exists $currentNames $filename]} {
      dict set currentNames $previousFilename 1
    }
    if {$uuid eq ""} {
      set change deleted
    } elseif {$previousUuid eq ""} {
      set change added
    } elseif {$previousFilename ne "" && $previousFilename ne $filename} {
      set change renamed
    } else {
      set change modified
    }
    lappend result [dict create filename $filename previous_filename $previousFilename \
      uuid $uuid previous_uuid $previousUuid checkin $checkinUuid epoch $epoch \
      user $user comment $comment change $change rid $rid]
    if {[llength $result] >= $limit} {
      break
    }
  }
  return [dict create file $file history $result]
}

proc ::fossilhub::history::temporaryCheckout {repository revision} {
  set channel [file tempfile checkout fossilhub-read-checkout]
  close $channel
  file delete $checkout
  file mkdir $checkout
  file attributes $checkout -permissions 0700
  if {[catch {exec [::fossilhub::model::fossilBinary] --nocgi open $repository \
      $revision --nosync --workdir $checkout} message options]} {
    file delete -force $checkout
    return -options $options $message
  }
  return $checkout
}

proc ::fossilhub::history::deleteTemporaryCheckout {checkout} {
  if {[file isdirectory $checkout] &&
      [string match fossilhub-read-checkout* [file tail $checkout]]} {
    file delete -force $checkout
  }
}

proc ::fossilhub::history::blame {name revision artifactId} {
  variable maximumRenderedBytes
  set repository [::fossilhub::history::repository $name]
  set file [::fossilhub::history::fileAtRevision $name $revision $artifactId]
  if {![dict get $file text] || [dict get $file truncated]} {
    error "blame is available only for text files within the rendering budget"
  }
  set checkout ""
  try {
    set checkout [::fossilhub::history::temporaryCheckout $repository \
      [dict get $file checkin uuid]]
    set output [exec -keepnewline [::fossilhub::model::fossilBinary] --nocgi \
      --chdir $checkout blame --revision [dict get $file checkin uuid] \
      --limit 200 [dict get $file filename]]
    if {[::fossilhub::history::utf8Length $output] > $maximumRenderedBytes} {
      set output [string range $output 0 [expr {$maximumRenderedBytes - 1}]]
      set truncated 1
    } else {
      set truncated 0
    }
    return [dict create file $file content $output truncated $truncated]
  } finally {
    if {$checkout ne ""} {
      ::fossilhub::history::deleteTemporaryCheckout $checkout
    }
  }
}

proc ::fossilhub::history::decodeCardValue {value} {
  set result ""
  set length [string length $value]
  for {set index 0} {$index < $length} {incr index} {
    set character [string index $value $index]
    if {$character ne "\\" || $index + 1 >= $length} {
      append result $character
      continue
    }
    incr index
    set escaped [string index $value $index]
    switch -- $escaped {
      s { append result " " }
      n { append result "\n" }
      r { append result "\r" }
      t { append result "\t" }
      {\\} { append result "\\" }
      default { append result "\\$escaped" }
    }
  }
  return $result
}

proc ::fossilhub::history::artifactCards {artifact} {
  set header $artifact
  if {[regexp -indices {\nW [0-9]+\n} $artifact marker]} {
    set header [string range $artifact 0 [lindex $marker 0]]
  }
  set cards {}
  foreach line [split [string trimright $header "\n"] "\n"] {
    if {![regexp {^([A-Z])(?: (.*))?$} $line -> key value]} {
      continue
    }
    dict lappend cards $key [::fossilhub::history::decodeCardValue $value]
  }
  return $cards
}

proc ::fossilhub::history::artifactBody {artifact} {
  if {![regexp -indices {\nW [0-9]+\n} $artifact marker]} {
    return ""
  }
  set start [expr {[lindex $marker 1] + 1}]
  set checksum [string last "\nZ " $artifact]
  if {$checksum < $start} {
    error "invalid Fossil content artifact"
  }
  return [string range $artifact $start [expr {$checksum - 1}]]
}

proc ::fossilhub::history::wikiHistory {name title {limit 100}} {
  set repository [::fossilhub::history::repository $name]
  set title [::fossilhub::history::validateFilter $title wiki 160]
  if {$title eq ""} {
    error "wiki page name is required"
  }
  set limit [::fossilhub::model::validatedLimit $limit 200]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(b.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',tx.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,'') AS TEXT))
      FROM tag AS t JOIN tagxref AS tx ON tx.tagid=t.tagid AND tx.tagtype>0
      JOIN blob AS b ON b.rid=tx.rid LEFT JOIN event AS e ON e.objid=tx.rid
     WHERE t.tagname=('wiki-' || %s)
     ORDER BY tx.mtime DESC,tx.rid DESC LIMIT %d;
  } [::fossilhub::model::textLiteral $title] $limit] 4]
  set result {}
  foreach row $rows {
    lassign $row uuid epoch user comment
    set artifact [::fossilhub::model::artifactText $repository $uuid]
    set cards [::fossilhub::history::artifactCards $artifact]
    set mimetype [expr {[dict exists $cards N] ? [lindex [dict get $cards N] 0] : \
      "text/x-fossil-wiki"}]
    lappend result [dict create title $title uuid $uuid epoch $epoch user $user \
      comment $comment mimetype $mimetype]
  }
  return $result
}

proc ::fossilhub::history::wikiArtifact {name revision} {
  set repository [::fossilhub::history::repository $name]
  set revision [::fossilhub::history::validateRevision $revision]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(substr(t.tagname,6) AS TEXT)),hex(CAST(b.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',tx.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT)),
           hex(CAST(COALESCE(e.ecomment,e.comment,'') AS TEXT))
      FROM tag AS t JOIN tagxref AS tx ON tx.tagid=t.tagid AND tx.tagtype>0
      JOIN blob AS b ON b.rid=tx.rid LEFT JOIN event AS e ON e.objid=tx.rid
     WHERE t.tagname GLOB 'wiki-*'
       AND lower(b.uuid) GLOB (lower(%s) || '*') LIMIT 2;
  } [::fossilhub::model::textLiteral $revision]] 5]
  if {[llength $rows] != 1} {
    error "wiki revision not found or identifier is ambiguous"
  }
  lassign [lindex $rows 0] title uuid epoch user comment
  set artifact [::fossilhub::model::artifactText $repository $uuid]
  set cards [::fossilhub::history::artifactCards $artifact]
  set mimetype [expr {[dict exists $cards N] ? [lindex [dict get $cards N] 0] : \
    "text/x-fossil-wiki"}]
  return [dict create title $title uuid $uuid epoch $epoch user $user \
    comment $comment mimetype $mimetype \
    content [::fossilhub::history::artifactBody $artifact]]
}

proc ::fossilhub::history::wikiRevision {name title revision} {
  set repository [::fossilhub::history::repository $name]
  set revision [::fossilhub::history::validateRevision $revision]
  foreach item [::fossilhub::history::wikiHistory $name $title 200] {
    if {[string match "${revision}*" [string tolower [dict get $item uuid]]]} {
      set artifact [::fossilhub::model::artifactText $repository \
        [dict get $item uuid]]
      dict set item content [::fossilhub::history::artifactBody $artifact]
      return $item
    }
  }
  error "wiki revision not found"
}

proc ::fossilhub::history::compareLines {before after} {
  set left [split $before "\n"]
  set right [split $after "\n"]
  if {[llength $left] > 300 || [llength $right] > 300} {
    return [dict create too_large 1 lines {}]
  }
  set table [dict create]
  for {set i [llength $left]} {$i >= 0} {incr i -1} {
    for {set j [llength $right]} {$j >= 0} {incr j -1} {
      if {$i == [llength $left] || $j == [llength $right]} {
        dict set table "$i,$j" 0
      } elseif {[lindex $left $i] eq [lindex $right $j]} {
        dict set table "$i,$j" [expr {1 + [dict get $table \
          "[expr {$i + 1}],[expr {$j + 1}]"]}]
      } else {
        dict set table "$i,$j" [expr {max(
          [dict get $table "[expr {$i + 1}],$j"],
          [dict get $table "$i,[expr {$j + 1}]"])}]
      }
    }
  }
  set lines {}
  set i 0
  set j 0
  while {$i < [llength $left] || $j < [llength $right]} {
    if {$i < [llength $left] && $j < [llength $right] &&
        [lindex $left $i] eq [lindex $right $j]} {
      lappend lines [dict create kind equal content [lindex $left $i]]
      incr i
      incr j
    } elseif {$j < [llength $right] && ($i >= [llength $left] ||
        [dict get $table "$i,[expr {$j + 1}]"] >
        [dict get $table "[expr {$i + 1}],$j"])} {
      lappend lines [dict create kind added content [lindex $right $j]]
      incr j
    } else {
      lappend lines [dict create kind deleted content [lindex $left $i]]
      incr i
    }
  }
  return [dict create too_large 0 lines $lines]
}

proc ::fossilhub::history::wikiComparison {name beforeRevision afterRevision} {
  set before [::fossilhub::history::wikiArtifact $name $beforeRevision]
  set after [::fossilhub::history::wikiArtifact $name $afterRevision]
  if {![string equal -nocase [dict get $before title] [dict get $after title]]} {
    error "wiki revisions belong to different pages"
  }
  return [dict create before $before after $after comparison \
    [::fossilhub::history::compareLines \
      [dict get $before content] [dict get $after content]]]
}

proc ::fossilhub::history::validateTicketId {ticketId} {
  set ticketId [string tolower [string trim $ticketId]]
  if {![regexp {^[[:xdigit:]]{40,64}$} $ticketId]} {
    error "invalid ticket identifier"
  }
  return $ticketId
}

proc ::fossilhub::history::ticket {name ticketId} {
  set repository [::fossilhub::history::repository $name]
  set ticketId [::fossilhub::history::validateTicketId $ticketId]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(tkt_uuid AS TEXT)),hex(CAST(COALESCE(title,'') AS TEXT)),
           hex(CAST(COALESCE(status,'') AS TEXT)),
           hex(CAST(COALESCE(type,'') AS TEXT)),
           hex(CAST(COALESCE(severity,'') AS TEXT)),
           hex(CAST(COALESCE(priority,'') AS TEXT)),
           hex(CAST(COALESCE(resolution,'') AS TEXT)),
           hex(CAST(COALESCE(comment,'') AS TEXT)),
           hex(CAST(COALESCE(CAST(strftime('%%s',tkt_ctime) AS INTEGER),0) AS TEXT)),
           hex(CAST(COALESCE(CAST(strftime('%%s',tkt_mtime) AS INTEGER),0) AS TEXT))
      FROM ticket WHERE lower(tkt_uuid)=lower(%s) LIMIT 1;
  } [::fossilhub::model::textLiteral $ticketId]] 10]
  if {[llength $rows] != 1} {
    error "ticket not found"
  }
  lassign [lindex $rows 0] uuid title status type severity priority resolution \
    comment createdEpoch updatedEpoch
  set result [dict create uuid $uuid title $title status $status type $type \
    severity $severity priority $priority resolution $resolution comment $comment \
    created_epoch $createdEpoch updated_epoch $updatedEpoch history {}]
  set eventRows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(b.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',e.mtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT))
      FROM tag AS t JOIN tagxref AS tx ON tx.tagid=t.tagid AND tx.tagtype>0
      JOIN event AS e ON e.objid=tx.rid AND e.type='t'
      JOIN blob AS b ON b.rid=e.objid
     WHERE t.tagname=('tkt-' || %s)
     ORDER BY e.mtime,e.objid LIMIT 500;
  } [::fossilhub::model::textLiteral $ticketId]] 3]
  set history {}
  foreach row $eventRows {
    lassign $row artifactId epoch user
    set artifact [::fossilhub::model::artifactText $repository $artifactId]
    set cards [::fossilhub::history::artifactCards $artifact]
    set changes {}
    if {[dict exists $cards J]} {
      foreach value [dict get $cards J] {
        if {[regexp {^([^ ]+)(?: (.*))?$} $value -> field fieldValue]} {
          lappend changes [dict create field $field value $fieldValue]
        }
      }
    }
    lappend history [dict create uuid $artifactId epoch $epoch user $user \
      changes $changes]
  }
  dict set result history $history
  return $result
}

proc ::fossilhub::history::forumThread {name artifactId} {
  set repository [::fossilhub::history::repository $name]
  set artifactId [::fossilhub::history::validateRevision $artifactId]
  set literal [::fossilhub::model::textLiteral $artifactId]
  set roots [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(root.uuid AS TEXT))
      FROM forumpost AS fp JOIN blob AS post ON post.rid=fp.fpid
      JOIN blob AS root ON root.rid=fp.froot
     WHERE lower(post.uuid) GLOB (lower(%s) || '*') LIMIT 2;
  } $literal] 1]
  if {[llength $roots] != 1} {
    error "forum thread not found or identifier is ambiguous"
  }
  set rootUuid [lindex [lindex $roots 0] 0]
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(post.uuid AS TEXT)),
           hex(CAST(COALESCE(parent.uuid,'') AS TEXT)),
           hex(CAST(CAST(strftime('%%s',fp.fmtime) AS INTEGER) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT))
      FROM forumpost AS fp JOIN blob AS post ON post.rid=fp.fpid
      JOIN blob AS root ON root.rid=fp.froot
      LEFT JOIN blob AS parent ON parent.rid=COALESCE(fp.firt,fp.fprev)
      LEFT JOIN event AS e ON e.objid=fp.fpid
     WHERE root.uuid=%s ORDER BY fp.fmtime,fp.fpid LIMIT 500;
  } [::fossilhub::model::textLiteral $rootUuid]] 4]
  set posts {}
  set title ""
  foreach row $rows {
    lassign $row uuid parent epoch user
    set artifact [::fossilhub::model::artifactText $repository $uuid]
    set cards [::fossilhub::history::artifactCards $artifact]
    if {$uuid eq $rootUuid && [dict exists $cards H]} {
      set title [lindex [dict get $cards H] 0]
    }
    set mimetype [expr {[dict exists $cards N] ? [lindex [dict get $cards N] 0] : \
      "text/x-fossil-wiki"}]
    lappend posts [dict create uuid $uuid parent $parent epoch $epoch user $user \
      mimetype $mimetype content [::fossilhub::history::artifactBody $artifact]]
  }
  return [dict create uuid $rootUuid title $title posts $posts]
}

proc ::fossilhub::history::forumThreads {name {limit 100}} {
  set repository [::fossilhub::history::repository $name]
  set limit [::fossilhub::model::validatedLimit $limit 200]
  set countRows [::fossilhub::model::sqlRows $repository {
    SELECT hex(CAST(COUNT(*) AS TEXT)) FROM event WHERE type='f';
  } 1]
  if {[lindex [lindex $countRows 0] 0] == 0} {
    return {}
  }
  set rows [::fossilhub::model::sqlRows $repository [format {
    SELECT hex(CAST(root.uuid AS TEXT)),
           hex(CAST(CAST(strftime('%%s',MAX(allposts.fmtime)) AS INTEGER) AS TEXT)),
           hex(CAST(COUNT(allposts.fpid) AS TEXT)),
           hex(CAST(COALESCE(e.euser,e.user,'') AS TEXT))
      FROM forumpost AS first
      JOIN blob AS root ON root.rid=first.fpid
      JOIN forumpost AS allposts ON allposts.froot=first.fpid
      LEFT JOIN event AS e ON e.objid=first.fpid
     WHERE first.fpid=first.froot
     GROUP BY first.fpid ORDER BY MAX(allposts.fmtime) DESC,first.fpid DESC
     LIMIT %d;
  } $limit] 4]
  set result {}
  foreach row $rows {
    lassign $row uuid epoch postCount user
    set artifact [::fossilhub::model::artifactText $repository $uuid]
    set cards [::fossilhub::history::artifactCards $artifact]
    set title [expr {[dict exists $cards H] ? [lindex [dict get $cards H] 0] :
      "Untitled discussion"}]
    lappend result [dict create uuid $uuid title $title epoch $epoch \
      posts $postCount user $user]
  }
  return $result
}

proc ::fossilhub::history::statistics {name} {
  set repository [::fossilhub::history::repository $name]
  set rows [::fossilhub::model::sqlRows $repository {
    SELECT hex('artifacts'),hex(CAST(COUNT(*) AS TEXT)) FROM blob WHERE size>=0
    UNION ALL SELECT hex('artifact_bytes'),hex(CAST(COALESCE(SUM(size),0) AS TEXT))
      FROM blob WHERE size>=0
    UNION ALL SELECT hex('checkins'),hex(CAST(COUNT(*) AS TEXT)) FROM event WHERE type='ci'
    UNION ALL SELECT hex('branches'),hex(CAST(COUNT(DISTINCT value) AS TEXT))
      FROM tagxref AS tx JOIN tag AS t ON t.tagid=tx.tagid
     WHERE t.tagname='branch' AND tx.tagtype>0
    UNION ALL SELECT hex('files'),hex(CAST(COUNT(*) AS TEXT)) FROM filename
    UNION ALL SELECT hex('wiki_revisions'),hex(CAST(COUNT(*) AS TEXT)) FROM event WHERE type='w'
    UNION ALL SELECT hex('tickets'),hex(CAST(COUNT(*) AS TEXT)) FROM ticket
    UNION ALL SELECT hex('forum_posts'),hex(CAST(COUNT(*) AS TEXT)) FROM event WHERE type='f'
    UNION ALL SELECT hex('contributors'),hex(CAST(COUNT(DISTINCT COALESCE(euser,user,'')) AS TEXT))
      FROM event WHERE COALESCE(euser,user,'')<>'';
  } 2]
  set result [dict create repository_bytes [file size $repository]]
  foreach row $rows {
    lassign $row key value
    dict set result $key $value
  }
  return $result
}

proc ::fossilhub::history::createArchive {name revision} {
  variable maximumArchiveBytes
  set repository [::fossilhub::history::repository $name]
  set checkin [::fossilhub::history::resolveCheckin $name $revision]
  set files [::fossilhub::history::filesAtRevision $name \
    [dict get $checkin uuid]]
  set total 0
  foreach file [dict get $files files] {
    incr total [dict get $file size]
    if {$total > $maximumArchiveBytes} {
      error "repository snapshot exceeds the archive download budget"
    }
  }
  set channel [file tempfile archive fossilhub-archive]
  close $channel
  file delete $archive
  append archive .zip
  set rootName "[file rootname $name]-[string range [dict get $checkin uuid] 0 9]"
  if {[catch {exec [::fossilhub::model::fossilBinary] --nocgi zip \
      [dict get $checkin uuid] $archive --name $rootName -R $repository} \
      message options]} {
    if {[file exists $archive]} {
      file delete -force $archive
    }
    return -options $options $message
  }
  file attributes $archive -permissions 0600
  return [dict create path $archive filename "${rootName}.zip" \
    checkin $checkin]
}

proc ::fossilhub::history::deleteArchive {archive} {
  if {[file isfile $archive] && [string match fossilhub-archive*.zip \
      [file tail $archive]]} {
    file delete -force $archive
  }
}
