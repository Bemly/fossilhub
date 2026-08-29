# FossilHub 2026.08.28-beta.1 validation

Validation date: 2026-08-29

Outcome: the Phase 5 candidate passed isolated NAS acceptance and is ready for
a separately authorized production preflight. It has not replaced production
on port 6080.

## Validated artifact

| Item | Value |
| --- | --- |
| Git revision in OCI label | `578fcff` |
| Image | `fossilhub:2026.08.28-beta.1` |
| Image ID | `sha256:c126646005c236fb10dcb1a4c1e2aa8ea5b22e23418aafa9619525e84242ba54` |
| Platform | `linux/amd64` |
| Source archive SHA-256 | `9f02a7a4feb5fd254b01ea34014342a2606677f4d42c6dee1b9cf22411452945` |
| Final smoke container | `fossilhub-beta-578fcff` |
| Final smoke port | `6083:8080` |
| Reused migration data | `/vol1/1000/fossilhub-smoke-e0cb8dc` |
| Clean initializer data | `/vol1/1000/fossilhub-smoke-578fcff-init` |

The source input was created with `git archive` from the committed revision.
The final smoke, test, and initializer containers are stopped and retained.
Their data and the intermediate smoke artifacts were not deleted.

## Automated verification

- `git diff --check`, both JavaScript syntax checks, the live-script suite, and
  all thirteen Tcl suites passed locally under Tcl 9.1b0.
- The same thirteen Tcl suites passed inside the final image under its packaged
  Tcl 9.1b0. The authentication suite used the packaged Argon2 binary rather
  than the fixture implementation.
- Wapp lint passed and the image reported Fossil 2.29 at the pinned upstream
  check-in.
- A clean final-image `fossilhub-init` run created exactly ten allow-listed
  repositories and the catalogue without relying on extra `HOME` or `USER`
  overrides.
- The final image started successfully on the existing Phase 5 data after
  several image replacements. Registry records, identities, catalogue state,
  and the isolated collaboration repository survived those restarts and
  migrations.

## HTTP, transport, and data verification

- The landing page, Explore SSR and fragment search, both browser scripts, all
  nine public information pages, and direct plus simulated mounted-prefix paths
  returned HTTP 200.
- Timeline, Files, Docs, Wiki, Tickets, Forum, Branches, Tags, and Statistics
  returned HTTP 200 for every allow-listed repository. Browser output contained
  no links into Fossil's native web interface.
- A private repository returned the same generic 404 as an unknown repository
  through both the browser and Fossil transport gates.
- A real HTTP `fossil clone` and `fossil sync` completed against the final
  image, and the client/server project codes matched.
- Repository integrity passed. The platform registry contained eleven records
  during end-to-end testing while the public catalogue retained only the ten
  active public repositories.
- Every repository, the catalogue database, the platform database, and the
  bootstrap administrator record remained owned by UID/GID 10001:10001 with
  mode 0600.

## Collaboration and administration verification

The isolated HTTP workflow exercised registration, login, logout and session
revocation; private repository creation; Writer collaboration; browser file,
Wiki, Ticket, and Forum mutations; dashboard and settings access; administrator
user/repository/audit/health/settings pages; recoverable archive and restore;
password rotation with rejection of the old password; redacted audit export;
and administrator catalogue rebuild. One-time CSRF challenges were consumed by
the real forms. Unit and service suites additionally covered challenge replay,
session expiry, login throttling, role boundaries, quota failures, rollback,
and quarantine paths.

All isolated test-account sessions were revoked after acceptance. No submitted
content, credential, cookie, challenge, or raw application log is included in
this record.

## Browser verification

- Light-mode layout passed at 1440 x 1000, 913 x 900, and 390 x 844 without
  horizontal overflow.
- Dark mode and reduced-motion preference passed at all three sizes for the
  landing page, Explore, and public status surfaces. Account and public pages
  were also checked after the system-theme consistency fix.
- Repository Timeline, Files, Wiki, Tickets, and Forum surfaces were traversed
  at the medium breakpoint; representative repository, status, Explore, and
  mounted-prefix pages were traversed on mobile.
- Mounted-prefix live catalogue search updated to one matching result and all
  generated internal links and clone commands retained the simulated prefix.
- The browser console reported no warnings or errors.

## Runtime security and lifecycle

The final smoke container used a read-only root filesystem, a 16 MiB
`/tmp` tmpfs with `nosuid,nodev,noexec`, all capabilities dropped,
`no-new-privileges`, PID limit 128, runtime UID/GID 10001:10001, the exact
isolated data mount, and no Docker socket or host networking.

The entrypoint forwards Docker stop signals to Althttpd and waits for it. The
final smoke container stopped in less than one second with exit code 143,
instead of reaching Docker's forced-stop timeout.

## Production boundary

Production remained `fossilhub:0.2.0-beta.1` at revision `0ac4dff` on port
6080 throughout validation and was healthy after the final smoke stop. No fnOS
system file, application-center state, unrelated container, production data,
rollback container, image, or volume was modified.

The only remaining Phase I action is the final production preflight and
transactional 6080 switch. It requires explicit authorization and must retain
the current production container as the immediate rollback target.
