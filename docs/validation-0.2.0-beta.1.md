# FossilHub 0.2.0-beta.1 validation

Validation completed: 2026-08-27

## Candidate

- Source revision: `188b918`
- Image: `fossilhub:0.2.0-beta.1`
- Image ID: `sha256:22fc745e0d795327c6e5eb8ac5aba75379a2bd41498916adb3bd56ccec3d224e`
- OCI revision label: `188b918`
- Temporary container: `fossilhub-beta-final-188b918`
- Temporary endpoint: `http://192.168.1.162:6082/`

The production container was not changed during this validation. It remains
the healthy `fossilhub:0.1.2` instance on host port 6080.

## Runtime versions

- Tcl 9.1b0
- Wapp 1.0 from official trunk check-in
  `5be58cf34374ea230303ce2af9127496aa4117bc79b74f554b97d9ead3d5be88`
- Althttpd 2.0 from official trunk check-in
  `641e31f18cff72151b1eee742abc3f067026e1d5c789f49de37b0b5adfd6922a`
- Fossil 2.29 development trunk check-in
  `b8c7665e121b25c3ccc268edbab86ec27c72f7a3c0cd56fa1ed2762a84fadc38`

## Automated and HTTP checks

- The Wapp safety lint and Tcl route tests pass under Tcl 9.1b0.
- The container health check reaches `healthy` before route testing begins.
- Hub routes `/`, `/explore`, `/repo/dig.fossil`, `/healthz`,
  `/fossilhub-live.js`, and the nested integration-script route return HTTP 200.
- Native Fossil Timeline, Files, Wiki, Tickets, Forum, and trunk ZIP routes
  return HTTP 200.
- A real HTTP `fossil clone` produces the same project code as the server
  repository.
- A subsequent `fossil sync` completes in one round trip with no missing
  artifacts.

## Persistence and permissions

- The seeded repository contains two real check-ins plus Wiki and Ticket
  artifacts.
- Repository identity, check-in count, repository bytes, and the bootstrap
  administrator record remain unchanged across image replacement and container
  restart.
- The repository and bootstrap administrator record are mode 0600 and owned by
  UID/GID 10001:10001.
- The bootstrap password is not written to container logs or this repository.
- The container uses a read-only root filesystem, a dedicated `/tmp` tmpfs,
  dropped Linux capabilities, `no-new-privileges`, and a 128-process limit.

## Browser acceptance

- Desktop verification: 1280 x 720 viewport, no horizontal overflow and no
  browser console warnings or errors.
- Mobile verification: 390 x 844 viewport, no horizontal overflow and no
  browser console warnings or errors.
- Theme switching changes the active colour theme.
- Clicking Timeline in the reference UI reaches the native Fossil Timeline,
  whose rendered page reports two check-ins.
- With a simulated `/bemly-moe/app/fossilhub/` pathname, clone, Timeline, and
  ZIP URLs retain that complete fnOS mount prefix.

## Production gate

The remaining operation is the production container replacement. Retain the
current 0.1.2 container as `fossilhub-rollback-8c9726d`, start the candidate on
the same dedicated data volume and port, and automatically restore 0.1.2 if the
candidate does not become healthy. This step requires explicit production
change approval.
