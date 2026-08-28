namespace eval ::fossilhub::views {}

proc ::fossilhub::views::publicNavigation {active} {
  set html {<nav class="public-page-nav" aria-label="FossilHub information">}
  foreach {slug label} {
    manual Manual hosting Hosting upstream Upstream releases Releases
    rules Rules status Status privacy Privacy security Security contact Contact
  } {
    append html [format {<a%s href="#" data-hub-path="/%s">%s</a>} \
      [expr {$slug eq $active ? { aria-current="page"} : ""}] $slug $label]
  }
  append html {</nav>}
  return $html
}

proc ::fossilhub::views::publicDefinition {slug} {
  set pages [dict create \
    manual [dict create title {Field manual} heading {Read the strata} \
      lede {A practical map of FossilHub repositories and collaboration.} body {
        <section><h2>Start a repository</h2><p>Create an account, open your dashboard, and choose New repository. Public repositories appear in Explore and support unauthenticated clone/sync. Private repositories require central membership for browser access and are never exposed by the public transport gate.</p></section>
        <section><h2>Work in the browser</h2><p>Writers can create, edit, rename, and delete files and maintain Wiki pages. Triage members can open and update Tickets and participate in Forum threads. Every change carries an optimistic revision marker, a one-time form challenge, and a central audit record.</p></section>
        <section><h2>Work with Fossil</h2><p>Use the clone command shown on a public repository. FossilHub browser pages remain first-party; the guarded <code>/fossil/&lt;slug&gt;/</code> endpoint exists only for clone and sync transport.</p></section>}] \
    hosting [dict create title {Hosting} heading {Keep one durable artifact} \
      lede {FossilHub is self-hosted infrastructure, not a metered hosting storefront.} body {
        <section><h2>Deployment shape</h2><p>The supported deployment is an isolated, unprivileged container with a read-only root filesystem. Persistent platform data, catalogue data, and individual Fossil repository files live under one separately mounted data directory.</p></section>
        <section><h2>Backups and recovery</h2><p>Back up the platform and catalogue databases together with every <code>.fossil</code> artifact while the service is quiescent or through a storage snapshot. Archive is recoverable; quarantined data requires trusted operator inspection and is never restored blindly from the browser.</p></section>
        <section><h2>Capacity</h2><p>Administrators control repository counts and per-repository storage quotas. The health board reports aggregate thresholds without publishing filesystem paths or private repository names.</p></section>}] \
    upstream [dict create title {Upstream projects} heading {Built on bedrock} \
      lede {FossilHub combines small, independently useful upstream systems.} body {
        <section id="fossil"><h2>Fossil SCM</h2><p>Repository storage, distributed sync, check-ins, Wiki, Tickets, and Forum artifacts come from <a href="https://fossil-scm.org/" rel="external">Fossil SCM</a>. Fossil owns its repository schema; FossilHub uses supported CLI and CGI boundaries.</p></section>
        <section id="sqlite"><h2>SQLite</h2><p>The application-owned registry and catalogue use <a href="https://sqlite.org/" rel="external">SQLite</a>. Fossil repository databases are never opened directly for application writes.</p></section>
        <section><h2>Tcl, Wapp, and Althttpd</h2><p>Tcl renders complete HTML on the server, Wapp supplies the request boundary, and Althttpd launches the isolated CGI application. Exact source pins and provenance are maintained with the release source.</p></section>}] \
    rules [dict create title {Site rules} heading {Share the dig responsibly} \
      lede {Clear custody keeps a collaborative repository useful and recoverable.} body {
        <section><h2>Content and conduct</h2><p>Publish only material you have the right to share. Do not use repositories, Wiki, Tickets, or Forum posts for harassment, credential disclosure, malware delivery, or attempts to compromise the service or other people.</p></section>
        <section><h2>Repository custody</h2><p>Owners are responsible for collaborators and visibility. Administrators may disable access, archive a repository, or quarantine a damaged artifact when platform integrity or safety requires it. Those actions are recorded in the audit ledger.</p></section>
        <section><h2>Operational limits</h2><p>Repository counts, mutation sizes, and storage quotas are enforced to preserve service availability. Bypassing those limits or probing private repository names is prohibited.</p></section>}] \
    privacy [dict create title {Privacy} heading {Collect the minimum} \
      lede {FossilHub keeps identity and operational data narrow and local.} body {
        <section><h2>Account data</h2><p>The platform stores username, email, display name, optional public profile fields, password hash, session hashes, repository roles, and audit events. Email is private. Raw passwords, session tokens, and one-time challenge tokens are not stored.</p></section>
        <section><h2>Operational records</h2><p>Session metadata is reduced to hashed browser and address markers. Audit exports omit internal detail, request identifiers, submitted content, and credentials. Application logs are not exposed through the browser.</p></section>
        <section><h2>Account lifecycle</h2><p>You can edit profile data, revoke sessions, and deactivate your account from Settings. Repository custody is retained so shared history is not silently orphaned; an administrator can restore access when appropriate.</p></section>}] \
    security [dict create title {Security} heading {Fail closed at every layer} \
      lede {Identity, authorization, repository custody, and transport use separate boundaries.} body {
        <section><h2>Identity</h2><p>Passwords use Argon2id. Sessions are opaque, server-side, idle- and absolute-expiring, and rotated after password changes. State-changing forms use single-use challenges; administrator mutations additionally require recent password verification.</p></section>
        <section><h2>Repositories</h2><p>Private and unknown repositories return the same response. Browser reads use Fossil's read-only interface, writes use supported Fossil commands, and integrity failure removes an artifact from publication into quarantine.</p></section>
        <section><h2>Report a concern</h2><p>Do not post exploit details in a public repository. Use the private operator channel described on the Contact page and include the affected route, impact, and a minimal reproduction without credentials.</p></section>}] \
    contact [dict create title {Contact} heading {Reach the wardens} \
      lede {Use the trusted contact channel configured by the operator of this instance.} body {
        <section><h2>Account and repository help</h2><p>Include your username, the public repository slug when applicable, the time of the problem, and the action you attempted. Never send a password, session cookie, bootstrap record, or private repository content.</p></section>
        <section><h2>Security reports</h2><p>Mark the message as a security report and use a private channel. Describe impact first, then provide the smallest safe reproduction. This deployment intentionally does not invent or publish an operator address until one is configured outside the source tree.</p></section>
        <section><h2>Upstream issues</h2><p>Problems in Fossil SCM, SQLite, Tcl, Wapp, or Althttpd should be reproduced independently before being reported to the relevant upstream project.</p></section>}]]
  if {![dict exists $pages $slug]} {
    return ""
  }
  return [dict get $pages $slug]
}

proc ::fossilhub::views::renderPublicInformation {context slug page} {
  set content [format {%s<div class="public-document">%s</div>} \
    [::fossilhub::views::publicNavigation $slug] [dict get $page body]]
  return [::fossilhub::views::accountFrame [dict get $page title] \
    {FossilHub information} [dict get $page heading] [dict get $page lede] \
    $content $context]
}

proc ::fossilhub::views::renderReleases {context markdown version} {
  set page [dict create title Releases heading {Release history} \
    lede "Maintained notes for FossilHub $version and its retained baselines." \
    body [::fossilhub::markup::render $markdown text/x-markdown]]
  return [::fossilhub::views::renderPublicInformation $context releases $page]
}

proc ::fossilhub::views::renderPublicStatus {context health version banner} {
  set overall ok
  foreach key {platform_database catalogue_database} {
    if {[dict get $health $key] ne "ok"} {
      set overall degraded
    }
  }
  if {[dict get $health readable_repositories] != [dict get $health repository_count] ||
      ![dict get $health file_modes_ok]} {
    set overall degraded
  }
  set notice [expr {$banner eq "" ?
    "No maintenance notice is active." : $banner}]
  set body [format {
    <div class="public-status-summary"><span>Current state</span>%s<p>%s</p></div>
    <div class="health-grid public-health"><article><span>Platform data</span>%s</article><article><span>Catalogue</span>%s</article><article><span>Repository availability</span><b>%s / %s</b></article><article><span>Catalogue freshness</span><b>%s</b></article><article><span>Storage threshold</span>%s</article><article><span>Version</span><b>%s</b></article></div>
    <p class="public-safety-note">This board deliberately omits filesystem paths, private repository names, credentials, logs, and internal revision identifiers.</p>} \
    [::fossilhub::views::adminState $overall] \
    [::fossilhub::view::escape $notice] \
    [::fossilhub::views::adminState [dict get $health platform_database]] \
    [::fossilhub::views::adminState [dict get $health catalogue_database]] \
    [::fossilhub::view::escape [dict get $health readable_repositories]] \
    [::fossilhub::view::escape [dict get $health repository_count]] \
    [::fossilhub::view::escape [::fossilhub::view::formatDate \
      [dict get $health catalogue_indexed_epoch]]] \
    [::fossilhub::views::adminState [dict get $health storage_status]] \
    [::fossilhub::view::escape $version]]
  set page [dict create title Status heading {Platform status} \
    lede {A public, privacy-preserving summary of application health.} body $body]
  return [::fossilhub::views::renderPublicInformation $context status $page]
}
