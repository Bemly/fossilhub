# FossilHub

FossilHub is a Tcl/Wapp port of the three-page UI prototype in
`/Users/bemly/cchaha/fossiltest`.

The production target is an isolated Ubuntu 24.04 Docker container on fnOS.
Althttpd terminates HTTP and launches the Wapp application as CGI. The current
release faithfully serves the reference catalogue and activity content from
trusted UTF-8 templates. SQLite is installed in the runtime image for a future
dynamic-data phase, but no database is required by release 0.1.2.

Production is available on the NAS at `http://192.168.1.162:6080/`; its health
endpoint is `/healthz`.

- [PLAN.md](PLAN.md) records implementation and acceptance status.
- [docs/operations.md](docs/operations.md) contains deployment, diagnostics,
  and rollback procedures.
- [docs/third-party.md](docs/third-party.md) records the pinned Wapp and
  althttpd sources.
