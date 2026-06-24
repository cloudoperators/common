# GHA Streamlining Status (cloudoperators/common#2086)

**Tracking issue:** [cloudoperators/greenhouse#2086](https://github.com/cloudoperators/greenhouse/issues/2086)
**Last updated:** 2026-06-24 (Copilot + abhijith-darshan review round 4)

---

## PRs — merge order matters

> **common#65 must merge first.** All consumer PRs depend on it resolving `@main`.

| # | Repo | PR | Status | Notes |
|---|---|---|---|---|
| 1 | `cloudoperators/common` | [#65](https://github.com/cloudoperators/common/pull/65) | Open — awaiting Copilot review round 5 | Adds 5 new shared reusable workflows. **Merge this first.** |
| 2 | `cloudoperators/repo-guard` | [#167](https://github.com/cloudoperators/repo-guard/pull/167) | Open — clean pass | Depends on common#65 |
| 3 | `cloudoperators/cloudctl` | [#57](https://github.com/cloudoperators/cloudctl/pull/57) | Open — clean pass | Depends on common#65 |
| 4 | `cloudoperators/shoot-grafter` | [#66](https://github.com/cloudoperators/shoot-grafter/pull/66) | Open — clean pass | Depends on common#65 |
| 5 | `cloudoperators/permission-manager` | [#39](https://github.com/cloudoperators/permission-manager/pull/39) | Open — clean pass | Depends on common#65 |

---

## What each PR does

### common#65 — new shared workflows

Five new files in `.github/workflows/`:

| File | Purpose |
|---|---|
| `shared-go-lint.yaml` | golangci-lint + optional govulncheck via `enable-govulncheck: true`. Go version always read from `go.mod`. |
| `shared-go-test.yaml` | Parameterized `make` test target; optional coverage artifact upload. Go version always read from `go.mod`. |
| `shared-go-build.yaml` | Go binary build + optional Docker multi-arch build/push to GHCR. Go version always read from `go.mod`. |
| `shared-release.yaml` (renamed to "Shared Release Bump") | Semver bump → Chart.yaml (version + optional appVersion) + Makefile update → release PR → GitHub release via `actions/github-script@v7` → optional `repository_dispatch` to greenhouse-extensions via GitHub App token |
| `shared-e2e.yaml` | Wraps existing `workflows/e2e` composite action for KinD-based e2e |

**Key design choices:**
- `go-version` input removed from all three Go workflows — always reads from `go.mod`
- `dispatch-token` secret replaced by `dispatch-app-id` + `dispatch-app-private-key` (GitHub App token via `actions/create-github-app-token@v3`)
- Chart.yaml update split into two steps: `version` always bumped when `chart-path` set; `appVersion` controlled by `bump-chart-app-version` input (default `true`)
- GitHub release created via `actions/github-script@v7` (not `gh` CLI)
- `peter-evans/repository-dispatch@v4` for greenhouse-extensions dispatch

**Latest commits on `feat/shared-go-workflows`:**
- `42b719b` — guards for makefile-path and dispatch inputs
- `bf067fd` — git add quoting, permissions on lint job
- `74c09c7` — drop go-version input from lint/build/build
- `845b28e` — abhijith-darshan review round

### repo-guard#167

- `ci.yaml`: `lint` + `test` jobs delegate to `shared-go-lint` and `shared-go-test` respectively.
  The `e2e` job stays **inline** (k3d + mock-GitHub, not compatible with greenhouse KinD composite).
- `release-cut.yaml`: all inline semver/PR/release logic replaced by `shared-release.yaml`.
  Includes `dispatch-greenhouse-extensions: true`; passes `CLOUDOPERATOR_APP_ID` and `CLOUDOPERATOR_APP_PRIVATE_KEY` as App secrets for the dispatch step.

### cloudctl#57

- `test.yaml`: `unit` job delegates to `shared-go-test.yaml` (`test-target: test`).
  The `e2e` job stays **inline** (k3d setup, not compatible with greenhouse KinD composite).

### shoot-grafter#66

- `ci.yaml`: `build` → `shared-go-build` (`build-target: build-all`); `test` → `shared-go-test` (`test-target: test-with-envtest`, coverage upload). `code_coverage` job stays inline.
- `checks.yaml`: new `lint` job calls `shared-go-lint` with `enable-govulncheck: true`.
  The `checks` job retains shellcheck, typos, addlicense, reuse, dependency-licenses inline.

### permission-manager#39

- New `ci.yaml` added (repo had no CI before). Calls `shared-go-lint`, `shared-go-test`, and `shared-go-build` (no `working-directory` override — Go module is at repo root).
- Existing `release.yaml` (multi-arch Docker + cosign + SBOM) is **unchanged**.

---

## Local branches

| Repo | Branch | Local path |
|---|---|---|
| `common` | `feat/shared-go-workflows` | `/Users/I313226/CODE/common` |
| `repo-guard` | `feat/shared-workflows` | `/Users/I313226/CODE/repo-guard` |
| `cloudctl` | `feat/shared-workflows` | `/Users/I313226/CODE/cloudctl` |
| `shoot-grafter` | `feat/shared-workflows` | `/Users/I313226/CODE/shoot-grafter` |
| `permission-manager` | `feat/shared-workflows` | `/Users/I313226/CODE/permission-manager` |

---

## Known gaps / follow-ups

| Item | Detail |
|---|---|
| **e2e standardization** | `repo-guard` and `cloudctl` e2e jobs use k3d with repo-specific mock setups. To use `shared-e2e.yaml`, those repos would need to migrate to KinD and the greenhouse composite action. |
| **shoot-grafter release** | No `charts/` dir or `VERSION` in Makefile. Release process needs to be defined before `shared-release.yaml` can be wired up. |
| **permission-manager release-cut** | Same as above — no charts, no `VERSION`. Existing `release.yaml` handles image publishing; version bump workflow TBD. |
| **shoot-grafter remaining checks** | `shellcheck`, `typos`, `check-addlicense`, `reuse`, `check-dependency-licenses` remain inline. Could be extracted into a shared `shared-go-checks.yaml` if other repos need the same. |
| **greenhouse-extensions** | Helm-based CI/release left unchanged (different paradigm). `repository_dispatch` receiver for `plugin-release` events should be verified/added. |

---

## Workflow call graph (after common#65 merges)

```
repo-guard/ci.yaml
  ├── lint     → common/shared-go-lint.yaml@main
  ├── test     → common/shared-go-test.yaml@main
  └── e2e      → inline (k3d)

repo-guard/release-cut.yaml
  └── cut-release → common/shared-release.yaml@main
                      └── dispatches → greenhouse-extensions (plugin-release)

cloudctl/test.yaml
  ├── unit     → common/shared-go-test.yaml@main
  └── e2e      → inline (k3d)

shoot-grafter/ci.yaml
  ├── build    → common/shared-go-build.yaml@main
  ├── test     → common/shared-go-test.yaml@main
  └── code_coverage → inline

shoot-grafter/checks.yaml
  ├── lint     → common/shared-go-lint.yaml@main
  └── checks   → inline (shellcheck, typos, addlicense, reuse, dep-licenses)

permission-manager/ci.yaml
  ├── lint     → common/shared-go-lint.yaml@main
  ├── test     → common/shared-go-test.yaml@main
  └── build    → common/shared-go-build.yaml@main
```
