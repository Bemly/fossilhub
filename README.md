# FossilHub

FossilHub is a Tcl/Wapp port of the three-page UI prototype in
`/Users/bemly/cchaha/fossiltest`.

The production target is an isolated Ubuntu 24.04 Docker container on fnOS.
Althttpd terminates HTTP and launches the Wapp application as CGI. Candidate
`2026.08.27-beta.3` uses an application-owned SQLite catalogue for search and
filters, then queries each repository through `fossil sql --readonly` for Tcl
server-rendered Timeline, Files, Docs, Wiki, Tickets, and Forum surfaces. The
browser receives complete HTML; JavaScript progressively enhances catalogue
search, theme, motion, and public mount-prefix adaptation.

The catalogue contains ten clean local Fossil repositories with no imported or
demonstration history. Fossil's CGI endpoint remains available for clone and
sync transport, but browser navigation stays inside FossilHub's visual system.
The previous generated `dig.fossil` is no longer created or indexed.

Production is available on the NAS at `http://192.168.1.162:6080/`; its health
endpoint is `/healthz`, the reference repository page is
`/repo/dig.fossil`, and the native Fossil service is `/fossil/dig/`.
Production remains 0.2.0-beta.1 until the Tcl SSR candidate completes the NAS
smoke and transactional deployment gates.

Candidate routes begin at `/explore` and `/repo/bedrock.fossil`. The image tag
is `fossilhub:2026.08.27-beta.3`; [VERSION](VERSION) is the release source of
truth.

Phase 5 development adds a separate versioned platform database at
`/data/platform/fossilhub.sqlite` for central identities, authorization,
sessions, audit events, settings, and the dynamic repository registry. The ten
candidate repositories are imported into that registry idempotently; Fossil
repository files remain untouched and continue to be the artifact source of
truth. See [docs/platform-roadmap.md](docs/platform-roadmap.md) for the ordered
implementation and acceptance checklist.

- [PLAN.md](PLAN.md) records implementation and acceptance status.
- [docs/operations.md](docs/operations.md) contains deployment, diagnostics,
  and rollback procedures.
- [docs/third-party.md](docs/third-party.md) records the pinned Tcl, Wapp,
  Althttpd, and Fossil sources.
