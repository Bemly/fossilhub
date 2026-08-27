# FossilHub production operations

Deployment verified: 2026-08-27

## Current production

- Site: `http://192.168.1.162:6080/`
- Health: `http://192.168.1.162:6080/healthz`
- Container: `fossilhub`
- Image: `fossilhub:0.2.0-beta.1`
- Source revision label: `0ac4dff`
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
| `/repo/dig.fossil` | Repository specimen and timeline |
| `/fh.css` | Shared stylesheet |
| `/healthz` | HTTP 200 with `ok` |
| `/fossil/` | Native Fossil repository list |
| `/fossil/dig/timeline` | Native Fossil Timeline |
| `/fossil/dig/tree` | Versioned source tree |
| `/fossil/dig/wiki` | Native Fossil Wiki |
| `/fossil/dig/reportlist` | Native Fossil Tickets |
| `/fossil/dig/forum` | Native Fossil Forum |

Legacy prototype paths `/explore.html` and `/repo.html` remain valid.

## CalVer candidate

The source candidate is `2026.08.27-beta.2`; it is not the production image
until the validation and transactional switch below are complete. Its public
catalogue is an application-owned SQLite database at
`/data/catalog/fossilhub.sqlite`, rebuilt atomically from ten clean local
repositories: Bedrock, Ammonite, Trilobite, Basalt, Cambrian, Granite, Shale,
Quartz, Obsidian, and Tectonic. They begin with no check-ins, Wiki pages,
Tickets, Forum posts, files, or imported upstream history beyond Fossil's
required initial empty check-in.

The candidate does not create `dig.fossil`. If that legacy repository and its
bootstrap record already exist, they are preserved but omitted from the public
catalogue.

| Candidate route | Expected result |
| --- | --- |
| `/explore?q=sqlite&kind=code&sort=recent` | Complete SSR search result |
| `/catalog-fragment` | Progressive-search HTML fragment |
| `/repo/bedrock.fossil/timeline` | FossilHub timeline |
| `/repo/bedrock.fossil/files` | FossilHub trunk source tree |
| `/repo/bedrock.fossil/docs` | FossilHub documentation index |
| `/repo/bedrock.fossil/wiki` | FossilHub Wiki index |
| `/repo/bedrock.fossil/tickets` | FossilHub ticket cabinet |
| `/repo/bedrock.fossil/forum` | FossilHub forum activity |

Browser pages do not link to Fossil's built-in web UI. The `/fossil/<slug>`
endpoint remains enabled only because Fossil clients require it for clone and
sync.

The image provides an idempotent `/usr/local/bin/fossilhub-init` command. It
initializes each missing repository in a uniquely named temporary file before
publishing it, applies mode 0600, and rebuilds the catalogue only after all ten
operations succeed. Run it only with the exact FossilHub data mount and the
same UID/GID as the service. Initialization output is deliberately suppressed
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

The live repository is `/vol1/1000/fossilhub/repositories/dig.fossil`.
Clone it from a LAN client with:

```sh
fossil clone http://192.168.1.162:6080/fossil/dig dig.fossil
```

The one-time administrator name and password generated during repository
bootstrap are stored in
`/vol1/1000/fossilhub/fossil-bootstrap-admin.txt`. The file and repository are
mode 0600 and owned by UID/GID 10001:10001. Read the record only in a trusted
SSH terminal and never paste it into logs, tickets, or this repository:

```sh
sudo cat /vol1/1000/fossilhub/fossil-bootstrap-admin.txt
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

Four stopped rollback containers are intentionally retained:

- `fossilhub-rollback-188b918` — the first validated 0.2.0-beta.1 image
- `fossilhub-rollback-8c9726d` — image `fossilhub:0.1.2`
- `fossilhub-rollback-94f8097` — image `fossilhub:0.1.1`
- `fossilhub-rollback-348f399` — image `fossilhub:0.1.0`

The preferred rollback target is revision `188b918`; its existing container
retains the original image ID even though the mutable beta tag now names the
newer `0ac4dff` image. Preserve the failed container for diagnosis:

```sh
sudo docker stop fossilhub
sudo docker rename fossilhub fossilhub-failed-0ac4dff
sudo docker rename fossilhub-rollback-188b918 fossilhub
sudo docker start fossilhub
curl --fail --silent --show-error http://127.0.0.1:6080/healthz
```

Before running this sequence, confirm that the rollback container still exists
and that no container already has the proposed `fossilhub-failed-0ac4dff` name.
Reversing a rollback follows the same stop-and-rename pattern.

## Post-deployment cleanup

On 2026-08-27, the six stopped `fossilhub-beta-*` smoke, persistence, and
responsive-hotfix containers were removed after production verification. The
production container and all four `fossilhub-rollback-*` containers were
preserved. No image, production data, rollback data, NAS build directory, or
temporary smoke-test data directory was removed as part of that cleanup.

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

## fnOS boundaries

No fnOS system file, systemd unit, PostgreSQL schema, or application-center
state was changed for this deployment. The protected containers listed in
`docs/nas-audit.md` remain out of scope and must not be modified by FossilHub
operations.
