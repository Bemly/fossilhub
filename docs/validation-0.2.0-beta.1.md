# FossilHub 0.2.0-beta.1 validation

Validation completed: 2026-08-27

## Candidate

- Final source revision: `0ac4dff`
- Base candidate revision: `188b918`
- Image: `fossilhub:0.2.0-beta.1`
- Image ID: `sha256:8b873837f192be367314fbacbb21940aa18071bb887ef39a9ac44235384b95f9`
- OCI revision label: `0ac4dff`
- Production container: `fossilhub`
- Production endpoint: `http://192.168.1.162:6080/`

The temporary 6082 validation container is stopped. Production 6080 is healthy
on the final image; revisions `188b918` and `8c9726d` are retained as the two
immediate rollback containers.

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
- Medium-width verification: 913 x 720 viewport, no horizontal overflow and no
  browser console warnings or errors. Revision `0ac4dff` hides the long header
  clone command below 1100 px while preserving the navigation.
- Theme switching changes the active colour theme.
- Clicking Timeline in the reference UI reaches the native Fossil Timeline,
  whose rendered page reports two check-ins.
- With a simulated `/bemly-moe/app/fossilhub/` pathname, clone, Timeline, and
  ZIP URLs retain that complete fnOS mount prefix.

## Production deployment

Production deployment completed after explicit approval. The existing 0.1.2
container was retained as `fossilhub-rollback-8c9726d`; the first beta image was
retained as `fossilhub-rollback-188b918` after the medium-width hotfix. The final
container reached healthy state, preserved repository identity and check-in
count, passed all listed HTTP routes, and completed a fresh clone plus sync.
