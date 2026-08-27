namespace eval ::fossilhub::manifest {
  variable repositories {}
  set specimens {
    {bedrock {Bedrock Dig} {A clean Fossil repository ready for its first durable layer.}}
    {ammonite {Ammonite Dig} {An empty field site for code, notes, tickets, and discussion.}}
    {trilobite {Trilobite Dig} {A newly opened Fossil specimen with no imported history.}}
    {basalt {Basalt Dig} {A blank repository prepared for the first check-in.}}
    {cambrian {Cambrian Dig} {A clean excavation where every future artifact stays together.}}
    {granite {Granite Dig} {An empty long-lived repository with Fossil-native storage.}}
    {shale {Shale Dig} {A fresh field notebook for source and project knowledge.}}
    {quartz {Quartz Dig} {A blank Fossil repository awaiting its first contribution.}}
    {obsidian {Obsidian Dig} {A clean project site with no demonstration data.}}
    {tectonic {Tectonic Dig} {An empty collaborative repository ready to evolve.}}
  }
  set index 0
  foreach specimen $specimens {
    lassign $specimen slug title description
    lappend repositories [dict create \
      name "${slug}.fossil" \
      slug $slug \
      title $title \
      description $description \
      source_url "" \
      category blank \
      language {Not set} \
      featured [expr {$index == 0}]]
    incr index
  }
  unset specimens index specimen slug title description
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
