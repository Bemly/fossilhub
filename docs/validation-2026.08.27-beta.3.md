# FossilHub 2026.08.27-beta.3 validation

Validation completed: 2026-08-27

## Candidate

- Source revision: `1d0bcfa`
- Image: `fossilhub:2026.08.27-beta.3`
- Image ID:
  `sha256:8315f667a91871d0e05b6b1f2156f7ba7099fb11e36e955d7e2ecc29cf8c7248`
- OCI revision label: `1d0bcfa`
- Smoke container: `fossilhub-beta-1d0bcfa`
- Smoke endpoint: `http://192.168.1.162:6082/`
- Isolated data: `/tmp/fossilhub-smoke-blank-9GJmZB`

Production port 6080 remained on `fossilhub:0.2.0-beta.1` throughout this
validation and stayed healthy. This CalVer image is a candidate, not the
production image.

## Runtime and automated tests

- The x86_64 NAS build completed from `git archive 1d0bcfa`.
- OCI labels identify revision `1d0bcfa` and version
  `2026.08.27-beta.3`.
- Tcl 9.1b0, Fossil 2.29, and Wapp lint passed during the image build.
- Route, model, catalogue, view, and repository-data tests passed inside the
  candidate image under Tcl 9.1b0.
- The repository-data suite runs with `GATEWAY_INTERFACE=CGI/1.1` and proves
  that Tcl launches Fossil CLI children with `--nocgi`.

## Repository and HTTP acceptance

- The idempotent initializer created exactly ten repositories: `bedrock`,
  `ammonite`, `trilobite`, `basalt`, `cambrian`, `granite`, `shale`, `quartz`,
  `obsidian`, and `tectonic`.
- Each repository contains Fossil's required initial empty check-in and no
  source files, Wiki pages, tickets, forum posts, or imported history.
- The application catalogue contains exactly the ten manifest repositories.
- `/`, `/healthz`, `/explore`, live catalogue fragments, both integration
  scripts, all ten repository roots, and the first-party Timeline, Files,
  Docs, Wiki, Tickets, and Forum surfaces returned HTTP 200.
- Rendered FossilHub pages contain no navigation link to `/fossil/*`; that
  endpoint remains available only to Fossil clone and sync clients.
- A real HTTP clone of `bedrock` completed, retained the server project code,
  and a subsequent sync completed successfully.

## Persistence and permissions

- Re-running the initializer left the aggregate hash of all ten repository
  files unchanged and rebuilt a ten-row catalogue.
- Restarting the smoke container preserved repository identity and restored a
  healthy service.
- Every repository and the catalogue database are mode 0600 and owned by
  UID/GID 10001:10001.
- The smoke container uses a read-only root filesystem, a 16 MB `/tmp` tmpfs,
  dropped capabilities, `no-new-privileges`, and a 128-process limit.

## Browser acceptance

- Desktop 1440 x 900, medium 913 px, and mobile 390 x 844 layouts have no
  horizontal overflow or broken images.
- The 390 px repository view exposes the first-party Timeline, Files, Docs,
  Wiki, Tickets, and Forum tabs without linking to native Fossil pages.
- Searching for `quartz` updates the URL and result fragment to one match
  without a full page navigation.
- Browser console checks reported no warnings or errors.
- A simulated `/bemly-moe/app/fossilhub/` pathname loaded its stylesheet,
  kept the complete mount prefix in the clone command, and had no horizontal
  overflow at 390 px.

## Remaining release gate

Port 6080 has not been switched. A production replacement still requires an
explicit authorization for `2026.08.27-beta.3` and a final transactional
preflight that retains the current container as a rollback target.
