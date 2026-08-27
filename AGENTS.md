# FossilHub agent operating guide

This file applies to the entire repository. Treat it as the durable handoff for
future coding and NAS operations. When it conflicts with a current explicit
user instruction, stop and resolve the conflict before making a destructive or
production change.

## Non-negotiable safety boundaries

- Never commit, print, document, or return the fnOS SSH/sudo password, Fossil
  administrator password, API keys, webhook tokens, or other credentials. The
  agent may authenticate non-interactively with a password explicitly supplied
  by the user for the current task; keep it transient, filter authentication
  prompts from captured output, and never save it in this repository, a helper
  script, Git configuration, or documentation. Do not require manual SSH
  authentication when the user has supplied and authorized a working password.
- Treat Docker and application logs as sensitive. Logs from unrelated services
  may include tokens in query strings or message content. Prefer targeted
  status/health queries; never dump broad logs into Git or a response.
- Do not modify fnOS itself: no changes under `/usr/trim`, no nginx changes, no
  systemd unit changes, and no PostgreSQL system-schema changes. Read-only
  inspection is allowed when relevant.
- Never execute `/usr/trim/bin/trim_app_center` without arguments. A bare run
  starts a second daemon whose initialization can clear the app-center service
  tables and make every application disappear from the panel. Use `--help` for
  help, and do not involve app-center machinery in FossilHub operations.
- Do not start, stop, restart, rename, remove, reconfigure, or reuse ports from
  these unrelated containers unless the user explicitly asks for that exact
  action: `llonebot`, `napcat-docker`, `astrbot`, `chromium`, `Ayu`, `db2`, and
  `redis`. Do not assume their current running state; inspect read-only and
  report anomalies.
- `llonebot` deliberately owns ports 616 and 3080. `napcat-docker` owns
  6099-6100. `Ayu` uses 6160 when running. DeepSeek Harness uses 6000 and must
  bind `127.0.0.1`. FossilHub production owns 6080. Always confirm a temporary
  port is unused before binding it; 6082 is the established smoke-test port.
- Never delete `/vol1/1000/dsh-fnos-dist`; unrelated DeepSeek profiles use its
  tarballs through `file:` dependencies.
- Do not delete a production data directory, Docker volume, image, or rollback
  container merely because it looks old. Resolve the exact target and its role
  first. Test containers use `fossilhub-beta-*`; rollback containers use
  `fossilhub-rollback-*` and are intentionally retained.

## fnOS connection and shell discipline

- Target: fnOS 1.2.0401, hostname `MEminiFnOS`, x86_64.
- Use the configured alias `fnOS`. Authentication details belong only in the
  current authorized session or a secure local store, never in this repository
  or `AGENTS.md`.
- Remote Docker access requires sudo. Suppress the sudo prompt with `-p ''` and
  filter password prompts from captured output. Non-interactive password SSH
  and sudo are allowed when explicitly authorized by the user, but the password
  must remain transient and must not be written to a saved script, Git
  configuration, shell history, documentation, logs, or replies.
- Commands run through remote `sh -c` must be quoted deliberately. In the local
  zsh, unquoted strings such as `===name===` can be treated as glob patterns.
- A background process can keep an SSH pipe open after the useful command has
  finished. If backgrounding is truly required, detach stdin with
  `</dev/null &`; otherwise prefer foreground commands. If an SSH call times
  out after a Docker action, reconnect and inspect actual state before retrying.
  Never blindly repeat a container rename or production switch.
- Avoid broad compound commands for production changes. Re-check exact names,
  image revisions, ports, and mounts immediately before mutation.

## Relevant fnOS paths

- Generic native applications:
  - `/vol1/@appcenter/`
  - `/vol1/@apphome/<app>/`
  - `/vol1/@appdata/<app>/`
  - `/vol1/@appconf/`, `/vol1/@appmeta/`, `/vol1/@apptemp/`
  - `/var/apps/<pkg>/cmd/main`
  - `/var/apps_ui/<pkg>/`
- User-managed data: `/vol1/1000/`
- FossilHub persistent data: `/vol1/1000/fossilhub/`
- FossilHub live repository:
  `/vol1/1000/fossilhub/repositories/dig.fossil`
- Candidate catalogue database:
  `/vol1/1000/fossilhub/catalog/fossilhub.sqlite`
- Candidate official repositories:
  `/vol1/1000/fossilhub/repositories/{sqlite,fossil,wapp,althttpd}.fossil`
- Fossil bootstrap administrator record:
  `/vol1/1000/fossilhub/fossil-bootstrap-admin.txt`
- The repository and bootstrap record must remain mode 0600 and owned by
  UID/GID 10001:10001. Read the bootstrap record only in a trusted interactive
  SSH terminal; never include its contents in logs, tests, commits, or replies.
- Every official repository and the catalogue database must also remain mode
  0600 and owned by UID/GID 10001:10001. `dig.fossil` and its bootstrap record
  are retained as legacy production data even though the CalVer catalogue does
  not expose them.

## Current FossilHub production state

- Site: `http://192.168.1.162:6080/`
- Health: `http://192.168.1.162:6080/healthz`
- Reference repository UI: `http://192.168.1.162:6080/repo/dig.fossil`
- Native Fossil service: `http://192.168.1.162:6080/fossil/dig/`
- Container: `fossilhub`
- Image tag: `fossilhub:0.2.0-beta.1`
- Deployed code revision: `0ac4dff`
- Mount: `/vol1/1000/fossilhub:/data`
- Port: `6080:8080`
- Restart policy: `unless-stopped`
- Runtime user: `fossilhub:fossilhub` (UID/GID 10001:10001)
- Security profile: read-only root, 16 MB `/tmp` tmpfs, all capabilities
  dropped, `no-new-privileges`, and PID limit 128.
- Preferred rollback: stopped container `fossilhub-rollback-188b918`.
- Stable rollback: stopped container `fossilhub-rollback-8c9726d` (0.1.2).
- Older stopped rollback containers `fossilhub-rollback-94f8097` and
  `fossilhub-rollback-348f399` are also intentionally retained.

Container names are operational facts, not a license to mutate them. Inspect
before acting because another operator may have changed the NAS since this file
was last updated. `docs/operations.md` is the detailed runbook and must be kept
in sync with production.

The source candidate is `2026.08.27-beta.1`. It is not production until its NAS
validation record and transactional port-6080 switch are complete.

## Runtime and source pins

- Ubuntu 24.04 multi-stage image.
- Tcl 9.1b0 from `vendor/tcl/tcl9.1b0-src.tar.gz`.
- Wapp 1.0 from official trunk check-in
  `5be58cf34374ea230303ce2af9127496aa4117bc79b74f554b97d9ead3d5be88`.
- Althttpd 2.0 from official trunk check-in
  `641e31f18cff72151b1eee742abc3f067026e1d5c789f49de37b0b5adfd6922a`.
- Fossil 2.29 development trunk check-in
  `b8c7665e121b25c3ccc268edbab86ec27c72f7a3c0cd56fa1ed2762a84fadc38`.
- Wapp and Althttpd do not publish separately numbered beta channels; their
  pinned official trunk leaves are the intended development versions.
- Keep vendored archive hashes and upstream provenance in
  `docs/third-party.md`. Never silently replace a vendored source snapshot.
- The Wapp safety patch using `info procs` instead of `info command` is
  intentional Tcl compatibility work; preserve or revalidate it on upgrades.

## Application architecture

```text
browser
  -> fnOS host port 6080
  -> isolated Ubuntu container
  -> althttpd :8080
     -> executable Wapp CGI for the reference hub UI
     -> Tcl SSR repository surfaces and SQLite catalogue search
     -> Fossil CGI `directory:` mode only for clone/sync transport
  -> `/data/catalog/fossilhub.sqlite`
  -> `/data/repositories/{sqlite,fossil,wapp,althttpd}.fossil`
```

- `app/fossilhub.tcl` owns Wapp routing and Tcl SSR response delivery.
- `app/lib/repository-manifest.tcl` is the allow-list for the four official
  repository names, source URLs, and catalogue facets. Files outside that list
  are never published merely because they end in `.fossil`.
- `app/lib/fossil-model.tcl` queries repository metadata, history, trunk files,
  Wiki artifacts, Tickets, and Forum activity through Fossil's
  `sql --readonly` interface. Query values are hex-encoded before crossing the
  process boundary and decoded in Tcl.
- `app/lib/catalog-model.tcl` owns the separate application SQLite schema,
  literal search, filters, sorting, and atomic index replacement. This is the
  only database the application may open with raw `sqlite3`.
- `app/lib/view.tcl` owns HTML escaping, formatting, and reusable repository,
  catalogue, composition, and timeline renderers.
- `app/views/` contains Tcl view modules for the reference-derived home,
  Explore, and repository pages. Runtime `.html` templates do not exist.
- `app/public/fh.css` is the shared design system.
- `app/views/repository-sections.tcl` renders the first-party Timeline, Files,
  Docs, Wiki, Tickets, and Forum surfaces. Browser navigation must not link to
  Fossil's built-in web pages.
- `app/public/fossilhub-live.js` derives the runtime mount prefix, rewrites
  internal `data-hub-path` links, and produces clone commands. It reads the
  active repository slug from the server-rendered `body` data attribute.
- `app/public/catalog-search.js` progressively enhances the complete Explore
  SSR form with debounced HTML-fragment replacement.
- `app/cgi/fossil` is Fossil's CGI directory-mode launcher.
- `app/bin/fossilhub-sync` idempotently pulls or atomically clones the four
  manifest repositories, sets mode 0600, removes capabilities from Fossil's
  generated local user, and rebuilds the catalogue. Fossil clone output must
  remain suppressed because it contains an automatically generated password.
  A trusted runtime-only proxy may be passed as `FOSSILHUB_SYNC_PROXY` when
  direct Fossil transport stalls; never write that value into the image.
- `app/bin/fossilhub-entrypoint` never clones or creates repositories. It only
  creates the data subdirectories and rebuilds the catalogue from official
  repository files already present on the mount.
- Fossil owns its repository SQLite schema. Do not manually alter internal
  Fossil tables to implement application features.

## Public subdirectory routing

The public fnOS path is mounted below a variable prefix similar to:

```text
https://5ddd.com/bemly-moe/app/fossilhub/...
```

Only the application subtree is forwarded to the NAS. Root-relative browser
URLs such as `/api/*` or `/fossil/*` can escape the mount and produce a login
redirect or 404. The server cannot infer the external prefix.

- Browser URLs must derive the mount prefix from `window.location.pathname` at
  runtime, as `fossilhub-live.js` does.
- Every internal browser link that cannot be expressed safely as a relative URL
  must use `data-hub-path`; every displayed clone command must use
  `data-clone-command`. `data-fossil-path` is not used for browser navigation.
- Test both direct LAN paths and a simulated
  `/bemly-moe/app/fossilhub/...` pathname.
- Do not regress nested asset routes such as
  `/repo/fossilhub-live.js`.
- Static assets currently use a one-hour cache. If CSS or JavaScript changes in
  a hot deployment, use a versioned asset URL or otherwise prove that existing
  browsers will fetch the new asset; a normal reload may reuse stale CSS.

## UI and code standards

- Preserve the immutable source prototype in `reference/`; do not edit it.
- Treat the visual direction as a 1:1 implementation, not an invitation to
  redesign. Preserve typography, spacing, colours, geological motifs, borders,
  theme behaviour, motion, and responsive composition.
- Small responsive corrections are allowed only to prevent demonstrable
  clipping or overflow. Existing intentional corrections are:
  - Explore language filters wrap below 640 px.
  - The long header clone command is hidden below 1100 px.
- Keep Tcl view modules valid UTF-8. Escape all Fossil-controlled values at the
  final HTML boundary; only renderer-owned fragments may bypass escaping. Serve
  CSS as `text/css; charset=utf-8` and the integration script as
  `text/javascript; charset=utf-8`.
- Repository reads must use Fossil's `sql --readonly` command. Do not open live
  repository files with raw SQLite for application queries, and never mutate
  Fossil-owned tables. Raw `sqlite3` access is restricted to the separate
  `/data/catalog/fossilhub.sqlite` application index.
- Runtime pages must be complete server-rendered HTML. Do not require JavaScript
  to fetch repository identity, counts, cards, or timeline events.
- Only serve files through trusted, fixed paths. Never concatenate an
  unvalidated request path into a filesystem path.
- Keep mount-prefix knowledge in browser code. Do not hardcode the external
  `5ddd.com` prefix or assume the LAN root is the public root.
- Shell entrypoints use `set -eu`, restrictive `umask`, quoted variables,
  atomic temporary files, and cleanup traps. Temporary directories must be
  exact `mktemp` results before recursive deletion.
- Do not log generated passwords. The CalVer importer clones public upstreams
  and does not create local administrators or bootstrap records.
- Keep the runtime root filesystem read-only and write only to `/data` and the
  `/tmp` tmpfs. Do not add Docker socket access, host networking, privileged
  mode, or extra capabilities.
- Prefer a narrow dependency set. Runtime packages are currently
  `ca-certificates`, `curl`, and `sqlite3`; Tcl, Fossil, and Althttpd are built
  from pinned sources.
- Image builds must set `FOSSILHUB_REVISION` so the OCI revision label identifies
  the exact code commit. The deploy documentation commit may follow the image
  commit and therefore have a newer Git revision.

## Verification gates

Before a production switch:

1. Work from a committed revision; create the NAS build input with
   `git archive`, never from a dirty worktree.
2. Run `git diff --check` and `node --check` for both scripts under
   `app/public/`.
3. Run `tests/routes.test.tcl`, `tests/model.test.tcl`,
   `tests/catalog.test.tcl`, `tests/repository-data.test.tcl`, and
   `tests/views.test.tcl` under the image's Tcl 9.1b0. macOS system Tcl may be
   8.5 and is not authoritative.
4. Build on the x86_64 NAS and confirm Tcl 9.1b0, Fossil 2.29, Wapp lint, and the
   OCI Git revision label.
5. Use `fossilhub-sync` to populate an isolated temporary data directory, then
   start a uniquely named `fossilhub-beta-*` container on confirmed-free port
   6082.
6. Verify HTTP 200 for `/`, `/healthz`, Explore SSR queries and fragments, both
   scripts, and Timeline, Files, Docs, Wiki, Tickets, and Forum for all four
   official repositories. Assert generated pages contain no native Fossil web
   links.
7. Perform a real HTTP `fossil clone` followed by `fossil sync`; compare its
   project code with the corresponding server repository.
8. Replace the smoke image while reusing its data directory, then restart it.
   Confirm project codes, check-in counts, repository identities, and catalogue
   membership do not change.
9. Verify file modes and ownership are 0600 and 10001:10001.
10. Browser-test desktop, 913 px medium width, and 390 x 844 mobile. Check for
    horizontal overflow, missing assets, broken links, stale cached assets, and
    console warnings/errors. Exercise live catalogue search and every
    first-party repository tab.
11. Re-check the production container, rollback name, port 6080 owner, data
    mount, and candidate health immediately before switching.

Production replacement must be transactional: retain the running container by
renaming it to a unique rollback name, start the candidate with the same mount
and security restrictions, wait for `healthy`, and automatically restore the
prior container if startup or health fails. Never retry a timed-out rename/run
sequence without first reconnecting and inspecting actual state.

After deployment, repeat health, routes, clone/sync, repository identity,
permissions, and browser checks. Stop smoke containers. Remove them only after
the user asks for cleanup and exact names have been listed. Keep rollback
containers unless the user explicitly asks to delete them.

## Git and workspace discipline

- Commit every coherent operation separately so changes remain reversible.
  Typical boundaries are plan/docs, vendored sources, build/runtime, repository
  bootstrap, UI integration, responsive fix, and deployment documentation.
- Use concise imperative commit subjects such as `feat:`, `fix:`, `build:`,
  `test:`, and `docs:`.
- Never amend, squash, reset, force-push, or rewrite published history unless
  explicitly requested.
- Preserve unrelated dirty work and untracked files. In particular, the PNG/SVG
  Logo, trilobite, ammonite, and bone-triad candidates under `app/public/` are
  user-owned experiments. Do not modify, delete, or commit them unless the user
  explicitly selects assets to adopt.
- Stage explicit paths, not `git add .`, when unrelated files exist.
- Before pushing, inspect the staged diff, run secret-pattern checks, verify the
  destination owner/repository, and confirm the branch and remote URL.
- Never commit build archives in `dist/`, NAS `/tmp` contents, generated Fossil
  repositories, administrator records, logs, or local credentials.

## GitHub publication

- Intended owner/repository: `bemly/fossilhub` (GitHub account may be displayed
  as `Bemly`; repository names are case-insensitive).
- Default branch: `main`.
- Prefer GitHub CLI with the already authenticated account. Check whether the
  repository exists before creating it, do not overwrite an unrelated remote,
  and do not force-push.
- Keep the local `origin` URL and publication state documented through normal
  Git configuration; do not store access tokens in remote URLs.

## Keeping this guide current

Update `AGENTS.md`, `README.md`, `PLAN.md`, `docs/operations.md`, and
`docs/validation-*.md` whenever a release changes ports, paths, runtime pins,
security settings, production revisions, rollback names, or verification
requirements. Operational facts become stale; safety boundaries do not.
