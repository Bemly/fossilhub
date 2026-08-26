# fnOS deployment audit

Audit date: 2026-08-26

This audit was read-only. No existing container or fnOS system file was changed.

## Host

- Host: `MEminiFnOS`
- Architecture: `x86_64`
- Host OS base: Debian 12
- Docker Engine: 28.5.2
- `/vol1`: 474 GB total, 400 GB available at audit time

## Deployment allocation

- Container: `fossilhub`
- Host port: `6080` (confirmed unused at audit time)
- Container port: `8080`
- Persistent host path: `/vol1/1000/fossilhub` (confirmed absent at audit time)

## Protected containers observed

The following existing containers were inspected only through `docker ps -a` and
must not be modified by this project:

- `llonebot`
- `napcat-docker`
- `astrbot`
- `chromium`
- `Ayu`
- `db2`
- `redis`

## Safety notes

- Re-check port `6080` immediately before deployment.
- Create only the dedicated `fossilhub` container and storage path.
- Do not use host networking.
- Do not mount the Docker socket or any fnOS system path.
- Never use or invoke fnOS application-center internals for this container.

