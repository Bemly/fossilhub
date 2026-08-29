# FossilHub

FossilHub is a Tcl/Wapp port of the three-page UI prototype in
`/Users/bemly/cchaha/fossiltest`.

Production runs in an isolated Ubuntu 24.04 Docker container on fnOS. Althttpd
terminates HTTP and launches the Wapp application as CGI. Release
`2026.08.29-beta.1` uses an application-owned SQLite catalogue for search and
filters, then queries each repository through `fossil sql --readonly` for Tcl
server-rendered Timeline, Files, Docs, Wiki, Tickets, and Forum surfaces. The
browser receives complete HTML; JavaScript progressively enhances catalogue
search, theme, motion, and public mount-prefix adaptation.

The catalogue contains ten clean local Fossil repositories with no imported or
demonstration history. Fossil's CGI endpoint remains available for clone and
sync transport on active public registry entries, but browser navigation stays
inside FossilHub's visual system. The transport gate has no repository-list
response and returns the same generic 404 for private and unknown names.
The previous generated `dig.fossil` is no longer created or indexed.

Production is available on the NAS at `http://192.168.1.162:6080/`; its health
endpoint is `/healthz`, the reference repository page is
`/repo/bedrock.fossil`, and its clone/sync endpoint is `/fossil/bedrock`.
生产环境运行 `fossilhub:2026.08.29-beta.1`，运行时代码修订为 `3b88c20`。
该版本在 2026-08-29 完成 NAS 构建、完整测试、事务式切换、真实生产数据、
clone/sync、权限、70 条 HTTP 路由和响应式浏览器验收。

Repository routes begin at `/explore` and `/repo/bedrock.fossil`. The deployed
image is `fossilhub:2026.08.29-beta.1` at runtime revision `3b88c20`;
[VERSION](VERSION) is the release source of truth. The production acceptance
record is [docs/validation-2026.08.29-beta.1.md](docs/validation-2026.08.29-beta.1.md).

Phase 5 development adds a separate versioned platform database at
`/data/platform/fossilhub.sqlite` for central identities, authorization,
sessions, audit events, settings, and the dynamic repository registry. The ten
candidate repositories are imported into that registry idempotently; Fossil
repository files remain untouched and continue to be the artifact source of
truth. See [docs/platform-roadmap.md](docs/platform-roadmap.md) for the ordered
implementation and acceptance checklist.

The first Phase 5 identity slice now provides `/register`, `/login`, `/logout`,
and `/account/security`. Passwords are hashed with Argon2id; browser sessions
are opaque, server-side, expiring, rotated after password changes, and protected
by one-time CSRF form challenges. A clean data directory receives a one-time
`warden` administrator whose initial credential is written only to the
protected platform bootstrap record and must be changed after first sign-in.

The repository-lifecycle slice adds `/account/repositories` and a complete
server-rendered workflow for creating public or private repositories, changing
metadata, assigning Reader/Triage/Writer/Maintainer collaborators, transferring
ownership, and recoverably archiving or restoring repositories. Private
repository routes are resolved through the central registry and fail closed
before Fossil reads the repository file. Created repository files are published
atomically with mode 0600 and failed catalogue publications move to quarantine.

The browser-write slice adds authenticated, role-checked workbenches directly
under `/repo/<name>/`: Writer-or-higher users can create, edit, rename, and
delete files on a selected branch and create or revise Wiki pages; Triage-or-
higher users can create and update Tickets, comment, close/reopen, and publish
Forum discussions and replies. Every form uses a one-time CSRF challenge and
optimistic revision marker. Mutations are serialized per repository, attributed
to the central username through a separate randomized Fossil-only credential,
bounded by request and repository quotas, audited without submitted content,
and followed by an atomic catalogue rebuild. A post-mutation indexing failure
fails closed by quarantining the registry entry for administrator recovery.

The complete first-party reading slice adds cursor-paginated Timeline search,
check-in relationships and unified diffs, branch/tag indexes, versioned source
trees, raw downloads, file history and blame, ZIP snapshots, repository
statistics, version-selectable rendered Docs, safe Markdown/Fossil-Wiki,
Wiki comparisons, Ticket history, and threaded Forum views. Browser pages use
only FossilHub routes; the guarded Fossil CGI remains clone/sync transport only.

The user-workspace slice adds `/dashboard`, `/users/<username>`, `/settings`,
and `/repositories/new`. Signed-in users can review owned and collaborative
repositories, open Tickets, and recent activity; publish an escaped public
profile; update private contact details; change passwords; revoke sessions;
choose a browser-local theme; and deactivate their account after password
confirmation. The last active administrator cannot self-deactivate, and
deactivation closes every session without deleting repository custody records.

The administrator-workspace slice adds `/admin` with searchable user and
repository ledgers, controlled role/status/session actions, recoverable archive
and restore, Fossil integrity checks with fail-closed quarantine, catalogue
reindexing, a redacted audit CSV, safe application health, and non-secret
platform policy. Administrator writes require authentication from the last ten
minutes plus a route-scoped one-time CSRF challenge. Registration, repository
defaults, per-user counts, per-repository quotas, and the maintenance banner are
enforced from the application-owned settings table.

The public-information slice replaces the prototype footer placeholders with
first-party `/manual`, `/hosting`, `/upstream`, `/releases`, `/rules`, `/status`,
`/privacy`, `/security`, and `/contact` routes. Release notes come from the
maintained source document, the public status board exposes only aggregated
health, and an escaped maintenance notice can be published from administrator
settings. Versioned CSS and JavaScript URLs keep direct and externally mounted
pages from reusing stale assets after an update.

- [PLAN.md](PLAN.md) records implementation and acceptance status.
- [docs/operations.md](docs/operations.md) contains deployment, diagnostics,
  and rollback procedures.
- [docs/validation-2026.08.28-beta.1.md](docs/validation-2026.08.28-beta.1.md)
  records the Phase 5 isolated and production acceptance evidence.
- [docs/validation-2026.08.29-beta.1.md](docs/validation-2026.08.29-beta.1.md)
  记录正式 Logo 维护版本的生产部署与验收证据。
- [docs/third-party.md](docs/third-party.md) records the pinned Tcl, Wapp,
  Althttpd, and Fossil sources.
