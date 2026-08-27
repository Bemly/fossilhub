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

## Tcl

- Project: Tcl core language runtime
- Upstream: `https://www.tcl-lang.org/software/tcltk/9.1.html`
- Version: 9.1b0 (official beta source release, 2026-06-30)
- Vendored archive: `vendor/tcl/tcl9.1b0-src.tar.gz`
- Archive SHA-256: `7a5cba88694512b12bd052e5ddc1c80a1eeed5247d57a7735306137fc7533d1d`
- License: Tcl/Tk license in the archive's root `license.terms`

The runtime image builds Tcl from this source instead of installing Ubuntu's
Tcl 8.6 package.

## Ubuntu runtime security tools

- `argon2`: the Ubuntu 24.04 package of the Password Hashing Competition
  reference command, used in Argon2id mode for central account passwords.
- `openssl`: the Ubuntu 24.04 command, used only for SHA-256 hashing of random
  session and form-challenge values before application-database storage.

Passwords are sent to Argon2 through standard input, never command arguments.
The configured Argon2id cost is 32 MiB, two iterations, and one lane, exceeding
the OWASP minimum memory recommendation while remaining bounded for the NAS.
Neither tool is used to read or mutate Fossil-owned repository schemas.

## Fossil SCM

- Project: Fossil distributed software configuration management
- Upstream: `https://fossil-scm.org/home/`
- Version: 2.29 development trunk
- Fossil check-in: `b8c7665e121b25c3ccc268edbab86ec27c72f7a3c0cd56fa1ed2762a84fadc38`
- Snapshot date: 2026-08-24 16:58:24 UTC
- Vendored archive: `vendor/fossil/fossil-b8c7665e121b.tar.gz`
- Archive SHA-256: `0aeb0d3a705de39bd0a7b103e718036b6ad126f12da0cdffe262cdc1f4c3dafd`
- License: 2-Clause BSD in the archive's `COPYRIGHT-BSD2.txt`

Fossil does not currently publish a 2.29 release tarball. The immutable trunk
check-in above is used deliberately as the current development build, while
the previous production container remains available for rollback.

## Development-channel interpretation

Wapp and Althttpd do not publish separately numbered beta channels. Their
official trunk leaves are therefore the precise development snapshots used by
this project. The pinned Wapp and Althttpd check-ins above were revalidated on
2026-08-27 and were already current; only the documented downstream Wapp Tcl
compatibility patch makes the vendored file differ from its upstream blob.

## Reference UI deviations

The reference snapshot is preserved unchanged in `reference/`. The production
explore template adds one narrow-screen rule (`.fgroup { flex-wrap: wrap; }`)
below 640 px so the language filter does not widen the document viewport.
