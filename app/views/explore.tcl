namespace eval ::fossilhub::views {
variable exploreTemplate {
<!doctype html>
<html lang="@@HTML_LANG@@">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>@@PAGE_TITLE@@</title>
<meta name="description" content="Browse Fossil repositories on FossilHub — every dig holds code, wiki, tickets and forum in one artifact.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@500;600;700;800&family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<script>document.documentElement.dataset.theme=localStorage.getItem("fh-theme")||(matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light");</script>
<link rel="stylesheet" href="fh.css?v=20260830-2">
<style>
.x-hero{padding-block:52px 44px;border-bottom:1px solid var(--line)}
.x-hero h1{
  font-family:var(--font-display);font-weight:700;text-transform:uppercase;
  font-size:clamp(2.6rem,5vw,4.4rem);line-height:.95;letter-spacing:.008em;
  margin-top:18px;max-width:20ch;
}
.x-lede{margin-top:16px;max-width:62ch;color:var(--ink-2);font-size:16.5px}
.searchbar{
  margin-top:28px;display:flex;align-items:center;gap:14px;
  background:var(--card);border:1px solid var(--line);border-radius:8px;
  padding:14px 18px;max-width:720px;
}
.searchbar:focus-within{border-color:var(--azurite)}
.searchbar .q{
  font-family:var(--font-mono);font-size:13px;color:var(--ink);flex:1;
  border:0;outline:0;background:transparent;min-width:0;
}
.searchbar .q::placeholder{color:var(--ink-2)}
.search-state{font-family:var(--font-mono);font-size:10px;color:var(--ink-2);white-space:nowrap}
.catalog-form.loading .search-state{color:var(--azurite-deep)}
.kbd{
  font-family:var(--font-mono);font-size:10px;color:var(--ink-2);
  border:1px solid var(--line);border-radius:4px;padding:2px 7px;background:var(--paper);
}
.filterbar{margin-top:18px;display:flex;gap:18px;flex-wrap:wrap;align-items:center}
.fgroup{display:flex;gap:8px;align-items:center}
.gl{
  font-family:var(--font-mono);font-size:9.5px;letter-spacing:.18em;
  color:var(--ink-2);margin-right:2px;
}
.fchip{
  font-family:var(--font-mono);font-size:11px;padding:6px 13px;
  border:1px solid var(--line);border-radius:999px;color:var(--ink-2);background:transparent;
}
.fchip{cursor:pointer}
.fchip.sel{border-color:var(--azurite);color:var(--azurite-deep);background:rgba(32,82,151,.08)}
.seg{display:inline-flex;border:1px solid var(--line);border-radius:999px;overflow:hidden;background:var(--card)}
.seg select{
  font-family:var(--font-mono);font-size:11px;padding:7px 15px;color:var(--ink-2);
  border:0;background:var(--card);outline:0;cursor:pointer;
}
.search-submit{font-family:var(--font-mono);font-size:10px}
.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}

.featured{padding-block:44px 10px}
.sec-tag{
  font-family:var(--font-mono);font-size:10.5px;letter-spacing:.18em;
  text-transform:uppercase;color:var(--iron);
  display:flex;align-items:center;gap:10px;margin-bottom:18px;
}
.sec-tag::before{content:"";width:14px;height:2px;background:var(--iron)}
.feat-card{
  display:grid;grid-template-columns:170px minmax(0,1fr) 230px;
  gap:clamp(22px,3.5vw,44px);align-items:center;
  background:var(--card);border:1px solid var(--line);border-radius:12px;
  padding:clamp(22px,3.5vw,36px);
  box-shadow:0 1px 0 rgba(28,35,44,.05),0 18px 40px -30px rgba(28,35,44,.4);
  color:inherit;text-decoration:none;
  transition:transform .25s ease,border-color .25s ease,box-shadow .25s ease;
}
.feat-card:hover{transform:translateY(-3px);border-color:rgba(28,35,44,.45);text-decoration:none}
.mini-core{width:100%;max-width:150px;margin-inline:auto;display:block}
.feat-name{
  font-family:var(--font-display);font-weight:700;text-transform:uppercase;
  font-size:clamp(1.7rem,3vw,2.3rem);line-height:1;
}
.feat-desc{margin-top:9px;font-size:14px;color:var(--ink-2);max-width:52ch;line-height:1.6}
.feat-chips{display:flex;gap:9px;margin-top:14px;flex-wrap:wrap}
.feat-metrics{margin-top:14px;font-family:var(--font-mono);font-size:11px;color:var(--ink-2);display:flex;gap:16px;flex-wrap:wrap}
.feat-side{text-align:left}
.spark-cap{font-family:var(--font-mono);font-size:9.5px;letter-spacing:.14em;text-transform:uppercase;color:var(--ink-2);margin-bottom:8px}
.feat-side svg{width:100%;height:auto;display:block}
.last-find{margin-top:10px;font-family:var(--font-mono);font-size:11px;color:var(--verdi)}

.feed{background:var(--paper-2);border-block:1px solid var(--line);padding-block:24px;margin-top:44px}
.feed-head{display:flex;justify-content:space-between;align-items:center;gap:14px;margin-bottom:14px}
.feed-head p{
  font-family:var(--font-mono);font-size:10.5px;letter-spacing:.18em;
  text-transform:uppercase;color:var(--ink-2);
}
.feed-hint{font-family:var(--font-mono);font-size:10px;color:var(--ink-2)}
.feed-row{display:flex;gap:12px;overflow-x:auto;padding-bottom:6px}
.pill{
  flex:none;display:inline-flex;align-items:center;gap:10px;
  background:var(--card);border:1px solid var(--line);border-radius:999px;
  padding:8px 16px 8px 11px;font-size:12px;white-space:nowrap;color:inherit;
  text-decoration:none;
}
.pill:hover{border-color:rgba(28,35,44,.45);text-decoration:none}
.pill .t{font-family:var(--font-mono);font-size:10px;color:var(--ink-2)}
.pill b{font-weight:600}

.grid-sec{padding-block:56px 96px}
.toolrow{display:flex;justify-content:space-between;align-items:baseline;gap:16px;margin-bottom:26px;flex-wrap:wrap}
.count{font-family:var(--font-mono);font-size:11px;letter-spacing:.08em;color:var(--ink-2)}
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(248px,1fr));gap:26px}
.rcard{
  --mx:.5;--my:.5;--rx:0deg;--ry:0deg;
  position:relative;display:flex;flex-direction:column;overflow:hidden;
  background:linear-gradient(165deg,#F6F7ED,#E7EADA 62%,#DDE1CC);
  border:1px solid rgba(28,35,44,.32);border-radius:14px;
  padding:17px 16px 14px;color:var(--ink);text-decoration:none;
  box-shadow:inset 0 1px 0 rgba(255,255,255,.8),0 16px 30px -24px rgba(28,35,44,.55);
  transform:perspective(900px) rotateX(var(--rx)) rotateY(var(--ry));
  transform-style:preserve-3d;
  transition:transform .5s cubic-bezier(.2,.8,.25,1),box-shadow .3s,border-color .3s;
  will-change:transform;
}
.rcard:hover,.rcard:focus-visible{
  border-color:rgba(28,35,44,.48);
  box-shadow:inset 0 1px 0 rgba(255,255,255,.8),0 32px 54px -28px rgba(28,35,44,.6);
}
.rcard .holo{
  position:absolute;inset:-30%;pointer-events:none;z-index:1;
  background:linear-gradient(calc(115deg + var(--mx)*80deg),
    #ff76a8,#ffcc5c 18%,#6fe8b0 36%,#589eff 55%,#be7aff 74%,#ff76a8);
  background-size:280% 280%;
  background-position:calc(var(--mx)*100%) calc(var(--my)*100%);
  mix-blend-mode:multiply;opacity:.34;filter:saturate(1.35);
  transition:opacity .35s;
}
.holo::before{
  content:"";position:absolute;inset:-20%;
  background:linear-gradient(105deg,
    transparent 40%,rgba(255,255,255,.55) 50%,rgba(255,255,255,.14) 57%,transparent 64%);
  background-size:250% 250%;
  background-position:calc(var(--mx)*100%) calc(var(--my)*100%);
  opacity:0;transition:opacity .35s;
}
.holo::after{
  content:"";position:absolute;inset:0;
  background:repeating-linear-gradient(105deg,rgba(255,255,255,.45) 0 1px,transparent 1px 6px);
  mix-blend-mode:overlay;
}
.rcard:hover .holo,.rcard:focus-visible .holo{opacity:.52}
.rcard:hover .holo::before,.rcard:focus-visible .holo::before{opacity:1}
.rcard .glare{
  position:absolute;inset:0;border-radius:inherit;pointer-events:none;z-index:6;
  background:radial-gradient(circle at calc(var(--mx)*100%) calc(var(--my)*100%),
    rgba(255,255,255,.6),rgba(255,255,255,0) 50%);
  mix-blend-mode:soft-light;opacity:0;transition:opacity .3s;
}
.rcard:hover .glare,.rcard:focus-visible .glare{opacity:1}
.rcard>*{position:relative;z-index:2}
.card-top{
  display:flex;align-items:baseline;justify-content:space-between;gap:10px;
  transform:translateZ(12px);
}
.rcard .name{
  font-family:var(--font-display);font-weight:700;text-transform:uppercase;
  font-size:1.22rem;letter-spacing:.02em;line-height:1.02;color:var(--ink);
}
.spec-tag{
  font-family:var(--font-mono);font-size:8px;letter-spacing:.2em;
  color:rgba(28,35,44,.5);white-space:nowrap;
}
.badge-row{display:flex;gap:6px;margin-top:9px;flex-wrap:wrap;transform:translateZ(12px)}
.badge-row .chip{padding:3px 9px;font-size:9.5px;background:rgba(244,245,236,.72)}
.core-art{
  width:58%;height:auto;display:block;margin:12px auto 2px;
  filter:drop-shadow(0 6px 12px rgba(28,35,44,.22));
}
.seismo{display:block;width:100%;height:24px;margin-top:4px;opacity:.85}
.seismo polyline{fill:none;stroke:rgba(28,35,44,.42);stroke-width:1.4;stroke-linecap:round;stroke-linejoin:round}
.rcard .desc{font-size:12.75px;color:var(--ink-2);margin-top:11px;line-height:1.52;min-height:58px}
.rcard .comp-seg{border:1px solid rgba(28,35,44,.24);height:9px}
.rcard .counts{
  display:flex;gap:11px;margin-top:9px;flex-wrap:wrap;
  font-family:var(--font-mono);font-size:9px;letter-spacing:.05em;
  color:var(--ink-2);text-transform:uppercase;
}
.rcard .foot{
  display:flex;align-items:center;gap:9px;
  border-top:1px dashed var(--line);margin-top:auto;padding-top:11px;
  font-family:var(--font-mono);font-size:10.5px;color:var(--ink-2);
  transform:translateZ(10px);
}
.rcard .foot .peers{margin-left:auto}
.avatar-sm{width:22px;height:22px;font-size:8px}
.js .rcard.reveal:not(.in){transform:none}
.js .rcard.reveal.in{
  transform:perspective(900px) rotateX(var(--rx)) rotateY(var(--ry));
}

[data-theme="dark"] .rcard{
  background:linear-gradient(160deg,#242C37,#151B23 72%);
  border-color:rgba(28,35,44,.95);
  color:var(--paper);
  box-shadow:0 18px 36px -26px rgba(0,0,0,.85);
}
[data-theme="dark"] .rcard:hover,[data-theme="dark"] .rcard:focus-visible{
  box-shadow:0 32px 54px -28px rgba(0,0,0,.9);
}
[data-theme="dark"] .rcard .name{color:var(--paper)}
[data-theme="dark"] .spec-tag{color:rgba(232,234,223,.55)}
[data-theme="dark"] .badge-row .chip{background:transparent}
[data-theme="dark"] .rcard .desc{color:rgba(232,234,223,.78)}
[data-theme="dark"] .rcard .counts{color:rgba(232,234,223,.62)}
[data-theme="dark"] .rcard .foot{border-top-color:rgba(232,234,223,.28);color:rgba(232,234,223,.78)}
[data-theme="dark"] .rcard .peers{color:rgba(232,234,223,.6)}
[data-theme="dark"] .rcard .comp-seg{border-color:rgba(232,234,223,.3)}
[data-theme="dark"] .rcard .cb-code{background:#7EAAEB}
[data-theme="dark"] .rcard .cb-wiki{background:#7EC7A8}
[data-theme="dark"] .rcard .cb-tkt{background:#E49262}
[data-theme="dark"] .rcard .cb-forum{background:rgba(232,234,223,.35)}
[data-theme="dark"] .rcard .holo{
  mix-blend-mode:color-dodge;opacity:.16;filter:saturate(1.25);
  background:linear-gradient(calc(115deg + var(--mx)*80deg),
    rgba(255,94,158,.55),rgba(255,196,64,.5) 18%,rgba(120,255,180,.46) 36%,
    rgba(84,160,255,.55) 55%,rgba(186,110,255,.5) 74%,rgba(255,94,158,.55));
}
[data-theme="dark"] .rcard:hover .holo,[data-theme="dark"] .rcard:focus-visible .holo{opacity:.42}
[data-theme="dark"] .rcard .holo::before{opacity:0}
[data-theme="dark"] .rcard:hover .holo::before,[data-theme="dark"] .rcard:focus-visible .holo::before{opacity:.45}
[data-theme="dark"] .rcard .holo::after{
  background:repeating-linear-gradient(105deg,rgba(255,255,255,.12) 0 1px,transparent 1px 6px);
}
[data-theme="dark"] .core-art{filter:drop-shadow(0 8px 16px rgba(0,0,0,.55))}
[data-theme="dark"] .core-art [stroke^="rgba(28,35,44"]{stroke:rgba(232,234,223,.55)}
[data-theme="dark"] .core-art [fill^="rgba(28,35,44"]{fill:rgba(232,234,223,.12)}
[data-theme="dark"] .core-art [fill="#205297"]{fill:#7AA5E4}
[data-theme="dark"] .core-art [fill="#2F6E5A"]{fill:#5FB394}
[data-theme="dark"] .core-art [fill="#A64B22"]{fill:#D98A57}
[data-theme="dark"] .core-art [fill="#F4F5EC"]{fill:#1B222B}
[data-theme="dark"] .core-art [fill^="rgba(166,75,34"]{fill:rgba(222,150,60,.3)}
[data-theme="dark"] .seismo polyline{stroke:rgba(232,234,223,.55)}
[data-theme="dark"] .mini-core [stroke="#1C232C"]{stroke:#E8EADF}
[data-theme="dark"] .mini-core [stroke="rgba(28,35,44,.5)"]{stroke:rgba(232,234,223,.55)}
[data-theme="dark"] .mini-core [fill="#205297"]{fill:#7AA5E4}
[data-theme="dark"] .mini-core [fill="#2F6E5A"]{fill:#5FB394}
[data-theme="dark"] .mini-core [fill="#A64B22"]{fill:#D98A57}
[data-theme="dark"] .mini-core [fill="#F4F5EC"]{fill:#202834}
[data-theme="dark"] .mini-core [stroke="#1C232C"]{stroke:#E8EADF}
[data-theme="dark"] .mini-core [fill="rgba(32,82,151,.09)"]{fill:rgba(110,156,224,.10)}
[data-theme="dark"] .mini-core [fill="rgba(47,110,90,.10)"]{fill:rgba(95,179,148,.10)}
[data-theme="dark"] .mini-core [fill="rgba(166,75,34,.07)"]{fill:rgba(217,138,87,.08)}
[data-theme="dark"] .mini-core [fill="#DEE1D3"]{fill:#1A212B}
[data-theme="dark"] .feat-side polyline{stroke:#7AA5E4}
[data-theme="dark"] .feat-card:hover{border-color:rgba(232,234,223,.35)}
[data-theme="dark"] .pill:hover{border-color:rgba(232,234,223,.4)}

@media (prefers-reduced-motion:reduce){
  .rcard{transform:none!important}
  .rcard .holo{opacity:.24;background-position:50% 50%}
  .glare{display:none}
}

@media (max-width:980px){
  .feat-card{grid-template-columns:1fr;gap:26px}
  .mini-core{max-width:140px}
  .feat-side{max-width:340px}
}
@media (max-width:640px){
  .searchbar .kbd{display:none}
  .fgroup{max-width:100%;flex-wrap:wrap}
  .rcard .desc{min-height:0}
}
</style>
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
    <a class="wordmark" href="index.html" aria-label="FossilHub home">
      <img src="fossilhub-hub-lockup-v1.png?v=20260829-1" width="137" height="50" alt="FossilHub">
    </a>
    <nav class="topnav" aria-label="@@PRIMARY_NAV_LABEL@@">
      <a href="#featured">@@FEATURED_LABEL@@</a>
      <a href="#feed">@@SURFACE_FEED_LABEL@@</a>
      <a href="#digs">@@ALL_DIGS_LABEL@@</a>
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

  <section class="x-hero">
    <div class="wrap">
      <p class="eyebrow">@@EXPLORE_EYEBROW@@</p>
      <h1>@@EXPLORE_HEADING@@</h1>
      <p class="lede">@@EXPLORE_LEDE@@</p>
      <form class="catalog-form" action="explore" method="get" data-catalog-form>
        <div class="searchbar">
          <label class="sr-only" for="catalogQuery">@@SEARCH_REPOSITORIES@@</label>
          <input class="q" id="catalogQuery" name="q" type="search" value="@@QUERY@@" placeholder="@@SEARCH_PLACEHOLDER@@" autocomplete="off">
          <span class="search-state" data-search-state>@@RESULT_SUMMARY@@</span>
          <span class="kbd">/</span>
        </div>
        <div class="filterbar">
          <div class="fgroup" role="group" aria-label="Repository content filter">
            <span class="gl">@@STRATA_LABEL@@</span>
            <input type="hidden" name="kind" value="@@KIND@@" data-kind-input>
            <button class="fchip @@KIND_ALL@@" type="button" data-kind="all">@@ALL_LABEL@@</button>
            <button class="fchip @@KIND_CODE@@" type="button" data-kind="code">@@CODE_LABEL@@</button>
            <button class="fchip @@KIND_WIKI@@" type="button" data-kind="wiki">Wiki</button>
            <button class="fchip @@KIND_TICKETS@@" type="button" data-kind="tickets">Tickets</button>
            <button class="fchip @@KIND_FORUM@@" type="button" data-kind="forum">Forum</button>
          </div>
          <div class="fgroup">
            <label class="gl" for="catalogSort">SORT BY</label>
            <span class="seg"><select id="catalogSort" name="sort">
              <option value="recent" @@SORT_RECENT@@>Surface · recent</option>
              <option value="oldest" @@SORT_OLDEST@@>Deep time · oldest</option>
              <option value="name" @@SORT_NAME@@>Specimen · name</option>
              <option value="size" @@SORT_SIZE@@>Mass · largest</option>
            </select></span>
          </div>
          <noscript><button class="btn btn-ghost search-submit" type="submit">@@APPLY_FILTERS@@</button></noscript>
        </div>
      </form>
    </div>
  </section>

  <!--SSR_RESULTS_START-->
  <!--SSR_RESULTS_END-->

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
const fine = matchMedia('(pointer: fine)').matches && !matchMedia('(prefers-reduced-motion: reduce)').matches;
if (fine) {
  document.querySelectorAll('.rcard').forEach((card) => {
    const set = (x, y) => {
      const r = card.getBoundingClientRect();
      const mx = Math.min(1, Math.max(0, (x - r.left) / r.width));
      const my = Math.min(1, Math.max(0, (y - r.top) / r.height));
      card.style.setProperty('--mx', mx.toFixed(3));
      card.style.setProperty('--my', my.toFixed(3));
      card.style.setProperty('--ry', ((mx - .5) * 10).toFixed(2) + 'deg');
      card.style.setProperty('--rx', ((.5 - my) * 8).toFixed(2) + 'deg');
    };
    card.addEventListener('pointerenter', () => { card.style.transition = 'box-shadow .3s,border-color .3s'; });
    card.addEventListener('pointermove', (e) => set(e.clientX, e.clientY));
    card.addEventListener('pointerleave', () => {
      card.style.transition = '';
      card.style.setProperty('--rx', '0deg');
      card.style.setProperty('--ry', '0deg');
      card.style.setProperty('--mx', '.5');
      card.style.setProperty('--my', '.5');
    });
  });
}
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
<script src="catalog-search.js?v=20260828-3"></script>

</body>
</html>
}
}

proc ::fossilhub::views::renderExploreResults {repositories} {
  set count [llength $repositories]
  set featuredHtml ""
  if {$count == 0} {
    set featuredHtml [format {<div class="panel"><div class="panel-body">%s</div></div>} \
      [::fossilhub::view::escape [::fossilhub::i18n::t no_matches]]]
  } else {
    set featuredHtml [::fossilhub::view::featuredRepository \
      [lindex $repositories 0]]
  }

  set cards ""
  set index 0
  foreach repository $repositories {
    incr index
    append cards [::fossilhub::view::repositoryCard $repository $index]
  }
  if {$cards eq ""} {
    set cards [format {<div class="panel"><div class="panel-body">%s</div></div>} \
      [::fossilhub::view::escape [::fossilhub::i18n::t broader_search]]]
  }

  return [format {
  <div data-catalog-results data-result-count="%d">
    <section class="featured wrap" id="featured">
      <p class="sec-tag">%s</p>
      %s
      <div class="feed" id="feed">
        <div class="feed-head">
          <p>%s</p>
          <span class="feed-hint">%s</span>
        </div>
        <div class="feed-row">%s</div>
      </div>
    </section>
    <section class="grid-sec" id="digs">
      <div class="wrap">
        <div class="toolrow reveal">
          <p class="eyebrow">%s</p>
          <span class="count">%s %s — %s</span>
        </div>
        <div class="cards">%s</div>
      </div>
    </section>
  </div>} \
    $count \
    [::fossilhub::view::escape [::fossilhub::i18n::t surface_specimen]] \
    $featuredHtml \
    [::fossilhub::view::escape [::fossilhub::i18n::t matching_digs]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t scroll_hint]] \
    [::fossilhub::view::surfaceFeed $repositories] \
    [::fossilhub::view::escape [::fossilhub::i18n::t survey_results]] \
    [::fossilhub::view::escape [::fossilhub::i18n::t showing]] \
    [::fossilhub::view::formatCount $count] \
    [::fossilhub::view::escape [::fossilhub::i18n::t indexed_sqlite]] $cards]
}

proc ::fossilhub::views::renderExplore {repositories {options {}} {context ""}} {
  variable exploreTemplate
  set options [::fossilhub::catalog::searchOptions $options]
  set count [llength $repositories]
  if {$count == 0} {
    set featured [::fossilhub::view::emptyRepository]
  } else {
    set featured [lindex $repositories 0]
  }

  set selected [dict create recent "" oldest "" name "" size ""]
  dict set selected [dict get $options sort] selected
  set kinds [dict create all "" code "" wiki "" tickets "" forum ""]
  dict set kinds [dict get $options kind] sel
  set page [string map [list \
    @@HTML_LANG@@ [::fossilhub::i18n::locale] \
    @@PAGE_TITLE@@ [::fossilhub::view::escape [::fossilhub::i18n::t explore_title]] \
    @@PRIMARY_NAV_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t primary_navigation]] \
    @@FEATURED_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t featured]] \
    @@SURFACE_FEED_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t surface_feed]] \
    @@ALL_DIGS_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t all_digs]] \
    @@THEME_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t theme_toggle]] \
    @@EXPLORE_EYEBROW@@ [::fossilhub::view::escape [::fossilhub::i18n::t explore_eyebrow]] \
    @@EXPLORE_HEADING@@ [::fossilhub::view::escape [::fossilhub::i18n::t explore_heading]] \
    @@EXPLORE_LEDE@@ [::fossilhub::view::escape [::fossilhub::i18n::t explore_lede]] \
    @@SEARCH_REPOSITORIES@@ [::fossilhub::view::escape [::fossilhub::i18n::t search_repositories]] \
    @@SEARCH_PLACEHOLDER@@ [::fossilhub::view::escape [::fossilhub::i18n::t search_placeholder]] \
    @@STRATA_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t strata]] \
    @@ALL_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t all]] \
    @@CODE_LABEL@@ [::fossilhub::view::escape [::fossilhub::i18n::t code]] \
    @@APPLY_FILTERS@@ [::fossilhub::view::escape [::fossilhub::i18n::t apply_filters]] \
    @@SITE_TOOLS@@ [::fossilhub::views::siteTools $context] \
    @@REPOSITORY_SLUG@@ [::fossilhub::view::escape [dict get $featured slug]] \
    @@QUERY@@ [::fossilhub::view::escape [dict get $options q]] \
    @@RESULT_SUMMARY@@ [expr {[::fossilhub::i18n::locale] eq "zh-CN" ? \
      "$count 个结果" : "$count matches"}] \
    @@KIND@@ [dict get $options kind] \
    @@KIND_ALL@@ [dict get $kinds all] \
    @@KIND_CODE@@ [dict get $kinds code] \
    @@KIND_WIKI@@ [dict get $kinds wiki] \
    @@KIND_TICKETS@@ [dict get $kinds tickets] \
    @@KIND_FORUM@@ [dict get $kinds forum] \
    @@SORT_RECENT@@ [dict get $selected recent] \
    @@SORT_OLDEST@@ [dict get $selected oldest] \
    @@SORT_NAME@@ [dict get $selected name] \
    @@SORT_SIZE@@ [dict get $selected size]] \
    $exploreTemplate]
  return [::fossilhub::view::replaceRegion $page \
    <!--SSR_RESULTS_START--> <!--SSR_RESULTS_END--> \
    [::fossilhub::views::renderExploreResults $repositories]]
}
