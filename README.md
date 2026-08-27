# FossilHub

FossilHub is a Tcl/Wapp port of the three-page UI prototype in
`/Users/bemly/cchaha/fossiltest`.

The production target is an isolated Ubuntu 24.04 Docker container on fnOS.
Althttpd terminates HTTP and launches the Wapp application as CGI. The upcoming
0.3.0-beta.1 source tree discovers trusted repository artifacts, queries them
through `fossil sql --readonly`, and server-renders the catalogue, repository
metadata, counts, and unified timeline in Tcl. The browser receives complete
HTML; JavaScript only handles theme/motion and the public mount prefix. Native
Fossil still owns repository source, Wiki, Tickets, Forum, clone, and sync.

Production is available on the NAS at `http://192.168.1.162:6080/`; its health
endpoint is `/healthz`, the reference repository page is
`/repo/dig.fossil`, and the native Fossil service is `/fossil/dig/`.
Production remains 0.2.0-beta.1 until the Tcl SSR candidate completes the NAS
smoke and transactional deployment gates.

- [PLAN.md](PLAN.md) records implementation and acceptance status.
- [docs/operations.md](docs/operations.md) contains deployment, diagnostics,
  and rollback procedures.
- [docs/third-party.md](docs/third-party.md) records the pinned Tcl, Wapp,
  Althttpd, and Fossil sources.
