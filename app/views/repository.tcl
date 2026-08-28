namespace eval ::fossilhub::views {
variable repositoryTemplate {
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>@@REPOSITORY_NAME@@ — FossilHub</title>
<meta name="description" content="dig.fossil on FossilHub — timeline, wiki, tickets and forum inside one artifact.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@500;600;700;800&family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<script>document.documentElement.dataset.theme=localStorage.getItem("fh-theme")||(matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light");</script>
<link rel="stylesheet" href="fh.css">
<style>
.chip-plain{color:var(--ink-2);border-color:var(--line);background:transparent}
.crumb-row{
  display:flex;align-items:center;justify-content:space-between;gap:16px;
  padding-top:28px;
}
.crumb{font-family:var(--font-mono);font-size:11px;letter-spacing:.14em;color:var(--ink-2)}
.crumb b{color:var(--ink);font-weight:500}
.mast-grid{
  display:grid;grid-template-columns:minmax(0,1fr) 300px;
  gap:clamp(28px,4vw,56px);align-items:start;
  padding-block:26px 40px;
}
.repo-title h1{
  font-family:var(--font-display);font-weight:700;text-transform:uppercase;
  font-size:clamp(2.6rem,4.5vw,3.8rem);line-height:.95;letter-spacing:.01em;
}
.repo-title .desc{margin-top:12px;color:var(--ink-2);max-width:56ch;font-size:15.5px}
.chip-row{display:flex;gap:10px;margin-top:16px;flex-wrap:wrap}
.clone-row{display:flex;gap:12px;margin-top:20px;flex-wrap:wrap;align-items:center}
.clone-row .cmd-chip{max-width:100%;overflow:hidden}
.btn-sm{padding:9px 16px;font-size:13px}
.label-card{
  background:var(--card);border:1.5px solid var(--ink);border-radius:5px;
  padding:34px 20px 14px;position:relative;transform:rotate(-.8deg);
  box-shadow:4px 5px 0 rgba(28,35,44,.14);
}
.label-card::before{
  content:"";position:absolute;top:11px;left:50%;transform:translateX(-50%);
  width:11px;height:11px;border-radius:50%;
  border:1.5px solid var(--ink);background:var(--paper);
}
.lab-tag{
  position:absolute;top:-9px;left:50%;transform:translateX(-50%);
  background:var(--iron);color:var(--paper);
  font-family:var(--font-mono);font-size:8.5px;letter-spacing:.22em;
  padding:3px 10px 2px;border-radius:2px;
}
.lab-row{
  display:flex;justify-content:space-between;gap:12px;
  font-family:var(--font-mono);font-size:10.5px;padding:7px 0;
  border-top:1px dashed var(--line);
}
.lab-row:first-of-type{border-top:none}
.lab-k{color:var(--ink-2);letter-spacing:.08em;flex:none}
.lab-v{color:var(--ink);text-align:right}
.mast-stats{border-top:1px solid var(--line);padding-block:24px 30px}

.repo-body{padding-block:0 100px}
.tabbar{
  position:sticky;top:60px;z-index:30;background:var(--paper);
  border-bottom:1px solid var(--line);
  display:flex;gap:26px;overflow-x:auto;
}
.tab{
  font-family:var(--font-mono);font-size:11.5px;letter-spacing:.12em;
  text-transform:uppercase;color:var(--ink-2);
  padding:16px 2px 13px;border-bottom:2px solid transparent;white-space:nowrap;
}
.tab:hover{color:var(--ink);text-decoration:none}
.tab.active{color:var(--ink);border-color:var(--azurite)}
.tab .n{color:rgba(28,35,44,.42)}
.body-grid{
  display:grid;grid-template-columns:minmax(0,1fr) 320px;
  gap:clamp(32px,4vw,56px);align-items:start;padding-top:0;
}
.filters{
  display:flex;align-items:center;gap:8px;margin:22px 0 14px;flex-wrap:wrap;
}
.fchip{
  font-family:var(--font-mono);font-size:11px;padding:6px 13px;
  border:1px solid var(--line);border-radius:999px;color:var(--ink-2);background:transparent;
}
.fchip.sel{border-color:var(--azurite);color:var(--azurite-deep);background:rgba(32,82,151,.08)}
.tl-legend{margin-left:auto;display:flex;gap:14px;flex-wrap:wrap}
.tl-legend span{
  display:inline-flex;align-items:center;gap:6px;
  font-family:var(--font-mono);font-size:9.5px;letter-spacing:.1em;
  text-transform:uppercase;color:var(--ink-2);
}
.rv-panel .panel-body{padding:0}
.day-h{
  height:40px;display:flex;align-items:center;padding:0 18px;
  background:var(--paper-2);border-bottom:1px solid var(--line);
  font-family:var(--font-mono);font-size:10px;letter-spacing:.2em;color:var(--ink-2);
}
.rv-list{position:relative}
.rv-svg{position:absolute;left:0;top:0;width:56px;height:600px;pointer-events:none}
.rv-row{
  position:relative;height:52px;display:grid;
  grid-template-columns:56px 48px minmax(0,1fr) auto;
  align-items:center;padding-right:18px;
  border-bottom:1px dashed rgba(28,35,44,.09);
}
.rv-time{font-family:var(--font-mono);font-size:10.5px;color:var(--ink-2)}
.rv-title{font-size:13.5px;font-weight:500;line-height:1.3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;padding-right:14px}
.rv-meta{font-family:var(--font-mono);font-size:10.5px;color:var(--ink-2);margin-top:2px}
.rv-end{display:flex;align-items:center;gap:10px}
.rv-hash{
  font-family:var(--font-mono);font-size:10.5px;color:var(--azurite-deep);
  border:1px solid rgba(32,82,151,.3);background:rgba(32,82,151,.05);
  padding:2px 7px;border-radius:4px;white-space:nowrap;
}
.rv-user{
  width:24px;height:24px;border-radius:50%;flex:none;
  background:var(--ink);color:var(--paper);
  font-family:var(--font-mono);font-size:8.5px;
  display:grid;place-items:center;
}
.deeper{
  display:block;text-align:center;font-family:var(--font-mono);
  font-size:11px;letter-spacing:.16em;color:var(--ink-2);padding:16px;
}
.deeper:hover{color:var(--ink);text-decoration:none;background:var(--paper-2)}

.side{display:grid;gap:20px;position:sticky;top:126px}
.side .panel-head{padding:11px 18px}
.side .panel-head .fname{font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:var(--ink-2)}
.comp-rows{margin-top:13px;display:grid;gap:7px}
.comp-row{
  display:flex;justify-content:space-between;align-items:center;gap:10px;
  font-family:var(--font-mono);font-size:10.5px;color:var(--ink-2);
}
.comp-row .l{display:inline-flex;align-items:center;gap:8px}
.comp-row i{width:9px;height:9px;border-radius:2px;flex:none}
.comp-note{margin-top:12px;font-size:12px;color:var(--ink-2)}
.br-row,.peer-row{
  display:flex;align-items:center;gap:10px;padding:9px 0;
  border-top:1px dashed var(--line);font-family:var(--font-mono);font-size:11px;
}
.br-row:first-child,.peer-row:first-child{border-top:none}
.swatch{width:16px;height:3px;border-radius:2px;flex:none}
.br-name{min-width:118px;color:var(--ink)}
.br-tip{color:var(--ink-2);margin-left:auto;text-align:right}
.peer-dot{width:8px;height:8px;border-radius:50%;flex:none}
.pulse{animation:ping 2.4s infinite}
@keyframes ping{
  0%{box-shadow:0 0 0 0 rgba(47,110,90,.45)}
  70%{box-shadow:0 0 0 7px rgba(47,110,90,0)}
  100%{box-shadow:0 0 0 0 rgba(47,110,90,0)}
}
.peer-name{color:var(--ink)}
.peer-state{color:var(--ink-2);margin-left:auto;text-align:right}
.sync-cap{margin-top:10px;font-size:12px;color:var(--ink-2)}
.section-lede{margin:26px 0 14px}
.section-lede>p:not(.eyebrow){margin-top:7px;color:var(--ink-2);font-size:13.5px}
.section-lede h2{
  margin-top:8px;font-family:var(--font-display);font-size:clamp(1.7rem,3vw,2.35rem);
  line-height:1;text-transform:uppercase;overflow-wrap:anywhere;
}
.back-link{display:inline-block;margin-bottom:16px;font-family:var(--font-mono);font-size:11px;color:var(--azurite-deep)}
.artifact-list{overflow:hidden}
.artifact-row{
  display:grid;grid-template-columns:44px minmax(0,1fr) auto 86px;gap:14px;
  align-items:center;min-height:64px;padding:10px 16px;border-top:1px dashed var(--line);
  color:inherit;text-decoration:none;
}
.artifact-row:first-child{border-top:0}
a.artifact-row:hover{background:var(--paper-2);text-decoration:none}
.artifact-mark{
  width:32px;height:32px;display:grid;place-items:center;border:1px solid var(--line);
  border-radius:50%;font-family:var(--font-mono);font-size:8px;text-transform:uppercase;color:var(--azurite-deep);
}
.wiki-mark{color:var(--verdi)}
.artifact-main{min-width:0}
.artifact-main b{display:block;font-size:13px;overflow-wrap:anywhere}
.artifact-main small{display:block;margin-top:3px;font-family:var(--font-mono);font-size:9.5px;color:var(--ink-2);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.artifact-size,.artifact-hash{font-family:var(--font-mono);font-size:10px;color:var(--ink-2);white-space:nowrap}
.artifact-hash{color:var(--azurite-deep);text-align:right}
.source-panel{overflow:auto;max-height:72vh}
.source-panel pre,.prose-artifact pre{
  margin:0;padding:20px;font-family:var(--font-mono);font-size:12px;line-height:1.65;
  white-space:pre;tab-size:2;color:var(--ink);
}
.prose-artifact pre{white-space:pre-wrap;overflow-wrap:anywhere}
.content-note{margin:0 0 10px;font-family:var(--font-mono);font-size:10px;color:var(--iron)}
.empty-stratum{color:var(--ink-2)}
.section-lede-actions,.section-title-actions{display:flex;justify-content:space-between;gap:18px;align-items:flex-end}
.section-actions{display:flex;gap:8px;flex-wrap:wrap;justify-content:flex-end}
.timeline-filter-form{
  display:grid;grid-template-columns:2fr 1.2fr 1fr 1fr 1fr 1fr auto;
  gap:10px;align-items:end;margin:0 0 16px;padding:14px;border:1px solid var(--line);
  border-radius:5px;background:var(--card);
}
.timeline-filter-form label,.revision-selector label{
  display:grid;gap:5px;font-family:var(--font-mono);font-size:9px;
  letter-spacing:.08em;text-transform:uppercase;color:var(--ink-2);
}
.timeline-filter-form input,.timeline-filter-form select,.revision-selector select{
  width:100%;min-width:0;border:1px solid var(--line);border-radius:4px;
  background:var(--paper);color:var(--ink);padding:8px 9px;font:11px var(--font-mono);
}
.timeline-results .artifact-mark{font-size:9px}
.tree-crumbs{display:flex;gap:7px;align-items:center;flex-wrap:wrap;margin-top:8px;font:12px var(--font-mono)}
.revision-selector{display:flex;gap:8px;align-items:end;min-width:min(100%,310px)}
.rendered-markup{padding:22px;line-height:1.7;overflow-wrap:anywhere}
.rendered-markup h1,.rendered-markup h2,.rendered-markup h3,.rendered-markup h4,.rendered-markup h5,.rendered-markup h6{
  margin:1.15em 0 .45em;font-family:var(--font-display);line-height:1.08;text-transform:none;
}
.rendered-markup h1:first-child,.rendered-markup h2:first-child,.rendered-markup h3:first-child{margin-top:0}
.rendered-markup p,.rendered-markup ul,.rendered-markup ol,.rendered-markup blockquote,.rendered-markup pre{margin:.8em 0}
.rendered-markup ul,.rendered-markup ol{padding-left:24px}
.rendered-markup blockquote{border-left:3px solid var(--azurite);padding-left:14px;color:var(--ink-2)}
.rendered-markup pre{padding:14px;background:var(--paper-2);overflow:auto}
.relation-panel{display:grid;gap:12px}
.relation-row{display:grid;grid-template-columns:80px 1fr;gap:12px;align-items:start}
.relation-row>div{display:flex;gap:7px;flex-wrap:wrap}
.relation-chip{font:10px var(--font-mono);padding:5px 8px;border:1px solid var(--line);border-radius:4px}
.muted-value{color:var(--ink-2)}
.diff-line{display:block;min-height:1.5em}.diff-line i{display:inline-block;width:22px;font-style:normal;user-select:none}
.diff-added{background:rgba(47,110,90,.12)}.diff-deleted{background:rgba(166,75,34,.12)}
.ticket-facts{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:10px;margin-bottom:14px}
.ticket-facts>div,.stat-card{border:1px solid var(--line);background:var(--card);padding:12px;border-radius:4px}
.ticket-facts span,.stat-card span{display:block;font:9px var(--font-mono);letter-spacing:.1em;text-transform:uppercase;color:var(--ink-2)}
.ticket-facts b,.stat-card b{display:block;margin-top:5px}
.history-list{overflow:hidden}.history-event{padding:16px;border-top:1px dashed var(--line)}.history-event:first-child{border-top:0}
.history-event header,.forum-thread-post header{display:flex;justify-content:space-between;gap:12px;margin-bottom:10px}
.history-event header span,.forum-thread-post header span{font:9.5px var(--font-mono);color:var(--ink-2)}
.ticket-change+.ticket-change{border-top:1px dashed var(--line);margin-top:10px;padding-top:10px}
.forum-thread{overflow:hidden}.forum-thread-post{padding:18px;border-top:1px dashed var(--line)}.forum-thread-post:first-child{border-top:0}
.forum-thread-post header{justify-content:flex-start;align-items:center}.forum-thread-post header>div:nth-child(2){display:grid}
.statistics-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin-bottom:16px}
.ticket-state{font-family:var(--font-mono);font-size:9px;text-transform:uppercase;text-align:center}
.ticket-open{color:var(--iron)}
.ticket-closed{color:var(--verdi)}
.forum-list{overflow:hidden}
.forum-post{display:grid;grid-template-columns:36px minmax(0,1fr) auto;gap:14px;align-items:start;padding:16px;border-top:1px dashed var(--line)}
.forum-post{color:inherit;text-decoration:none}.forum-post:hover{background:var(--paper-2);text-decoration:none}
.forum-post:first-child{border-top:0}
.forum-post h3{font-size:13.5px;line-height:1.45}
.forum-post p,.forum-post time{margin-top:4px;font-family:var(--font-mono);font-size:9.5px;color:var(--ink-2)}

[data-theme="dark"] .rv-svg [stroke="rgba(28,35,44,.45)"]{stroke:rgba(232,234,223,.45)}
[data-theme="dark"] .rv-svg [stroke="#205297"]{stroke:#7AA5E4}
[data-theme="dark"] .rv-svg [stroke="#2F6E5A"]{stroke:#5FB394}
[data-theme="dark"] .rv-svg [fill="#205297"]{fill:#7AA5E4}
[data-theme="dark"] .rv-svg [fill="#A64B22"]{fill:#D98A57}
[data-theme="dark"] .rv-svg [fill="#2F6E5A"]{fill:#5FB394}
[data-theme="dark"] .rv-svg [fill="#F4F5EC"]{fill:#202834}
[data-theme="dark"] .rv-svg [stroke="#1C232C"]{stroke:#E8EADF}
[data-theme="dark"] .rv-svg [fill="#1C232C"]{fill:#E8EADF}
[data-theme="dark"] .rv-row{border-bottom-color:rgba(232,234,223,.1)}
[data-theme="dark"] .label-card{box-shadow:4px 5px 0 rgba(0,0,0,.5)}

@media (max-width:1140px){
  .body-grid{grid-template-columns:1fr}
  .side{position:static;grid-template-columns:repeat(auto-fit,minmax(270px,1fr))}
}
@media (max-width:980px){
  .mast-grid{grid-template-columns:1fr}
  .label-card{max-width:380px}
  .timeline-filter-form{grid-template-columns:repeat(3,minmax(0,1fr))}
}
@media (max-width:640px){
  .rv-row{grid-template-columns:56px 40px minmax(0,1fr) auto}
  .rv-hash{display:none}
  .tl-legend{margin-left:0;width:100%}
  .artifact-row{grid-template-columns:38px minmax(0,1fr) auto;padding-inline:12px}
  .artifact-size{display:none}
  .artifact-hash{font-size:9px}
  .forum-post{grid-template-columns:32px minmax(0,1fr)}
  .forum-post time{grid-column:2}
  .timeline-filter-form{grid-template-columns:1fr 1fr}
  .timeline-filter-form label:first-of-type{grid-column:1/-1}
  .section-lede-actions,.section-title-actions{align-items:flex-start;flex-direction:column}
  .section-actions{justify-content:flex-start}
  .revision-selector{width:100%}
}
</style>
</head>
<body data-repository-slug="@@REPOSITORY_SLUG@@" data-repository-visibility="@@VISIBILITY@@">

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
    <a class="wordmark" href="index.html" aria-label="FossilHub home">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" aria-hidden="true">
        <path d="M12 12a1.1 1.1 0 0 1 1.1 1.1A2.2 2.2 0 0 1 10.9 15.3 3.6 3.6 0 0 1 7.3 11.7 5.2 5.2 0 0 1 12.5 6.5 7 7 0 0 1 19.5 13.5"/>
      </svg>
      <b>Fossilhub</b>
    </a>
    <nav class="topnav" aria-label="Repository">
      <a href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/timeline">Timeline</a>
      <a href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/files">Files</a>
      <a href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/wiki">Wiki</a>
      <a href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/tickets">Tickets</a>
      <a href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/forum">Forum</a>
    </nav>
    <button class="theme-btn" id="themeBtn" type="button" aria-label="Toggle color theme">
      <svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13A8 8 0 1 1 11 4a6.5 6.5 0 0 0 9 9Z"/></svg>
      <svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5 5l1.5 1.5M17.5 17.5 19 19M19 5l-1.5 1.5M6.5 17.5 5 19"/></svg>
    </button>
    @@HEADER_TRANSPORT@@
  </div>
</header>

<main>

  <section class="masthead">
    <div class="wrap">
      <div class="crumb-row">
        <p class="crumb">FOSSILHUB ▸ DIGS ▸ <b>@@REPOSITORY_UPPER@@</b></p>
        <span class="chip chip-plain"><span class="sdot"></span>@@VISIBILITY_UPPER@@ · LIVE FOSSIL 2.29</span>
      </div>
      <div class="mast-grid">
        <div class="repo-title">
          <h1>@@REPOSITORY_NAME@@</h1>
          <p class="desc">@@DESCRIPTION@@</p>
          <div class="chip-row">
            <span class="chip chip-verdi"><span class="sdot"></span>live Fossil artifact</span>
            <span class="chip chip-azu"><span class="sdot"></span>Tcl server-rendered</span>
            <span class="chip chip-plain"><span class="sdot"></span>updated @@RELATIVE_TIME@@</span>
          </div>
          <div class="clone-row">
            @@MAIN_TRANSPORT@@
            <a class="btn btn-ghost btn-sm" href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/files">Survey trunk files</a>
          </div>
        </div>
        <aside class="label-card reveal" aria-label="Specimen label">
          <span class="lab-tag">SPECIMEN LABEL</span>
          <div class="lab-row"><span class="lab-k">SITE ID</span><span class="lab-v">@@PROJECT_ID@@</span></div>
          <div class="lab-row"><span class="lab-k">PROJECT</span><span class="lab-v">@@PROJECT_NAME@@</span></div>
          <div class="lab-row"><span class="lab-k">OPENED</span><span class="lab-v">@@OPENED_DATE@@</span></div>
          <div class="lab-row"><span class="lab-k">LAST FIND</span><span class="lab-v">@@LAST_FIND@@</span></div>
          <div class="lab-row"><span class="lab-k">ARTIFACTS</span><span class="lab-v">@@ARTIFACTS@@</span></div>
          <div class="lab-row"><span class="lab-k">DEPTH</span><span class="lab-v">@@DEPTH@@</span></div>
          <div class="lab-row"><span class="lab-k">SOURCE</span><span class="lab-v">Fossil read-only SQL</span></div>
          <div class="lab-row"><span class="lab-k">RENDERER</span><span class="lab-v">Tcl 9.1 + Wapp</span></div>
        </aside>
      </div>
      <div class="stats mast-stats">
        <div class="stat"><b>@@ARTIFACTS@@</b><span>artifacts in one file</span></div>
        <div class="stat"><b>@@WIKI_EVENTS@@</b><span>wiki versions</span></div>
        <div class="stat"><b>@@OPEN_TICKETS@@</b><span>open tickets</span></div>
        <div class="stat"><b>@@CONTRIBUTORS@@</b><span>contributors</span></div>
      </div>
    </div>
  </section>

  <section class="repo-body" id="tl">
    <div class="tabbar">
      <div class="wrap" style="display:flex;gap:26px">
        <a class="tab @@TAB_TIMELINE@@" href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/timeline">Timeline</a>
        <a class="tab @@TAB_FILES@@" href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/files">Files</a>
        <a class="tab @@TAB_DOCS@@" href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/docs">Docs</a>
        <a class="tab @@TAB_WIKI@@" href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/wiki">Wiki <span class="n">@@WIKI_EVENTS@@</span></a>
        <a class="tab @@TAB_TICKETS@@" href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/tickets">Tickets <span class="n">@@OPEN_TICKETS@@ open</span></a>
        <a class="tab @@TAB_FORUM@@" href="#" data-hub-path="/repo/@@REPOSITORY_NAME@@/forum">Forum <span class="n">@@FORUM_EVENTS@@</span></a>
      </div>
    </div>

    <div class="wrap body-grid">
      <div>
        <!--SSR_SECTION_START-->
        <!--SSR_SECTION_END-->
      </div>

      <aside class="side">
        <div class="panel reveal">
          <div class="panel-head"><span class="fname">Composition</span></div>
          <div class="panel-body">
            <!--SSR_COMPOSITION_START-->
            <!--SSR_COMPOSITION_END-->
          </div>
        </div>

        <!--SSR_FACTS_START-->
        <!--SSR_FACTS_END-->
      </aside>
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
          <li><a href="#" data-hub-path="/explore">Browse repositories</a></li>
          <li><a href="#" data-hub-path="/#engine">Field manual</a></li>
          <li><a href="#about">Hosting plans</a></li>
        </ul>
        @@FOOTER_TRANSPORT@@
      </div>
      <div>
        <h4>Upstream</h4>
        <ul>
          <li><a href="#about">fossil-scm.org</a></li>
          <li><a href="#about">SQLite, the sibling project</a></li>
          <li><a href="#about">Release history</a></li>
        </ul>
      </div>
      <div>
        <h4>The hub</h4>
        <ul>
          <li><a href="#about">Site rules</a></li>
          <li><a href="#about">Status board</a></li>
          <li><a href="#about">Contact the wardens</a></li>
        </ul>
      </div>
    </div>
    <div class="bedrock-bottom">
      <span>© 2026 FOSSILHUB — SURVEY DRAWING NO. FH-26-08</span>
      <span>SET IN BIG SHOULDERS &amp; IBM PLEX · DRAWN AT 1:1 SCALE</span>
    </div>
  </div>
</footer>

<script src="fossilhub-live.js"></script>
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
  ind.style.top = `${(f * 100).toFixed(2)}%`;
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

proc ::fossilhub::views::repositoryTransport {visibility} {
  if {$visibility eq "private"} {
    return [dict create header "" footer "" main {
      <span class="private-transport">Private repository · browser members only</span>}]
  }
  set command {
    <span class="cmd-chip"><span class="p">$</span><span class="u" data-clone-command>fossil clone /fossil/dig</span></span>}
  return [dict create header $command main $command footer {
    <span class="clone-dark"><span class="p">$</span><span class="u" data-clone-command>fossil clone /fossil/dig</span></span>}]
}

proc ::fossilhub::views::repositoryFacts {repository} {
  set repositoryName [dict get $repository name]
  set visibility [expr {[dict exists $repository visibility] ?
    [dict get $repository visibility] : "public"}]
  set transportNote [expr {$visibility eq "private" ?
    "Private transport is disabled; authorized members use first-party browser workflows." :
    "Browser navigation stays in FossilHub. Fossil's endpoint is retained only for clone and sync clients."}]
  return [format {
        <div class="panel reveal">
          <div class="panel-head"><span class="fname">Repository facts</span></div>
          <div class="panel-body">
            <div class="br-row"><span class="swatch" style="background:#205297"></span><span class="br-name">check-ins</span><span class="br-tip">%s</span></div>
            <div class="br-row"><span class="swatch" style="background:#2F6E5A"></span><span class="br-name">repository file</span><span class="br-tip">%s</span></div>
            <div class="br-row"><span class="swatch" style="background:#A64B22"></span><span class="br-name">latest event</span><span class="br-tip">%s</span></div>
          </div>
        </div>
        <div class="panel reveal">
          <div class="panel-head"><span class="fname">FossilHub surfaces</span></div>
          <div class="panel-body">
            <div class="peer-row"><span class="peer-dot" style="background:#205297"></span><a class="peer-name" href="#" data-hub-path="/repo/%s/timeline">Timeline</a><span class="peer-state">SSR</span></div>
            <div class="peer-row"><span class="peer-dot" style="background:#2F6E5A"></span><a class="peer-name" href="#" data-hub-path="/repo/%s/files">Files</a><span class="peer-state">trunk</span></div>
            <div class="peer-row"><span class="peer-dot" style="background:#A64B22"></span><a class="peer-name" href="#" data-hub-path="/repo/%s/docs">Docs</a><span class="peer-state">indexed</span></div>
            <p class="sync-cap">%s</p>
          </div>
        </div>} \
    [::fossilhub::view::formatCount [dict get $repository checkins]] \
    [::fossilhub::view::escape [::fossilhub::view::formatBytes \
      [dict get $repository bytes]]] \
    [::fossilhub::view::escape [::fossilhub::view::relativeTime \
      [dict get $repository latest_epoch]]] \
    $repositoryName $repositoryName $repositoryName \
    [::fossilhub::view::escape $transportNote]]
}

proc ::fossilhub::views::renderRepository {repository {section timeline} {sectionData ""}} {
  variable repositoryTemplate
  if {$sectionData eq ""} {
    set sectionData [dict create repository $repository event_filter all]
  }
  set activeSection $section
  if {$activeSection in {file tree blob history blame branches tags stats}} {
    set activeSection files
  } elseif {$activeSection eq "doc"} {
    set activeSection docs
  } elseif {$activeSection eq "checkin"} {
    set activeSection timeline
  } elseif {$activeSection in {wiki-page wiki-revision wiki-history wiki-compare}} {
    set activeSection wiki
  } elseif {$activeSection eq "file-compose"} {
    set activeSection files
  } elseif {$activeSection eq "wiki-compose"} {
    set activeSection wiki
  } elseif {$activeSection in {ticket-compose ticket-workbench ticket-detail}} {
    set activeSection tickets
  } elseif {$activeSection in {forum-compose discussion}} {
    set activeSection forum
  }
  set tabs [dict create timeline "" files "" docs "" wiki "" tickets "" forum ""]
  if {[dict exists $tabs $activeSection]} {
    dict set tabs $activeSection active
  }
  set latest [dict get $repository latest_epoch]
  set visibility [expr {[dict exists $repository visibility] ?
    [dict get $repository visibility] : "public"}]
  set transport [::fossilhub::views::repositoryTransport $visibility]
  set page [string map [list \
    @@REPOSITORY_SLUG@@ [::fossilhub::view::escape [dict get $repository slug]] \
    @@REPOSITORY_NAME@@ [::fossilhub::view::escape [dict get $repository name]] \
    @@REPOSITORY_UPPER@@ [::fossilhub::view::escape \
      [string toupper [dict get $repository name]]] \
    @@VISIBILITY@@ [::fossilhub::view::escape $visibility] \
    @@VISIBILITY_UPPER@@ [::fossilhub::view::escape \
      [string toupper $visibility]] \
    @@HEADER_TRANSPORT@@ [dict get $transport header] \
    @@MAIN_TRANSPORT@@ [dict get $transport main] \
    @@FOOTER_TRANSPORT@@ [dict get $transport footer] \
    @@TAB_TIMELINE@@ [dict get $tabs timeline] \
    @@TAB_FILES@@ [dict get $tabs files] \
    @@TAB_DOCS@@ [dict get $tabs docs] \
    @@TAB_WIKI@@ [dict get $tabs wiki] \
    @@TAB_TICKETS@@ [dict get $tabs tickets] \
    @@TAB_FORUM@@ [dict get $tabs forum] \
    @@DESCRIPTION@@ [::fossilhub::view::escape \
      [::fossilhub::view::repositoryDescription $repository]] \
    @@ZIP_NAME@@ [::fossilhub::view::escape [dict get $repository slug]] \
    @@RELATIVE_TIME@@ [::fossilhub::view::escape \
      [::fossilhub::view::relativeTime $latest]] \
    @@PROJECT_ID@@ [::fossilhub::view::escape \
      [::fossilhub::view::projectId $repository]] \
    @@PROJECT_NAME@@ [::fossilhub::view::escape \
      [dict get $repository project_name]] \
    @@OPENED_DATE@@ [::fossilhub::view::escape \
      [::fossilhub::view::formatDate [dict get $repository opened_epoch]]] \
    @@LAST_FIND@@ [::fossilhub::view::escape \
      "[::fossilhub::view::formatDate $latest] [::fossilhub::view::formatTime $latest]"] \
    @@ARTIFACTS@@ [::fossilhub::view::formatCount \
      [dict get $repository artifacts]] \
    @@DEPTH@@ [::fossilhub::view::escape [::fossilhub::view::formatBytes \
      [dict get $repository bytes]]] \
    @@WIKI_EVENTS@@ [::fossilhub::view::formatCount \
      [dict get $repository wiki_events]] \
    @@OPEN_TICKETS@@ [::fossilhub::view::formatCount \
      [dict get $repository open_tickets]] \
    @@CONTRIBUTORS@@ [::fossilhub::view::formatCount \
      [dict get $repository contributors]] \
    @@FORUM_EVENTS@@ [::fossilhub::view::formatCount \
      [dict get $repository forum_events]]] \
    $repositoryTemplate]
  set page [::fossilhub::view::replaceRegion $page \
    <!--SSR_SECTION_START--> <!--SSR_SECTION_END--> \
    [::fossilhub::views::renderRepositorySection \
      $repository $section $sectionData]]
  set page [::fossilhub::view::replaceRegion $page \
    <!--SSR_COMPOSITION_START--> <!--SSR_COMPOSITION_END--> \
    [::fossilhub::view::composition $repository]]
  return [::fossilhub::view::replaceRegion $page \
    <!--SSR_FACTS_START--> <!--SSR_FACTS_END--> \
    [::fossilhub::views::repositoryFacts $repository]]
}
