# FossilHub production operations

Deployment verified: 2026-08-29

## Current production

- Site: `http://192.168.1.162:6080/`
- Health: `http://192.168.1.162:6080/healthz`
- Container: `fossilhub`
- Image: `fossilhub:2026.08.28-beta.1`
- Image ID: `sha256:c126646005c236fb10dcb1a4c1e2aa8ea5b22e23418aafa9619525e84242ba54`
- Source revision label: `578fcff`
- Host/container port: `6080:8080`
- Persistent data: `/vol1/1000/fossilhub:/data`
- Restart policy: `unless-stopped`

The container runs as UID/GID `10001:10001` with a read-only root filesystem,
a 16 MB `/tmp` tmpfs, all Linux capabilities dropped, `no-new-privileges`, and
a 128-process limit. It does not use host networking, the Docker socket, or an
fnOS system path.

## Routes

| Route | Expected result |
| --- | --- |
| `/` | FossilHub landing page |
| `/explore` | Repository catalogue |
| `/repo/bedrock.fossil` | Repository specimen and timeline |
| `/repo/bedrock.fossil/files` | Versioned source tree |
| `/repo/bedrock.fossil/wiki` | First-party Wiki |
| `/repo/bedrock.fossil/tickets` | First-party Tickets |
| `/repo/bedrock.fossil/forum` | First-party Forum |
| `/fh.css` | Shared stylesheet |
| `/healthz` | HTTP 200 with `ok` |
| `/fossil/bedrock` | Fossil clone/sync transport only |
| `/dashboard` | Signed-in user workspace |
| `/admin` | Administrator workspace |

Legacy prototype paths `/explore.html` and `/repo.html` remain valid.

## Deployed CalVer release

Release `2026.08.28-beta.1` was transactionally deployed on 2026-08-29 after
isolated validation finished for OCI revision `578fcff`, image ID
`sha256:c126646005c236fb10dcb1a4c1e2aa8ea5b22e23418aafa9619525e84242ba54`.
The stopped `fossilhub-beta-578fcff` container and its isolated data at
`/vol1/1000/fossilhub-smoke-e0cb8dc` are retained; port 6083 is no longer bound
by that container. See
[validation-2026.08.28-beta.1.md](validation-2026.08.28-beta.1.md).

Wapp request processes carry CGI environment variables, so application-side
Fossil CLI queries must include Fossil's `--nocgi` global option. Its public
catalogue is an application-owned SQLite database at
`/data/catalog/fossilhub.sqlite`, rebuilt atomically from ten clean local
repositories: Bedrock, Ammonite, Trilobite, Basalt, Cambrian, Granite, Shale,
Quartz, Obsidian, and Tectonic. They begin with no check-ins, Wiki pages,
Tickets, Forum posts, files, or imported upstream history beyond Fossil's
required initial empty check-in.

The release does not create `dig.fossil`. The previous production data,
including its legacy repository and bootstrap record, is retained separately at
`/vol1/1000/fossilhub-rollback-0ac4dff-data` for rollback and is not mounted by
the current production container.

Phase 5 provides a second application-owned database at
`/data/platform/fossilhub.sqlite`. It is the versioned source of truth for the
repository registry and, as later Phase 5 milestones land, central accounts,
sessions, memberships, settings, and audit events. Startup creates or migrates
this database before rebuilding the public catalogue. The file is mode 0600;
its parent directory is mode 0750. It is not a Fossil repository and must never
be opened or modified with Fossil commands.

The identity slice exposes `/register`, `/login`, `/logout`, and
`/account/security`. Password processing uses the Ubuntu Argon2 command with
Argon2id parameters `m=32768,t=2,p=1`; passwords are supplied on standard input
and are never command arguments or log fields. Session identifiers and form
challenges are random; only their SHA-256 hashes are stored. Password changes
revoke every existing session and issue a new session cookie.

The repository workspace is available at `/account/repositories`. Authenticated
users can create public or private repositories, manage metadata and
collaborators according to their repository role, and archive or restore owned
repositories. Repository creation uses a per-name atomic lock, initializes a
same-directory temporary Fossil file, removes the generated local
administrator's capabilities, applies mode 0600, then publishes the file and
registry record. Catalogue failure removes the public registry record and moves
the unpublished file into `/data/quarantine`; it is never silently deleted.
Normal archive operations also move the exact repository file into that
quarantine directory and retain a restorable registry record.

Authenticated repository workbenches live below `/repo/<name>/files/new`,
`/file/<artifact>/edit`, `/wiki/new`, `/wiki-page/<artifact>/edit`,
`/tickets/new`, `/ticket/<id>`, `/forum/new`, and
`/forum/<post>/reply`. File and Wiki writes require Writer; Ticket and Forum
writes require Triage. Each operation consumes a one-time form challenge,
serializes writes with a repository lock, records the central username as the
Fossil artifact author, and atomically rebuilds the public catalogue. Central
passwords are never copied into Fossil: managed Fossil users receive random,
Fossil-only credentials, and Forum credentials are rotated for each internal
submission. The default repository storage quota is 512 MiB and can be lowered
or raised for a deployment with `FOSSILHUB_REPOSITORY_QUOTA_BYTES` (1 MiB to
1 TiB); invalid values fail closed.

On the first Phase 5 startup, `/usr/local/bin/fossilhub-bootstrap-admin`
creates the central `warden` administrator and writes its one-time credential
to:

```text
/vol1/1000/fossilhub/platform/fossilhub-bootstrap-admin.txt
```

The record is mode 0600 and owned by UID/GID 10001:10001. Read it only in a
trusted interactive SSH terminal, never through logs or a captured automation
command, and change the password immediately through `/account/security`.
Startup does not overwrite the record or create a second administrator.

Session cookies add `Secure` automatically when the CGI request reports HTTPS
through `HTTPS` or `X-Forwarded-Proto`. The public fnOS reverse proxy must retain
that scheme header. `FOSSILHUB_COOKIE_SECURE=always` is available for an
HTTPS-only deployment; `never` is restricted to isolated HTTP smoke testing.

| Platform route | Expected result |
| --- | --- |
| `/explore?q=sqlite&kind=code&sort=recent` | Complete SSR search result |
| `/catalog-fragment` | Progressive-search HTML fragment |
| `/repo/bedrock.fossil/timeline` | FossilHub timeline |
| `/repo/bedrock.fossil/files` | FossilHub trunk source tree |
| `/repo/bedrock.fossil/docs` | FossilHub documentation index |
| `/repo/bedrock.fossil/wiki` | FossilHub Wiki index |
| `/repo/bedrock.fossil/tickets` | FossilHub ticket cabinet |
| `/repo/bedrock.fossil/forum` | FossilHub forum activity |
| `/repo/<name>/files/new` | Writer file-commit workbench |
| `/repo/<name>/wiki/new` | Writer Wiki workbench |
| `/repo/<name>/tickets/new` | Triage Ticket workbench |
| `/repo/<name>/forum/new` | Triage Forum workbench |
| `/account/repositories` | Signed-in repository workspace |
| `/account/repositories/new` | Repository creation form |
| `/account/repositories/<slug>/settings` | Role-protected repository management |

Browser pages do not link to Fossil's built-in web UI. The `/fossil/<slug>`
endpoint remains enabled only for clone and sync of active public registry
entries. `/fossil/` does not list repositories, and private or unknown slugs
receive the same generic 404 before Fossil opens a repository file. Private
repository pages therefore do not render a clone command.

The image provides an idempotent `/usr/local/bin/fossilhub-init` command. It
initializes each missing repository in a uniquely named temporary file before
publishing it, applies mode 0600, and rebuilds the catalogue only after all ten
operations succeed. Run it only with the exact FossilHub data mount and the
same UID/GID as the service. The image supplies the required non-secret
`HOME=/data` and `USER=fossilhub` environment for direct initializer runs.
Initialization output is deliberately suppressed
because Fossil prints a generated local administrator password; the initializer
immediately removes that generated user's capabilities.

## Read-only checks

Run these commands through the documented fnOS SSH connection. They do not
contain or require embedding the SSH/sudo password in this repository.

```sh
sudo docker ps --filter name='^fossilhub$'
sudo docker inspect --format '{{.State.Status}} {{.State.Health.Status}} {{.Config.Image}}' fossilhub
curl --fail --silent --show-error http://127.0.0.1:6080/healthz
sudo docker logs --tail 100 fossilhub
```

Althttpd request logs are persisted as
`/vol1/1000/fossilhub/althttpd-YYYYMMDD.csv`.

The reference live repository is
`/vol1/1000/fossilhub/repositories/bedrock.fossil`. Clone it from a LAN client
with:

```sh
fossil clone http://192.168.1.162:6080/fossil/bedrock bedrock.fossil
```

The central `warden` administrator's one-time credential is stored in
`/vol1/1000/fossilhub/platform/fossilhub-bootstrap-admin.txt`. The file is mode
0600 and owned by UID/GID 10001:10001. Read it only in a trusted interactive SSH
terminal and change it immediately through `/account/security`. Never paste it
into logs, tickets, automation output, or this repository:

```sh
sudo cat /vol1/1000/fossilhub/platform/fossilhub-bootstrap-admin.txt
```

## Lifecycle

```sh
sudo docker stop fossilhub
sudo docker start fossilhub
sudo docker restart fossilhub
```

These commands affect only the dedicated FossilHub container. Do not substitute
fnOS application-center commands and do not change any existing production
container.

## Rollback

Five stopped rollback containers are intentionally retained:

- `fossilhub-rollback-0ac4dff-20260829` — immediate pre-Phase-5 production;
  data: `/vol1/1000/fossilhub-rollback-0ac4dff-data`
- `fossilhub-rollback-188b918` — the first validated 0.2.0-beta.1 image
- `fossilhub-rollback-8c9726d` — image `fossilhub:0.1.2`
- `fossilhub-rollback-94f8097` — image `fossilhub:0.1.1`
- `fossilhub-rollback-348f399` — image `fossilhub:0.1.0`

The preferred rollback target is `fossilhub-rollback-0ac4dff-20260829`.
Container and bind-mount rollback must happen together. Resolve the exact
targets first, confirm that the failed-data and failed-container names are
unused, and preserve both failed production artifacts for diagnosis:

```sh
sudo docker stop fossilhub
sudo docker rename fossilhub fossilhub-failed-578fcff
sudo mv /vol1/1000/fossilhub /vol1/1000/fossilhub-failed-578fcff-data
sudo mv /vol1/1000/fossilhub-rollback-0ac4dff-data /vol1/1000/fossilhub
sudo docker rename fossilhub-rollback-0ac4dff-20260829 fossilhub
sudo docker start fossilhub
curl --fail --silent --show-error http://127.0.0.1:6080/healthz
```

Before running this sequence, confirm that the rollback container still exists
and that neither proposed failed target already exists. Reversing a rollback
follows the same stop, rename, and exact data-directory exchange.

## Post-deployment cleanup

On 2026-08-27, the six stopped `fossilhub-beta-*` smoke, persistence, and
responsive-hotfix containers were removed after production verification. The
production container and all four `fossilhub-rollback-*` containers were
preserved. No image, production data, rollback data, NAS build directory, or
temporary smoke-test data directory was removed as part of that cleanup.

On 2026-08-29, the Phase 5 deployment retained the prior production container
and data, the final smoke container and data, and the production initializer,
database-check, and integrity-check containers. No NAS container, image, data
directory, or rollback artifact was deleted. Local HTTP clone artifacts were
moved to the desktop Trash and remain recoverable.

## Upgrade procedure

1. Commit the complete release in this repository and record the revision.
2. Re-check that host port 6080 is owned only by the current FossilHub container.
3. Transfer a `git archive` of that revision to a new `/tmp/fossilhub-build-*`
   directory on the NAS; do not build from a dirty working tree.
4. Build a uniquely versioned image from `Dockerfile` on the x86_64 NAS.
5. Populate an isolated data directory with `fossilhub-init`, then smoke-test
   all first-party routes in a temporary container on a different unused port.
6. Stop and rename the current container as a rollback point, then create the
   replacement with the same restrictions and persistent volume.
7. Verify health, UTF-8 content, routes, logs, desktop/mobile layout, and restart
   behaviour before considering the deployment complete.

The runtime entrypoint forwards `SIGTERM` to Althttpd and waits for it. A normal
`docker stop` should complete before its timeout and report exit code 143; exit
137 indicates a forced stop and must be investigated before production use.

## fnOS boundaries

No fnOS system file, systemd unit, PostgreSQL schema, or application-center
state was changed for this deployment. The protected containers listed in
`docs/nas-audit.md` remain out of scope and must not be modified by FossilHub
operations.
