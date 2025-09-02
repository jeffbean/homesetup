# DevPod Seed

This document seeds a plan to build a personal “DevPod” — an on‑demand, reproducible development environment you can spin up quickly on a laptop or in the cloud. The design borrows ideas from Uber’s DevPod: ephemeral workspaces, pre‑baked images, fast startup, and a consistent developer experience.

## Goals
- Fast start: <1–2 min from command to ready shell/IDE.
- Reproducible: same toolchain across machines and sessions.
- Disposable: destroy/recreate safely; no pet servers.
- Secure: no secrets in images; inject at runtime.

## Core Concepts
- Pre‑baked image: base OS + common tools (git, zsh, tmux, Go, Node, mise).
- Runtime provisioning: mount code; stow dotfiles; apply minimal runtime glue.
- Ephemeral storage: workspace volume is disposable; caches layered (image + optional persistent cache volume).
- Remote access: connect with SSH or VS Code Remote / JetBrains Gateway.

## Architecture (MVP)
- Orchestrator: local Docker/Colima initially; optional k3d/kind; later cloud K8s.
- Image: `devpod-base:latest` (build in CI). Contains shells/tools but no secrets.
- Bootstrap: entrypoint that runs `make apply` to stow dotfiles inside the pod.
- Volumes:
  - Workspace: bind‑mount repo into `/work`.
  - Optional persistent cache: `/cache` for Go/npm caches.
- Access: `docker exec -it devpod zsh` or `code --remote ssh-remote devpod`.

## Developer Workflow
- Start: `devpod up` → container from `devpod-base` with mounts.
- Attach: `devpod shell` → `zsh` with OMZ theme and tmux.
- Stop: `devpod down` → remove container/volumes (except cache if configured).

## Implementation Plan (Incremental)
1) Image
- Add `Dockerfile.devpod` (Ubuntu/Alpine + zsh + tmux + git + Go + mise).
- CI: build and push `devpod-base:latest` (GHCR or local).

2) CLI wrapper (reuse Go CLI)
- Add `homesetup devpod up|shell|down` that shells out to Docker:
  - `up`: run container `--name devpod -v $PWD:/work -w /work` and call `make apply` inside.
  - `shell`: `docker exec -it devpod zsh`.
  - `down`: `docker rm -f devpod`.

3) Dotfiles integration
- Inside container, run `make apply` to stow `dotfiles/*` to the pod’s `$HOME`.

4) Secrets
- No secrets in images. At runtime, mount a host path or inject with 1Password CLI.

## Future Enhancements
- K8s operator (k3d/cloud): devpod per branch/PR via labels.
- IDE gateways: VS Code devcontainers, JetBrains Gateway.
- Pre‑warm caches: Go module proxy layer, npm cache volume.
- Resource policy: CPU/mem quotas; idle shutdown.

## Open Questions
- Where to host images (GHCR vs. local registry)?
- Which caches warrant persistence vs. full ephemerality?
- Do we need multiple “profiles” (langs/stacks) or a single universal image?
