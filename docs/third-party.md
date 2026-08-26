# Third-party source record

The required upstream sources are vendored so NAS builds do not depend on a
moving branch or a successful connection to an external source host.

## Wapp

- Project: Wapp, a web-application framework for Tcl
- Upstream: `https://www.sqlite.org/wapp/`
- Version: 1.0
- Fossil check-in: `5be58cf34374ea230303ce2af9127496aa4117bc79b74f554b97d9ead3d5be88`
- Snapshot SHA-256: `4741f31927c0b1ee2fbc959179b806bafcec4e0ef7d4d36c7ea0eaf13ebb5f9c`
- License: Simplified BSD / 2-Clause BSD
- Vendored runtime: `vendor/wapp/wapp.tcl`

Downstream compatibility patch: `wapp-safety-check` enumerates Tcl procedures
with `info procs` instead of all commands. The upstream `info command` spelling
also returns built-in commands under Tcl 8.6, causing `info body` to fail before
the safety scan can run.

## Althttpd

- Project: Althttpd
- Upstream: `https://sqlite.org/althttpd/`
- Version: 2.0
- Fossil check-in: `641e31f18cff72151b1eee742abc3f067026e1d5c789f49de37b0b5adfd6922a`
- Snapshot SHA-256: `7f4e26404b44513fabaf1505b8eec573075766e5b32ef634fddd57ce7486d2ba`
- License statement: public-domain dedication in `althttpd.c`
- Vendored build input: `vendor/althttpd/`

The snapshot hashes identify the downloaded official tarballs. The repository
contains only the source and license files required to build and run FossilHub.

## Reference UI deviations

The reference snapshot is preserved unchanged in `reference/`. The production
explore template adds one narrow-screen rule (`.fgroup { flex-wrap: wrap; }`)
below 640 px so the language filter does not widen the document viewport.
