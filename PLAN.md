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
  -> Tcl page/view procedures
  -> SQLite catalogue
```

Althttpd serves fingerprintable static assets directly and treats the executable
Wapp entry point as CGI. Wapp owns application routes, input validation, HTML
escaping, and database reads. Runtime database state is mounted separately from
the immutable application image.

## Route map

| Route | Reference | Purpose |
| --- | --- | --- |
| `/` | `fossilhub.html` | Product landing page |
| `/explore` | `explore.html` | Searchable repository catalogue |
| `/repo/dig.fossil` | `repo.html` | Repository specimen and timeline |
| `/healthz` | — | Container health check |

## Milestones

1. Create the Git repository and record this plan.
2. Audit NAS Docker networking, ports, storage, and architecture read-only.
3. Add the vendored reference snapshot and a deterministic comparison manifest.
4. Scaffold Wapp routing, static asset delivery, and health checks.
5. Port the three reference pages into Tcl views without visual changes.
6. Add SQLite schema, seed data, search/filter behaviour, and tests.
7. Build the Ubuntu/althttpd/Wapp image locally and verify HTTP behaviour.
8. Compare reference and implementation screenshots at desktop and mobile sizes.
9. Deploy as a new NAS container with a dedicated volume and unused host port.
10. Verify health, routes, logs, restart behaviour, and document operations.

## Visual acceptance

- Desktop: 1440 x 1000 for all three pages in light and dark themes.
- Mobile: 390 x 844 for all three pages.
- No accidental horizontal overflow, missing SVG art, console error, or broken link.
- Typography, spacing, colours, borders, responsive breakpoints, and motion follow
  the reference files; reduced-motion mode remains functional.

