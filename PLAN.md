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
  -> executable Wapp CGI
  -> Tcl routing and trusted UTF-8 templates
```

Althttpd serves fingerprintable static assets directly and treats the executable
Wapp entry point as CGI. Wapp owns application routes and response handling. The
runtime data directory is mounted separately from the immutable application
image and currently stores request logs. SQLite is bundled for a future dynamic
catalogue phase; it is not part of the 0.1.2 request path.

## Route map

| Route | Reference | Purpose |
| --- | --- | --- |
| `/` | `fossilhub.html` | Product landing page |
| `/explore` | `explore.html` | Searchable repository catalogue |
| `/repo/dig.fossil` | `repo.html` | Repository specimen and timeline |
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

Acceptance completed against production release 0.1.2. The one intentional
deviation from the immutable reference snapshot is a mobile-only wrapping rule
for the Explore language filters below 640 px; it removes prototype-originated
horizontal overflow without changing the desktop composition.

## Phase 2: beta runtime and real Fossil service

Requested 2026-08-27. Release 0.1.2 remains the rollback baseline until every
item below is complete.

- [ ] Pin the latest official development snapshots of Wapp and Althttpd by
  immutable Fossil check-in, plus Tcl 9.1b0 and Fossil 2.29 source releases.
- [ ] Build Tcl 9.1b0, Wapp, Althttpd, and Fossil from source in a reproducible
  multi-stage Ubuntu 24.04 image.
- [ ] Add a persistent `/data/repositories` directory and idempotently bootstrap
  a real `dig.fossil` repository without exposing its setup password in logs.
- [ ] Serve the repository through Althttpd and Fossil's documented CGI
  `directory:` mode under `/fossil/dig/`.
- [ ] Preserve the reference UI composition while wiring repository navigation
  to live Timeline, Files, Docs, Wiki, Tickets, Forum, clone, and sync surfaces.
- [ ] Keep public access read-only by default; retain Fossil's own authenticated
  permission model for repository writes and administration.
- [ ] Verify a real HTTP clone, a pull/sync round trip, repository persistence
  across restart, CGI writes under UID/GID 10001, and all prior visual checks.
- [ ] Deploy only after smoke tests pass, retaining the current 0.1.2 container
  as the immediate rollback target and documenting credential recovery.
