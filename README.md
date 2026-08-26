# FossilHub

FossilHub is a Tcl/Wapp implementation of the UI prototype in
`/Users/bemly/cchaha/fossiltest`.

The production target is an isolated Ubuntu 24.04 Docker container on fnOS.
Althttpd terminates HTTP and launches the Wapp application as CGI. SQLite stores
the repository catalogue and activity data.

See [PLAN.md](PLAN.md) for the implementation and deployment checkpoints.

