# FossilHub implementation plan

## Constraints

- Preserve the reference pages' visual system and responsive behaviour 1:1.
- Implement request routing and page rendering in Tcl with Wapp.
- Run althttpd and Wapp in a new isolated Ubuntu 24.04 container.
- Do not modify fnOS system files or any existing production container.
- Commit every coherent operation so every milestone is independently reversible.

## Architecture

```text
browser
  -> host port (new, conflict-checked)
  -> fossilhub Ubuntu container
  -> althttpd :8080
  -> executable Wapp CGI for the reference hub UI
  -> Tcl SSR routes and a separate SQLite catalogue index
  -> read-only Fossil queries and persistent Fossil artifacts
  -> Fossil CGI directory mode retained only for clone/sync transport
```

Althttpd serves fingerprintable static assets directly and treats the executable
Wapp entry point as CGI. Wapp owns application routes and response handling. The
runtime data directory is mounted separately from the immutable application
image and stores request logs, native Fossil repositories, and the one-time
administrator bootstrap record. Fossil owns its SQLite repository schema. Tcl
queries it through Fossil's read-only enhanced SQL shell and renders the public
catalogue and timeline on the server.

## Route map

| Route | Reference | Purpose |
| --- | --- | --- |
| `/` | `fossilhub.html` | Product landing page |
| `/explore` | `explore.html` | Searchable repository catalogue |
| `/catalog-fragment` | — | Live search/filter HTML fragment |
| `/repo/<name>.fossil` | `repo.html` | Repository specimen and timeline |
| `/repo/<name>.fossil/files` | — | Styled source tree |
| `/repo/<name>.fossil/docs` | — | Styled documentation index |
| `/repo/<name>.fossil/wiki` | — | Styled Wiki history |
| `/repo/<name>.fossil/tickets` | — | Styled ticket index |
| `/repo/<name>.fossil/forum` | — | Styled forum activity |
| `/healthz` | — | Container health check |

## Milestones

- [x] Create the Git repository and record this plan.
- [x] Audit NAS Docker networking, ports, storage, and architecture read-only.
- [x] Add the vendored reference snapshot and deterministic source records.
- [x] Scaffold Wapp routing, static asset delivery, and health checks.
- [x] Port the three reference pages into Tcl templates without redesigning them.
- [x] Build the Ubuntu/althttpd/Wapp image on the x86_64 NAS and verify HTTP
  behaviour. The local macOS Docker client had no active engine, so the target
  host performed the authoritative build.
- [x] Compare the implementation at desktop and mobile sizes in the browser.
- [x] Deploy as a new NAS container with a dedicated volume and unused host port.
- [x] Verify health, routes, logs, restart behaviour, and document operations.
- [ ] Optional future phase: replace the static reference catalogue with a
  SQLite schema, live search/filter behaviour, and data-layer tests. This was
  not required to reproduce the supplied UI and is deliberately outside 0.1.2.

## Visual acceptance

- Desktop: 1440 x 1000 for all three pages in light and dark themes.
- Mobile: 390 x 844 for all three pages.
- No accidental horizontal overflow, missing SVG art, console error, or broken link.
- Typography, spacing, colours, borders, responsive breakpoints, and motion follow
  the reference files; reduced-motion mode remains functional.

Acceptance completed against production release 0.2.0-beta.1. Intentional
responsive corrections wrap Explore language filters below 640 px and hide the
long header clone command below 1100 px. Both remove horizontal clipping without
changing the reference desktop composition.

## Phase 2: beta runtime and real Fossil service

Requested 2026-08-27. Release 0.1.2 remains the rollback baseline until every
item below is complete.

- [x] Pin the latest official development snapshots of Wapp, Althttpd, and
  Fossil by immutable Fossil check-in, plus the Tcl 9.1b0 source release.
- [x] Build Tcl 9.1b0, Wapp, Althttpd, and Fossil from source in a reproducible
  multi-stage Ubuntu 24.04 image.
- [x] Add a persistent `/data/repositories` directory and idempotently bootstrap
  a real `dig.fossil` repository without exposing its setup password in logs.
- [x] Serve the repository through Althttpd and Fossil's documented CGI
  `directory:` mode under `/fossil/dig/`.
- [x] Preserve the reference UI composition while wiring repository navigation
  to live Timeline, Files, Docs, Wiki, Tickets, Forum, clone, and sync surfaces.
- [x] Keep public access read-only by default; retain Fossil's own authenticated
  permission model for repository writes and administration.
- [x] Verify a real HTTP clone, a pull/sync round trip, repository persistence
  across restart, CGI writes under UID/GID 10001, and all prior visual checks.
- [x] Deploy only after smoke tests pass, retaining the current 0.1.2 container
  as the immediate rollback target and documenting credential recovery.

Production port 6080 runs 0.2.0-beta.1 at revision `0ac4dff`. Revision
`188b918` and production 0.1.2 at revision `8c9726d` remain as stopped rollback
containers. See `docs/validation-0.2.0-beta.1.md` for the evidence record.

## Phase 3: Tcl-native server-side rendering

Requested 2026-08-27. This phase preserves the accepted reference design while
replacing prototype repository facts with live Fossil data.

- [x] Add a Tcl repository model that discovers only trusted `.fossil` files
  below `/data/repositories` and queries them with `fossil sql --readonly`.
- [x] Decode delimiter-safe query results and escape every repository value at
  the HTML boundary.
- [x] Render the home, Explore, and repository pages from Tcl view modules;
  remove runtime dependence on static HTML templates.
- [x] Populate repository identity, counts, storage depth, contributors, open
  tickets, and the unified event timeline from the live Fossil artifact.
- [x] Keep JavaScript limited to theme, reveal/rail effects, card motion, and
  public mount-prefix adaptation. Initial content must be complete without it.
- [x] Add model and render tests, including hostile repository text, empty data,
  missing repositories, and public subdirectory routes.
- [ ] Superseded by the wider Phase 4 candidate below.

The immutable HTML prototype remains under `reference/` for visual comparison;
it is not a runtime data source.

## Phase 4: SQLite catalogue and first-party repository surfaces

Requested 2026-08-27. Releases in this phase use CalVer beginning with
`2026.08.27-beta.1`. The existing production image remains untouched until the
candidate passes every smoke and browser gate.

- [x] Add an application-owned SQLite catalogue under `/data/catalog/`, built
  atomically from read-only Fossil metadata without altering Fossil schemas.
- [x] Replace directory scanning at request time with indexed catalogue reads,
  literal search, type filters, deterministic sorting, and data-layer tests.
- [x] Keep Explore complete under SSR, then progressively enhance it with a
  debounced HTML-fragment search that remains mount-prefix safe.
- [x] Replace links to Fossil's native Timeline, Files, Docs, Wiki, Tickets,
  Forum, stats, and ZIP pages with first-party FossilHub routes and styling.
- [x] Preserve the native Fossil endpoint solely as the clone/sync transport;
  it must no longer be part of browser navigation.
- [x] Add an idempotent Tcl importer for the official Althttpd, Wapp, Fossil,
  and SQLite source repositories. Existing repository files are pulled, never
  overwritten; new clones are published by atomic rename.
- [x] Stop creating the demonstration repository on a clean data directory.
  Preserve any existing `dig.fossil` and bootstrap record as legacy data, but
  do not include them in the public catalogue.
- [ ] Build and smoke-test the committed x86_64 CalVer image on port 6082 with
  isolated cloned repositories, including search, each styled repository
  surface, clone/sync, persistence, permissions, responsive layouts, and the
  public subdirectory prefix.
- [ ] Update NAS production on port 6080 only after explicit authorization and
  retain the current container as a rollback target.
