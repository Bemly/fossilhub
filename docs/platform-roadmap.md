# FossilHub platform implementation roadmap

Status: approved implementation scope, not yet production

This roadmap upgrades FossilHub from a read-only Fossil presentation layer into
a self-hosted collaboration platform with central accounts, repository
ownership, browser writes, user and administrator workspaces, and complete
first-party repository navigation. It covers the gaps previously numbered 3
through 8. Production port 6080 remains unchanged until every release gate is
complete and the operator explicitly authorizes the switch.

## Product boundary

FossilHub will provide the foundational workflow expected from a GitHub-like
service while preserving Fossil as the repository of record:

- central registration, login, profiles, sessions, password changes, and
  account status;
- public and private repositories, ownership, collaborators, and role-based
  authorization;
- browser workflows for repository creation and settings, source commits,
  Wiki, Tickets, and Forum;
- first-party timelines, check-ins, diffs, branches, tags, source trees, file
  history, Wiki history, Ticket detail/history, Forum threads, archives, and
  repository statistics;
- user and administrator workspaces with audit history and operational health;
- real public documentation, policy, status, release, contact, and hosting
  pages in place of placeholder links.

This milestone does not attempt to clone every GitHub product. Pull requests,
Actions-compatible CI, package hosting, billing, organizations, OAuth apps,
email delivery, and federation require separate product phases after this
foundation is proven.

## Invariants

- Fossil repository files remain owned by Fossil. Reads use
  `fossil sql --readonly`; mutations use supported Fossil commands or HTTP
  sync, never raw writes to Fossil-owned tables.
- Central identities, authorization, sessions, audit events, repository
  registry, and catalogue data live in application-owned SQLite databases.
- Repository publication is registry-based and fail-closed. A file is never
  exposed merely because it has a `.fossil` suffix.
- Passwords use Argon2id with per-password salts. Session, reset, and API token
  values are random and only their hashes are stored.
- Every state-changing browser request requires authentication, authorization,
  CSRF validation, an allowed HTTP method, input and size limits, and an audit
  event. Sensitive account and destructive operations require recent
  re-authentication.
- Deletes are recoverable: repositories are archived first and moved to an
  exact quarantine path. Permanent removal is an explicit administrator-only
  operation outside the normal UI.
- Repository mutations are serialized per repository, use exact temporary
  directories, and rebuild the catalogue only after Fossil reports success.
- The container remains non-root with a read-only root filesystem, no added
  capabilities, no Docker socket, no host networking, and writes limited to
  `/data` plus the bounded `/tmp` tmpfs.
- Complete pages remain server-rendered. JavaScript may improve interactions
  but is never the sole path to content or an essential state change.
- Public subdirectory routing remains runtime-derived in the browser. No
  external mount prefix is hardcoded in server templates.
- Existing `dig.fossil`, bootstrap records, candidate repositories, production
  data, and rollback containers are preserved throughout migration.

## Permission model

Roles are evaluated for every repository operation; the global administrator
role can inspect and suspend resources but does not silently impersonate an
artifact author.

| Capability | Visitor | Reader | Triage | Writer | Maintainer | Owner | Administrator |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Read a public repository | yes | yes | yes | yes | yes | yes | yes |
| Read a private repository | no | yes | yes | yes | yes | yes | yes |
| Open/comment on Tickets and Forum | no | no | yes | yes | yes | yes | yes |
| Create Wiki revisions | no | no | no | yes | yes | yes | yes |
| Commit browser file changes | no | no | no | yes | yes | yes | yes |
| Manage collaborators and metadata | no | no | no | no | yes | yes | yes |
| Archive or transfer repository | no | no | no | no | no | yes | yes |
| Manage platform users and policy | no | no | no | no | no | no | yes |

The built-in anonymous and bootstrap identities are never accepted as central
interactive accounts.

## Delivery order and progress

### Phase A — platform database and migrations

- [x] Add a versioned, transactional application schema for users, credentials,
  sessions, login attempts, repositories, collaborators, audit events, and
  platform settings.
- [x] Add deterministic migrations and backup/restore checks; migrations must
  be repeatable and must not touch Fossil-owned schemas.
- [x] Import the ten manifest repositories into the registry without changing
  their repository files or project codes. Keep legacy `dig.fossil` retained
  but unpublished.
- [x] Make the catalogue rebuild from enabled registry records instead of a
  compile-time-only manifest, while retaining a seed manifest for clean installs.
- [x] Add database integrity, permission, ownership, migration, and hostile-data
  tests.

Acceptance: a clean data directory and a migrated beta.3 data directory produce
the same ten public repository identities; a failed migration leaves the prior
database usable.

### Phase B — identity, sessions, and authorization

- [x] Add Argon2id password hashing and verification without logging passwords.
- [x] Add registration, login, logout, current-user loading, password change,
  session listing/revocation, and administrator identity support.
- [ ] Add administrator controls for disabling, restoring, and deactivating
  accounts; their session rejection is already enforced by the identity model.
- [x] Add opaque server-side sessions with rotation, idle and absolute expiry,
  `HttpOnly` and `SameSite` cookies, secure-cookie enforcement behind HTTPS,
  and no browser storage of credentials.
- [x] Add per-session CSRF tokens, recent re-authentication for sensitive
  actions, generic login failures, and bounded login throttling.
- [ ] Add centralized request guards for anonymous, authenticated, repository
  role, and administrator access.
- [x] Add a one-time bootstrap administrator workflow whose generated
  credential is suppressed from non-interactive output and stored only in a
  mode-0600 record owned by UID/GID 10001:10001.
- [ ] Add security headers, session fixation, CSRF, authorization, timing-safe
  comparison, expiry, and account-state tests.

Acceptance: no protected page or mutation is reachable anonymously or with a
lower repository role; password and token material never appears in databases,
logs, generated HTML, test output, or Git.

### Phase C — repository lifecycle and access control

- [x] Replace the fixed public-only routing check with a dynamic registry lookup
  that enforces visibility and membership before touching a repository file.
- [x] Add repository creation with validated slugs, atomic Fossil initialization,
  owner membership, default branch metadata, catalogue publication, and audit.
- [x] Add repository settings for name, description, visibility, default branch,
  and archive state.
- [x] Add collaborator invitation/removal and Reader, Triage, Writer, and
  Maintainer role changes.
- [x] Add owner transfer with re-authentication and an explicit confirmation.
- [x] Add recoverable archive/quarantine; do not implement routine permanent
  deletion in this milestone.
- [x] Reconcile central users with Fossil artifact authors without exposing or
  reusing central passwords as Fossil credentials.
- [x] Add concurrent-create, path traversal, case collision, permission downgrade,
  private-route, archive, and recovery tests.

Acceptance: two ordinary users can own separate public/private repositories,
collaborate according to the matrix, and cannot discover or mutate each other's
private resources without a grant.

### Phase D — safe browser write service

- [x] Add a per-repository mutation lock and exact temporary checkout service.
- [x] Add create/edit/delete/rename source-file workflows with branch selection,
  commit message, author attribution, size limits, conflict detection, and
  guaranteed temporary cleanup.
- [x] Add Wiki create/edit with revision-aware conflict detection.
- [x] Add Ticket creation, field updates, comments, and close/reopen; the
  first-party artifact history reader remains in Phase E.
- [x] Add Forum thread creation and replies using supported Fossil interfaces;
  the first-party threaded history reader remains in Phase E.
- [x] Rebuild repository metadata and the public catalogue after every successful
  mutation; leave both unchanged on failure.
- [x] Record actor, repository, action, target, outcome, request identifier, and
  timestamp in the application audit log without recording submitted content or
  secrets.
- [x] Add mutation size/quota limits and validation for filenames, branch names,
  artifact identifiers, Ticket fields, Wiki names, and Forum titles.
- [x] Add concurrent update, stale revision, rollback, malicious input, binary
  file, quota, and interrupted-operation tests.

Acceptance: Writer-or-higher users can complete all four collaboration workflows
from the browser, and an injected failure cannot leave a partial checkout,
unindexed successful mutation, or unauthorized Fossil artifact.

### Phase E — complete first-party repository reading

- [ ] Add searchable cursor pagination to the unified Timeline with event type,
  author, branch/tag, and time filters.
- [ ] Add check-in detail with parents, children, branches/tags, changed files,
  additions/deletions, and safely rendered unified diffs.
- [ ] Add branch and tag indexes plus per-branch history.
- [ ] Replace the flat trunk file list with a navigable directory tree at any
  check-in, breadcrumbs, raw/download responses, file history, and blame.
- [ ] Add repository archive download and first-party repository statistics.
- [ ] Keep the Docs index heuristic, then add a rendered document view and
  check-in selector.
- [ ] Add safe Fossil-Wiki/Markdown rendering with a strict HTML allow-list,
  Wiki revision history, and revision comparison.
- [ ] Add Ticket detail/history and Forum thread/body/reply views.
- [ ] Add empty, large-history, merge, rename, binary, Unicode, hostile markup,
  private repository, and pagination tests.

Acceptance: browser navigation has no dependency on Fossil's built-in HTML UI;
clone/sync remains the only public `/fossil/*` use.

### Phase F — user workspace

- [ ] Add a signed-in dashboard with owned repositories, collaborations, recent
  activity, assigned/open Tickets, and useful empty states.
- [ ] Add public profiles with display name, biography, links, join date, and
  public repository/activity summaries.
- [ ] Add account settings for profile, password, active sessions, theme, and
  account deactivation.
- [x] Add repository creation, collaboration, archive, and transfer flows to the
  user workspace.
- [ ] Add keyboard focus, screen-reader labels, responsive navigation, reduced
  motion, validation summaries, and no-JavaScript form paths.

Acceptance: an ordinary user can manage the full lifecycle of an account and
owned repository without administrator help.

### Phase G — administrator workspace

- [ ] Add an overview with user, repository, storage, activity, failure, and
  catalogue-health summaries.
- [ ] Add user search, detail, role change, disable/restore, and session
  revocation with re-authentication and audit.
- [ ] Add repository search, ownership/visibility inspection, archive/restore,
  reindex, and integrity-check actions.
- [ ] Add audit search/filter/export with secret and submitted-content redaction.
- [ ] Add application health for database integrity, repository readability,
  catalogue freshness, data ownership/modes, version, and storage thresholds.
- [ ] Add platform settings for registration policy, default visibility, limits,
  and maintenance banner; secrets are never editable or displayed in the UI.
- [ ] Add tests proving administrators cannot bypass re-authentication, CSRF,
  audit, quarantine, or Fossil ownership boundaries.

Acceptance: routine platform administration can be performed without SSH while
high-risk actions remain explicit, recoverable, and attributable.

### Phase H — public information and navigation

- [ ] Replace every placeholder footer link with a real first-party route:
  field manual, hosting, upstream projects, releases, rules, status, privacy,
  security, and contact.
- [ ] Generate the status page from safe application health summaries without
  exposing paths, credentials, private repository names, or logs.
- [ ] Add release notes sourced from a maintained application document.
- [ ] Ensure authenticated navigation exposes Dashboard, New repository,
  Profile, Settings, and Sign out; administrators additionally see Admin.
- [ ] Verify every link directly and below the simulated public subdirectory.

Acceptance: there are no `href="#"` or self-anchor placeholders presented as
working product navigation.

### Phase I — integration, NAS validation, and release

- [ ] Run formatting and syntax checks plus all existing and new tests under the
  image's Tcl 9.1 runtime.
- [ ] Build a committed x86_64 image on the NAS with the exact Git revision in
  the OCI label.
- [ ] Initialize isolated data and run a uniquely named smoke container on a
  confirmed-free temporary port; never reuse 6080 or an unrelated service port.
- [ ] Exercise registration, login, logout, password change, private access,
  collaboration roles, repository creation, file commit, Wiki, Ticket, Forum,
  archive/restore, user workspace, and administrator workspace end to end.
- [ ] Repeat clone/sync, restart, migration, ownership/mode, read-only root,
  security header, CSRF, session expiry, rate-limit, and catalogue consistency
  checks.
- [ ] Browser-test 1440 px, 913 px, and 390 x 844 in light/dark and reduced-motion
  modes, direct LAN paths, and the simulated public mount prefix.
- [ ] Record a validation document with no credentials, raw sensitive logs, or
  private content.
- [ ] Stop but retain the exact smoke container and data until cleanup is
  explicitly authorized.
- [ ] Perform the final production preflight and transactional port-6080 switch
  only after explicit authorization; retain the current production container as
  rollback.

Acceptance: the candidate passes the entire verification matrix twice—before
and after restart/migration—and production remains unchanged until separately
authorized.

## Interface direction

The accepted FossilHub prototype remains the visual source of truth. New
authenticated surfaces use the existing Big Shoulders Display, IBM Plex Sans,
and IBM Plex Mono type system, limestone/ink/azurite/verdigris/iron palette,
square borders, specimen labels, and stratigraphic spacing.

The signature element is a **stratigraphic permission section**: repository
membership and administrative scope are displayed as stacked geological layers,
so access depth is understandable at a glance. It encodes the real role
hierarchy and is used sparingly on collaborator and administrator pages. Dense
tables remain quiet, legible field ledgers rather than generic rounded dashboard
cards.

## Commit and review boundaries

Each checkbox group is delivered in independently reversible commits. Expected
boundaries are:

1. `docs:` platform scope and security model
2. `feat:` application database and migrations
3. `feat:` authentication and sessions
4. `feat:` repository registry and permissions
5. `feat:` browser repository writes
6. `feat:` complete repository read surfaces
7. `feat:` user workspace
8. `feat:` administrator workspace
9. `feat:` public information routes
10. `test:` platform security and end-to-end coverage
11. `docs:` NAS validation and operations

Before every commit: inspect explicit staged paths, run relevant tests, run
secret-pattern checks, and preserve all unrelated untracked visual experiments.
