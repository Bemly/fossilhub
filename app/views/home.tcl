namespace eval ::fossilhub::views {
variable homeTemplate {
<!doctype html>
<html lang="@@HTML_LANG@@">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>@@PAGE_TITLE@@</title>
<meta name="description" content="FossilHub is a hosting hub for Fossil repositories: code, wiki, tickets, forum and docs in a single versioned artifact.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@500;600;700;800&family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<script>document.documentElement.dataset.theme=localStorage.getItem("fh-theme")||(matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light");</script>
<link rel="stylesheet" href="fh.css?v=20260830-1">
</head>
<body data-repository-slug="@@REPOSITORY_SLUG@@">

<div class="rail" aria-hidden="true">
  <div class="rail-track"></div>
  <span class="rail-label" style="top:9%">0M</span>
  <span class="rail-label" style="top:30%">3M</span>
  <span class="rail-label" style="top:51%">6M</span>
  <span class="rail-label" style="top:72%">9M</span>
  <span class="rail-label" style="top:91%">12M</span>
  <div class="rail-ind" id="railInd"></div>
  <div class="rail-now" id="railNow">0.0M</div>
</div>

<header class="topbar">
  <div class="wrap">
    <a class="wordmark" href="#top" aria-label="FossilHub home">
      <img src="fossilhub-hub-lockup-v1.png?v=20260829-1" width="137" height="50" alt="FossilHub">
    </a>
    <nav class="topnav" aria-label="@@PRIMARY_NAV_LABEL@@">
      <a href="#timeline">@@NAV_TIMELINE@@</a>
      <a href="#wiki">@@NAV_WIKI@@</a>
      <a href="#tickets">@@NAV_TICKETS@@</a>
      <a href="#engine">@@NAV_ENGINE@@</a>
      <a href="explore.html">@@NAV_EXPLORE@@</a>
    </nav>
    @@SITE_TOOLS@@
    <button class="theme-btn" id="themeBtn" type="button" aria-label="@@THEME_LABEL@@">
      <svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13A8 8 0 1 1 11 4a6.5 6.5 0 0 0 9 9Z"/></svg>
      <svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5 5l1.5 1.5M17.5 17.5 19 19M19 5l-1.5 1.5M6.5 17.5 5 19"/></svg>
    </button>
    <span class="cmd-chip"><span class="p">$</span><span class="u" data-clone-command>fossil clone /fossil/dig</span></span>
  </div>
</header>

<main id="top">

  <section class="hero">
    <div class="wrap">
      <div class="hero-grid">
        <div>
          <p class="eyebrow">@@HOME_EYEBROW@@</p>
          <h1>@@HOME_HEADING@@</h1>
          <p class="lede">@@HOME_LEDE@@</p>
          <div class="cta-row">
            <a class="btn btn-primary" href="explore.html">@@EXPLORE_REPOSITORIES@@</a>
            <a class="btn btn-ghost" href="#engine">@@FIELD_MANUAL@@</a>
          </div>
        </div>
        <div class="core-wrap">
          <svg class="core" viewBox="0 0 380 600" role="img" aria-labelledby="coreTitle coreDesc">
            <title id="coreTitle">Core sample of a Fossil repository</title>
            <desc id="coreDesc">A vertical drill-core of layered strata with a check-in timeline running through it, including a branch that forks and merges back into the trunk.</desc>
            <defs>
              <clipPath id="coreClip"><rect x="70" y="24" width="250" height="552" rx="20"/></clipPath>
            </defs>
            <g clip-path="url(#coreClip)">
              <rect class="cs-band b1" x="70" y="24" width="250" height="104" fill="rgba(32,82,151,.09)"/>
              <rect class="cs-band b2" x="70" y="128" width="250" height="112" fill="rgba(47,110,90,.10)"/>
              <rect class="cs-band b3" x="70" y="240" width="250" height="94" fill="rgba(166,75,34,.07)"/>
              <rect class="cs-band b4" x="70" y="334" width="250" height="112" fill="rgba(32,82,151,.05)"/>
              <rect class="cs-band b5" x="70" y="446" width="250" height="130" fill="#DEE1D3"/>
              <path class="cs-seams" d="M70 128H320 M70 240H320 M70 334H320 M70 446H320" stroke="rgba(28,35,44,.14)" stroke-width="1"/>
            </g>
            <rect class="cs-frame" x="70" y="24" width="250" height="552" rx="20" fill="none" stroke="#1C232C" stroke-width="1.5"/>
            <g class="cs-ticks" stroke="rgba(28,35,44,.45)" stroke-width="1">
              <path d="M58 44H70 M58 156H70 M58 268H70 M58 380H70 M58 492H70"/>
            </g>
            <g class="cs-ticks" font-family="IBM Plex Mono,monospace" font-size="9.5" fill="#545F68" text-anchor="end">
              <text x="53" y="47">0m</text>
              <text x="53" y="159">2m</text>
              <text x="53" y="271">4m</text>
              <text x="53" y="383">6m</text>
              <text x="53" y="495">8m</text>
            </g>
            <path class="cs-line" d="M131 44C129 96 133 148 131 196C129 252 133 300 131 352C129 416 133 470 131 556" fill="none" stroke="#1C232C" stroke-width="1.5"/>
            <path class="cs-line" d="M131 196C176 202 228 208 232 240L232 372C232 404 182 420 137 428" fill="none" stroke="#205297" stroke-width="1.5"/>
            <path class="cs-line cs-stub" d="M131 468C158 474 178 480 192 490" fill="none" stroke="#545F68" stroke-width="1.3"/>
            <circle class="cs-node n1" cx="131" cy="64" r="5" fill="#205297"/>
            <circle class="cs-node n2" cx="131" cy="110" r="4.5" fill="#F4F5EC" stroke="#1C232C" stroke-width="1.4"/>
            <circle class="cs-node n3" cx="131" cy="196" r="6.5" fill="#F4F5EC" stroke="#1C232C" stroke-width="1.4"/>
            <circle class="cs-node n3" cx="131" cy="196" r="2.6" fill="#205297"/>
            <circle class="cs-node n4" cx="232" cy="300" r="4.5" fill="#2F6E5A"/>
            <circle class="cs-node n5" cx="131" cy="306" r="4.5" fill="#A64B22"/>
            <circle class="cs-node n6" cx="137" cy="428" r="4.5" fill="#F4F5EC" stroke="#1C232C" stroke-width="1.4"/>
            <circle class="cs-node n7" cx="194" cy="492" r="4" fill="none" stroke="#545F68" stroke-width="1.3" stroke-dasharray="3 2.5"/>
            <g class="cs-tag t1">
              <path d="M139 64H198" stroke="rgba(28,35,44,.4)" stroke-width="1"/>
              <text x="204" y="67.5" font-family="IBM Plex Mono,monospace" font-size="10" fill="#545F68">c-9f2e1a · check-in</text>
            </g>
            <g class="cs-tag t2">
              <path d="M139 196H186" stroke="rgba(28,35,44,.4)" stroke-width="1"/>
              <text x="192" y="199.5" font-family="IBM Plex Mono,monospace" font-size="10" fill="#545F68">fork → delta-v2</text>
            </g>
            <g class="cs-tag t3">
              <path d="M139 306H186" stroke="rgba(28,35,44,.4)" stroke-width="1"/>
              <text x="192" y="309.5" font-family="IBM Plex Mono,monospace" font-size="10" fill="#545F68">ticket #42 closed</text>
            </g>
            <g class="cs-tag t4">
              <path d="M240 300H290" stroke="rgba(28,35,44,.4)" stroke-width="1"/>
              <text x="240" y="290" font-family="IBM Plex Mono,monospace" font-size="10" fill="#545F68">wiki edit</text>
            </g>
            <g class="cs-tag t5">
              <text x="204" y="495.5" font-family="IBM Plex Mono,monospace" font-size="10" fill="#545F68">abandoned</text>
            </g>
            <text class="cs-bedrock" x="195" y="566" text-anchor="middle" font-family="IBM Plex Mono,monospace" font-size="9" letter-spacing="4" fill="#545F68">BEDROCK</text>
          </svg>
          <div class="legend" aria-hidden="true">
            <span><i class="dot dot-azu"></i>check-in</span>
            <span><i class="dot dot-verdi"></i>wiki edit</span>
            <span><i class="dot dot-iron"></i>ticket</span>
          </div>
        </div>
      </div>

      <div class="stats reveal">
        <div class="stat"><b>1</b><span>self-contained executable</span></div>
        <div class="stat"><b>0</b><span>external dependencies</span></div>
        <div class="stat"><b>2007</b><span>first check-in by D.&nbsp;R.&nbsp;Hipp</span></div>
        <div class="stat"><b>100%</b><span>of history in every clone</span></div>
      </div>
    </div>
  </section>

  <div class="unconformity" aria-hidden="true">
    <svg viewBox="0 0 1200 24" preserveAspectRatio="none"><path d="M0 12 C 60 4 140 20 240 13 C 340 6 420 18 520 12 C 620 6 700 20 800 13 C 900 6 1000 18 1100 12 C 1150 9 1190 14 1200 11"/></svg>
  </div>

  <section class="stratum band-b" id="timeline">
    <div class="wrap">
      <div class="sec-head reveal">
        <p class="eyebrow">Stratum 01 · Timeline</p>
        <h2>One thread for everything that happened.</h2>
        <p class="lede">Check-ins, ticket changes, wiki edits, and forum posts land on a single chronological timeline — with forks and merges drawn as they happen.</p>
      </div>
      <div class="demo-grid reveal">
        <div class="copy">
          <p>No tab-switching between tools. The timeline is the project's complete field journal: who changed what, when a bug was closed, which page was rewritten — all in one scroll, all searchable from one box.</p>
        </div>
        <div class="panel">
          <div class="panel-head">
            <span class="fname">@@REPOSITORY_NAME@@ — recent activity</span>
            <span class="chip chip-azu"><span class="sdot"></span>live</span>
          </div>
          @@HOME_TIMELINE@@
        </div>
      </div>
    </div>
  </section>

  <div class="unconformity" aria-hidden="true">
    <svg viewBox="0 0 1200 24" preserveAspectRatio="none"><path d="M0 14 C 80 20 160 6 260 12 C 360 18 440 5 540 11 C 640 17 720 6 820 12 C 920 18 1010 7 1100 13 C 1150 16 1185 10 1200 12"/></svg>
  </div>

  <section class="stratum" id="wiki">
    <div class="wrap">
      <div class="sec-head reveal">
        <p class="eyebrow">Stratum 02 · Wiki + embedded docs</p>
        <h2>Documentation that checks out with the code.</h2>
        <p class="lede">The wiki and the docs tree version alongside source. Check out any commit and the manuals match it exactly — no drift between release notes and reality.</p>
      </div>
      <div class="demo-grid flip reveal">
        <div class="panel">
          <div class="panel-head">
            <span class="fname">www/autosync.wiki</span>
            <span class="chip chip-azu"><span class="sdot"></span>v214 @ c-9f2e1a</span>
          </div>
          <div class="panel-body doc-body">
            <h3>Autosync</h3>
            <p>With autosync enabled, every commit is shared with the remote peer the moment it is made. Work offline for days; the next connection reconciles both histories automatically.</p>
            <p class="doc-foot">last edited in-browser · saved as commit c-7b1d03</p>
          </div>
        </div>
        <div class="copy">
          <p>Edit pages from the browser or from your checkout — either path saves a real commit with a real hash. A wiki page is never “just content”: it is an artifact in the repository like everything else.</p>
        </div>
      </div>
    </div>
  </section>

  <div class="unconformity" aria-hidden="true">
    <svg viewBox="0 0 1200 24" preserveAspectRatio="none"><path d="M0 11 C 70 18 150 5 250 12 C 350 19 430 7 530 13 C 630 19 710 5 810 12 C 910 19 1000 8 1090 13 C 1145 16 1180 10 1200 12"/></svg>
  </div>

  <section class="stratum band-b" id="tickets">
    <div class="wrap">
      <div class="sec-head reveal">
        <p class="eyebrow">Stratum 03 · Tickets + forum</p>
        <h2>The bug tracker never leaves the repository.</h2>
        <p class="lede">Tickets and forum threads travel inside the same artifact as the code. Clone the repo, get its whole history of arguments.</p>
      </div>
      <div class="demo-grid reveal">
        <div class="copy">
          <p>Every ticket change and every forum reply becomes part of the timeline you already read. Mirror a project to a laptop before a flight and its open questions fly with you.</p>
        </div>
        <div class="panel">
          <div class="panel-head">
            <span class="fname">Ticket #42</span>
            <span class="chip chip-verdi"><span class="sdot"></span>closed</span>
          </div>
          <div class="panel-body">
            <p class="ticket-title">Sync stalls on flaky links</p>
            <p class="ticket-meta">opened by r.hipp · 3 linked check-ins · severity 1</p>
            <p class="ticket-desc">Delta push retries forever when the tunnel drops mid-round-trip. Reproduces on satellite uplinks every time.</p>
            <div class="forum-split">
              <p class="forum-label">Forum · thread 118</p>
              <div class="post">
                <span class="avatar" aria-hidden="true">DR</span>
                <div>
                  <p class="post-name">d.r.hipp<span class="post-time">09:41</span></p>
                  <p class="post-text">Fixed for 2.26 — the retry now backs off and resyncs cleanly. Closing after the next merge test.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <div class="unconformity" aria-hidden="true">
    <svg viewBox="0 0 1200 24" preserveAspectRatio="none"><path d="M0 13 C 90 7 170 19 270 12 C 370 5 450 17 550 12 C 650 7 730 19 830 12 C 930 5 1020 18 1110 12 C 1155 9 1190 15 1200 11"/></svg>
  </div>

  <section class="stratum" id="engine">
    <div class="wrap">
      <div class="sec-head reveal">
        <p class="eyebrow">Stratum 04 · The engine</p>
        <h2>One binary does the work of a rack.</h2>
        <p class="lede">A single static executable initializes, serves, syncs, and renders. Point it at a file and it becomes the forge.</p>
      </div>
      <div class="demo-grid flip reveal">
        <div class="term">
          <div class="term-head">@@REPOSITORY_NAME@@ — fossil shell</div>
<pre>$ fossil init @@REPOSITORY_NAME@@
<span class="dim">  project-id:</span> <span class="lit">@@PROJECT_ID@@</span> <span class="dim">· repository artifact</span>

$ fossil ui
<span class="dim">  serving</span> <span class="lit">http://127.0.0.1:8080</span> <span class="dim">(repo: @@REPOSITORY_NAME@@)</span>

$ <span data-clone-command>fossil clone /fossil/dig</span>
<span class="dim">  @@ARTIFACTS@@ artifacts · @@DEPTH@@ received</span>
<span class="dim">  history:</span> @@CHECKINS@@ check-ins · @@EVENTS@@ timeline events</pre>
          <div class="term-note">No daemons, no config files, no database server. The web UI ships inside the same binary that stores the data.</div>
        </div>
        <div class="copy">
          <p>Distributed when you want it, centralized when you need it: peers sync directly over HTTP(S) in autosync mode, while a single server can host hundreds of projects. Backup is one file copy.</p>
        </div>
      </div>
    </div>
  </section>

</main>

<footer class="bedrock" id="about">
  <div class="wrap">
    <p class="eyebrow">Bedrock · Nothing below this line</p>
    <p class="giant-mark" aria-hidden="true">Fossilhub</p>
    <div class="bedrock-grid">
      <div>
        <h4>Start a dig</h4>
        <ul>
          <li><a href="explore" data-hub-path="/explore">Browse repositories</a></li>
          <li><a href="manual" data-hub-path="/manual">Field manual</a></li>
          <li><a href="hosting" data-hub-path="/hosting">Hosting</a></li>
        </ul>
        <span class="clone-dark"><span class="p">$</span><span class="u" data-clone-command>fossil clone /fossil/dig</span></span>
      </div>
      <div>
        <h4>Upstream</h4>
        <ul>
          <li><a href="upstream#fossil" data-hub-path="/upstream#fossil">Fossil SCM</a></li>
          <li><a href="upstream#sqlite" data-hub-path="/upstream#sqlite">SQLite, the sibling project</a></li>
          <li><a href="releases" data-hub-path="/releases">Release history</a></li>
        </ul>
      </div>
      <div>
        <h4>The hub</h4>
        <ul>
          <li><a href="rules" data-hub-path="/rules">Site rules</a></li>
          <li><a href="status" data-hub-path="/status">Status board</a></li>
          <li><a href="contact" data-hub-path="/contact">Contact the wardens</a></li>
        </ul>
      </div>
    </div>
    <div class="bedrock-bottom">
      <span>© 2026 FOSSILHUB — SURVEY DRAWING NO. FH-26-08</span>
      <span><a href="privacy" data-hub-path="/privacy">Privacy</a> · <a href="security" data-hub-path="/security">Security</a> · SET IN BIG SHOULDERS &amp; IBM PLEX</span>
    </div>
  </div>
</footer>

<script src="fossilhub-live.js?v=20260828-3"></script>
<script>
document.documentElement.classList.add('js');
const io = new IntersectionObserver((entries) => {
  entries.forEach((e) => {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
  });
}, { threshold: 0.15 });
document.querySelectorAll('.reveal').forEach((el) => io.observe(el));
const ind = document.getElementById('railInd');
const now = document.getElementById('railNow');
addEventListener('scroll', () => {
  const h = document.documentElement;
  const f = Math.min(1, Math.max(0, h.scrollTop / (h.scrollHeight - h.clientHeight)));
  ind.style.top = `calc(${(f * 100).toFixed(2)}% )`;
  now.textContent = `${(f * 12).toFixed(1)}M`;
}, { passive: true });

const themeBtn = document.getElementById('themeBtn');
themeBtn.addEventListener('click', () => {
  const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
  document.documentElement.dataset.theme = next;
  localStorage.setItem('fh-theme', next);
});
</script>

</body>
</html>
}
}

proc ::fossilhub::views::renderHome {repository {context ""}} {
  variable homeTemplate
  set eventCount [expr {
    [dict get $repository checkins] +
    [dict get $repository wiki_events] +
    [dict get $repository ticket_events] +
    [dict get $repository forum_events]
  }]
  return [string map [list \
    @@HTML_LANG@@ [::fossilhub::i18n::locale] \
    @@PAGE_TITLE@@ [::fossilhub::view::escape [::fossilhub::i18n::t home_title]] \
    @@PRIMARY_NAV_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t primary_navigation]] \
    @@NAV_TIMELINE@@ [::fossilhub::view::escape [::fossilhub::i18n::t timeline]] \
    @@NAV_WIKI@@ [::fossilhub::view::escape [::fossilhub::i18n::t wiki]] \
    @@NAV_TICKETS@@ [::fossilhub::view::escape [::fossilhub::i18n::t tickets]] \
    @@NAV_ENGINE@@ [::fossilhub::view::escape [::fossilhub::i18n::t engine]] \
    @@NAV_EXPLORE@@ [::fossilhub::view::escape [::fossilhub::i18n::t explore]] \
    @@THEME_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t theme_toggle]] \
    @@HOME_EYEBROW@@ [::fossilhub::view::escape [::fossilhub::i18n::t home_eyebrow]] \
    @@HOME_HEADING@@ [::fossilhub::i18n::t home_heading] \
    @@HOME_LEDE@@ [::fossilhub::view::escape [::fossilhub::i18n::t home_lede]] \
    @@EXPLORE_REPOSITORIES@@ [::fossilhub::view::escape [::fossilhub::i18n::t explore_repositories]] \
    @@FIELD_MANUAL@@ [::fossilhub::view::escape [::fossilhub::i18n::t field_manual]] \
    @@SITE_TOOLS@@ [::fossilhub::views::siteTools $context] \
    @@REPOSITORY_SLUG@@ [::fossilhub::view::escape [dict get $repository slug]] \
    @@REPOSITORY_NAME@@ [::fossilhub::view::escape [dict get $repository name]] \
    @@PROJECT_ID@@ [::fossilhub::view::escape \
      [::fossilhub::view::projectId $repository]] \
    @@ARTIFACTS@@ [::fossilhub::view::formatCount \
      [dict get $repository artifacts]] \
    @@DEPTH@@ [::fossilhub::view::escape [::fossilhub::view::formatBytes \
      [dict get $repository bytes]]] \
    @@CHECKINS@@ [::fossilhub::view::formatCount \
      [dict get $repository checkins]] \
    @@EVENTS@@ [::fossilhub::view::formatCount $eventCount] \
    @@HOME_TIMELINE@@ [::fossilhub::view::homeTimeline $repository]] \
    $homeTemplate]
}
