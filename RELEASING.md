# Releasing

This document describes the standard release process for repositories in the `cloudoperators` org. All shared release workflows live in [`cloudoperators/common`](https://github.com/cloudoperators/common) and are designed to be called from any repo.

---

## Workflows

| Workflow | Purpose |
|---|---|
| [`shared-release.yaml`](#shared-releaseyaml) | Bump version, commit, create git tag, create GitHub Release |
| [`shared-helm-release.yaml`](#shared-helm-releaseyaml) | Package and push a Helm chart to GHCR OCI |
| [`shared-docker-release.yaml`](#shared-docker-releaseyaml) | Build and push a Docker image to GHCR |
| [`shared-goreleaser.yaml`](#shared-goreleaseryaml) | Build Go binaries and create a GitHub Release via GoReleaser |

A typical release flow chains these together:

```
shared-release (bumps version, creates tag)
    → shared-docker-release  (triggered by v* tag)
    → shared-helm-release    (triggered by v* or helm-chart-* tag)
    → shared-goreleaser      (triggered by v* tag)
```

---

## `shared-release.yaml`

The entry point for all releases. Bumps the version in `Makefile` and/or `Chart.yaml`, commits, creates a git tag, and creates a GitHub Release.

### Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `bump` | ✅ | — | Version bump type: `patch`, `minor`, or `major` |
| `chart-path` | | `""` | Relative path to `Chart.yaml` (e.g. `charts/myapp/Chart.yaml`). Leave empty to skip. |
| `makefile-path` | | `""` | Relative path to `Makefile` containing a `VERSION` variable. Leave empty to skip. At least one of `chart-path` or `makefile-path` is required. |
| `bump-chart-app-version` | | `true` | Update `appVersion` in `Chart.yaml` to the new version. Set to `false` for chart-only releases (or use `chart-only`). |
| `bump-make-version` | | `false` | Also update the `IMG` tag line in `Makefile` to the new version. |
| `chart-only` | | `false` | When `true`: skip `appVersion`, tag as `helm-chart-vX.Y.Z` instead of `vX.Y.Z`, skip GitHub Release. Use for Helm chart changes that don't involve a new app binary. |
| `dispatch-greenhouse-extensions` | | `false` | Trigger a `repository_dispatch` event on `cloudoperators/greenhouse-extensions` after release. |
| `plugin-name` | | `""` | Plugin name passed as payload when dispatching to `greenhouse-extensions`. Required when `dispatch-greenhouse-extensions: true`. |
| `environment` | | `""` | GitHub environment name to activate (e.g. `release`), for protection rules and scoped secrets. |
| `runs-on` | | `ubuntu-latest` | Runner label. Must be a Linux runner (workflow uses GNU sed). |

### Secrets

| Secret | Required | Description |
|---|---|---|
| `release-token` | ✅ | PAT or GitHub App token with `contents: write` permission |
| `dispatch-app-id` | | GitHub App ID for dispatching to `greenhouse-extensions` |
| `dispatch-app-private-key` | | GitHub App private key for dispatching to `greenhouse-extensions` |

> **Important:** Tags pushed with the built-in `GITHUB_TOKEN` do **not** trigger downstream `push`-triggered workflows (this is a GitHub security restriction). If you want the tag created by `shared-release` to automatically kick off `shared-docker-release`, `shared-goreleaser`, or `shared-helm-release`, you must pass a **PAT** or **GitHub App token** as `release-token`. Repos that use only `GITHUB_TOKEN` will need to trigger those downstream workflows manually after the release tag is created.

### Example: App release (bumps version + appVersion)

```yaml
name: Cut Release

on:
  workflow_dispatch:
    inputs:
      bump:
        description: "Version bump type"
        required: true
        type: choice
        options: [patch, minor, major]

jobs:
  release:
    uses: cloudoperators/common/.github/workflows/shared-release.yaml@main
    permissions:
      contents: write
    with:
      bump: ${{ inputs.bump }}
      makefile-path: Makefile
      chart-path: charts/myapp/Chart.yaml
    secrets:
      release-token: ${{ secrets.RELEASE_TOKEN }}
```

### Example: Chart-only release (bumps chart version, not appVersion)

```yaml
name: Cut Chart Release

on:
  workflow_dispatch:
    inputs:
      bump:
        description: "Version bump type"
        required: true
        type: choice
        options: [patch, minor, major]

jobs:
  release:
    uses: cloudoperators/common/.github/workflows/shared-release.yaml@main
    permissions:
      contents: write
    with:
      bump: ${{ inputs.bump }}
      chart-path: charts/myapp/Chart.yaml
      chart-only: true
    secrets:
      release-token: ${{ secrets.RELEASE_TOKEN }}
```

This creates a `helm-chart-vX.Y.Z` tag, which can then trigger `shared-helm-release.yaml`.

### Version source

The workflow reads the current version from `makefile-path` first (looks for `VERSION ?= x.y.z`), then falls back to `chart-path` (`version: x.y.z`). At least one must be provided.

> **Note for Makefile repos:** the `VERSION` variable must be a static value, not a shell expression. Replace `VERSION ?= $(shell git describe ...)` with `VERSION ?= 1.2.3` — the workflow will own version bumping from that point.

---

## `shared-helm-release.yaml`

Packages a Helm chart and pushes it to GHCR OCI. Includes a duplicate-version guard.

### Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `chart-dir` | ✅ | — | Path to the chart directory containing `Chart.yaml` (e.g. `charts/myapp`) |
| `chart-name` | ✅ | — | Chart name for the OCI duplicate-version check. Must match the `name:` field in `Chart.yaml`. |
| `registry` | | `ghcr.io` | Container registry hostname |
| `helm-version` | | `v3.17.0` | Helm CLI version |
| `run-dependency-update` | | `false` | Run `helm dependency update` before packaging. Set to `true` if the chart has local `file://` dependencies. |
| `allow-existing` | | `false` | When `true`: exit 0 instead of failing if the chart version already exists in the registry. Useful when multiple charts are released in batch and not all have changed. |
| `environment` | | `""` | GitHub environment name |
| `runs-on` | | `ubuntu-latest` | Runner label (must be Linux) |

### Secrets

| Secret | Required | Description |
|---|---|---|
| `registry-token` | | Registry token; falls back to `GITHUB_TOKEN` |

### OCI path

Charts are pushed to `oci://ghcr.io/{repo}/charts/` (repo-scoped). For example, a chart in `cloudoperators/myrepo` is pushed to `ghcr.io/cloudoperators/myrepo/charts/{chart-name}`.

### Example: Single chart, tag-triggered

```yaml
name: Helm Chart Publish

on:
  push:
    tags:
      - "helm-chart-*.*.*"
    paths:
      - 'charts/**'

jobs:
  helm-release:
    uses: cloudoperators/common/.github/workflows/shared-helm-release.yaml@main
    permissions:
      contents: read
      packages: write
    with:
      chart-dir: charts/myapp
      chart-name: myapp
```

### Example: Multiple charts in one workflow

```yaml
jobs:
  helm-release-app:
    uses: cloudoperators/common/.github/workflows/shared-helm-release.yaml@main
    permissions:
      contents: read
      packages: write
    with:
      chart-dir: charts/myapp
      chart-name: myapp
      run-dependency-update: true

  helm-release-ui:
    uses: cloudoperators/common/.github/workflows/shared-helm-release.yaml@main
    permissions:
      contents: read
      packages: write
    with:
      chart-dir: charts/myapp-ui
      chart-name: myapp-ui
```

### Example: Batch release where not all charts may have changed

Use `allow-existing: true` so jobs for unchanged charts (same version) exit 0 instead of failing:

```yaml
  helm-release-plugin-a:
    uses: cloudoperators/common/.github/workflows/shared-helm-release.yaml@main
    permissions:
      contents: read
      packages: write
    with:
      chart-dir: plugin-a/charts
      chart-name: plugin-a
      allow-existing: true
```

---

## `shared-docker-release.yaml`

Builds a multi-arch Docker image and pushes it to GHCR with a standard tag set.

### Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `image-name` | ✅ | — | Full GHCR image name, e.g. `ghcr.io/cloudoperators/myapp` |
| `dockerfile` | | `Dockerfile` | Path to the Dockerfile |
| `context` | | `.` | Docker build context path |
| `platforms` | | `linux/amd64,linux/arm64` | Comma-separated target platforms |
| `environment` | | `""` | GitHub environment name |
| `runs-on` | | `ubuntu-latest` | Runner label (must be Linux) |

### Secrets

| Secret | Required | Description |
|---|---|---|
| `registry-token` | | Registry token; falls back to `GITHUB_TOKEN` |

### Tags applied

| Tag | When |
|---|---|
| `1.2.3` | Always (full semver from tag) |
| `v1.2` | Always |
| `v1` | Always |
| `latest` | Only on default branch pushes |
| `sha-<long>` | Always |

### Example: Triggered by app release tag

```yaml
name: Container Registry

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  docker-release:
    uses: cloudoperators/common/.github/workflows/shared-docker-release.yaml@main
    permissions:
      contents: read
      packages: write
    with:
      image-name: ghcr.io/cloudoperators/myapp
```

### Example: Non-default Dockerfile location

```yaml
  docker-release:
    uses: cloudoperators/common/.github/workflows/shared-docker-release.yaml@main
    permissions:
      contents: read
      packages: write
    with:
      image-name: ghcr.io/cloudoperators/myapp
      dockerfile: build/Dockerfile
      context: .
```

---

## `shared-goreleaser.yaml`

Runs GoReleaser to build Go binaries and create a GitHub Release. Requires a `.goreleaser.yaml` config in the calling repo (or uses GoReleaser's default discovery).

### Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `goreleaser-version` | | `~> v2` | GoReleaser version constraint passed to `goreleaser-action` |
| `goreleaser-config` | | `""` | Path to `.goreleaser.yaml`. Leave empty to use GoReleaser's default file discovery. |
| `go-version-file` | | `go.mod` | Path to `go.mod` used by `setup-go` |
| `environment` | | `""` | GitHub environment name |
| `runs-on` | | `ubuntu-latest` | Runner label (must be Linux) |

### Secrets

| Secret | Required | Description |
|---|---|---|
| `release-token` | | Token for GoReleaser GitHub Release creation; falls back to `GITHUB_TOKEN` |

### Example: Standard Go project

```yaml
name: Release Binaries

on:
  push:
    tags:
      - "v*"

jobs:
  goreleaser:
    uses: cloudoperators/common/.github/workflows/shared-goreleaser.yaml@main
    permissions:
      contents: write
```

### Example: Custom config path

```yaml
  goreleaser:
    uses: cloudoperators/common/.github/workflows/shared-goreleaser.yaml@main
    permissions:
      contents: write
    with:
      goreleaser-config: .github/.goreleaser.yaml
```

---

## Complete example: Full release pipeline

App releases and chart releases are **separate flows** with separate tags — `v*` for app releases, `helm-chart-*` for chart-only releases. Wire them up as two independent pipelines.

> **Prerequisite:** For tags to automatically trigger downstream `push` workflows, `release-token` must be a PAT or GitHub App token. Tags pushed with `GITHUB_TOKEN` do not trigger other workflows.

### App release pipeline

Triggered manually → creates `vX.Y.Z` tag → Docker and binary publish fire automatically.

**`.github/workflows/cut-release.yaml`** — manually triggered, bumps version and creates `v*` tag:
```yaml
name: Cut Release

on:
  workflow_dispatch:
    inputs:
      bump:
        type: choice
        options: [patch, minor, major]
        required: true

jobs:
  release:
    uses: cloudoperators/common/.github/workflows/shared-release.yaml@main
    permissions:
      contents: write
    with:
      bump: ${{ inputs.bump }}
      makefile-path: Makefile
      chart-path: charts/myapp/Chart.yaml
    secrets:
      release-token: ${{ secrets.RELEASE_TOKEN }}
```

**`.github/workflows/release-docker.yaml`** — fires when `cut-release` creates a `v*` tag:
```yaml
name: Release Docker

on:
  push:
    tags:
      - "v*.*.*"

jobs:
  docker:
    uses: cloudoperators/common/.github/workflows/shared-docker-release.yaml@main
    permissions:
      contents: read
      packages: write
    with:
      image-name: ghcr.io/cloudoperators/myapp
```

**`.github/workflows/release-binaries.yaml`** — fires when `cut-release` creates a `v*` tag:
```yaml
name: Release Binaries

on:
  push:
    tags:
      - "v*.*.*"

jobs:
  goreleaser:
    uses: cloudoperators/common/.github/workflows/shared-goreleaser.yaml@main
    permissions:
      contents: write
```

### Chart release pipeline

Triggered manually → creates `helm-chart-vX.Y.Z` tag → Helm publish fires automatically.

**`.github/workflows/cut-chart-release.yaml`** — manually triggered, bumps chart version and creates `helm-chart-*` tag:
```yaml
name: Cut Chart Release

on:
  workflow_dispatch:
    inputs:
      bump:
        type: choice
        options: [patch, minor, major]
        required: true

jobs:
  release:
    uses: cloudoperators/common/.github/workflows/shared-release.yaml@main
    permissions:
      contents: write
    with:
      bump: ${{ inputs.bump }}
      chart-path: charts/myapp/Chart.yaml
      chart-only: true
    secrets:
      release-token: ${{ secrets.RELEASE_TOKEN }}
```

**`.github/workflows/release-chart.yaml`** — fires when `cut-chart-release` creates a `helm-chart-*` tag:
```yaml
name: Release Helm Chart

on:
  push:
    tags:
      - "helm-chart-*.*.*"

jobs:
  helm:
    uses: cloudoperators/common/.github/workflows/shared-helm-release.yaml@main
    permissions:
      contents: read
      packages: write
    with:
      chart-dir: charts/myapp
      chart-name: myapp
```
