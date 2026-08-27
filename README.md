# FossilHub

FossilHub is a Tcl/Wapp port of the three-page UI prototype in
`/Users/bemly/cchaha/fossiltest`.

The production target is an isolated Ubuntu 24.04 Docker container on fnOS.
Althttpd terminates HTTP and launches the Wapp application as CGI. The current
release faithfully serves the reference catalogue and activity content from
trusted UTF-8 templates. Release 0.2.0-beta.1 also serves a persistent, native
Fossil repository through Fossil's CGI directory mode. Repository source,
Wiki, Tickets, Forum, clone, and sync all use real Fossil artifacts.

Production is available on the NAS at `http://192.168.1.162:6080/`; its health
endpoint is `/healthz`, the reference repository page is
`/repo/dig.fossil`, and the native Fossil service is `/fossil/dig/`.

- [PLAN.md](PLAN.md) records implementation and acceptance status.
- [docs/operations.md](docs/operations.md) contains deployment, diagnostics,
  and rollback procedures.
- [docs/third-party.md](docs/third-party.md) records the pinned Tcl, Wapp,
  Althttpd, and Fossil sources.
