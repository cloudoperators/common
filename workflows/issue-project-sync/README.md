# Issue Project Sync Workflow

A reusable composite action that automatically adds issues to [cloudoperators project #9](https://github.com/orgs/cloudoperators/projects/9) when the `backlog` label is applied. Uses the official [actions/add-to-project](https://github.com/actions/add-to-project) action under the hood.

## Usage

Create `.github/workflows/issue-project-sync.yaml` in your repository:

```yaml
name: Issue Project Sync
on:
  issues:
    types: [labeled]

permissions:
  issues: read

jobs:
  sync:
    if: github.event.label.name == 'backlog'
    runs-on: ubuntu-latest
    steps:
      - uses: cloudoperators/common/workflows/issue-project-sync@main
        with:
          GH_TOKEN: ${{ secrets.GH_PROJECT_TOKEN }}
```

## What it does

1. Triggered when any label is added to an issue
2. Filters to only run when the `backlog` label is applied
3. Uses `actions/add-to-project` to add the issue to the organization project

## Prerequisites

### Org-level secret: `GH_PROJECT_TOKEN`

This workflow requires a GitHub token with elevated permissions to write to organization projects. Set this up once at the org level:

1. Go to **GitHub → cloudoperators → Settings → Secrets and variables → Actions**
2. Click **New organization secret**
3. Configure:
   - **Name:** `GH_PROJECT_TOKEN`
   - **Value:** A Personal Access Token (classic) or GitHub App token with scopes:
     - `project` (read/write)
     - `repo` (to read issue metadata)
   - **Repository access:** Select the repositories using this workflow:
     - `greenhouse`
     - `shoot-grafter`
     - `repo-guard`
     - `cloudctl`
     - `owner-label-injector`

### Labels

The `backlog` label must exist in the repository:

```bash
gh label create "backlog" --color "0e8a16" --description "Ready for sprint planning; triggers project addition" --repo cloudoperators/<repo-name>
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `GH_TOKEN` | **Yes** | — | GitHub token with `project` scope (org-level secret) |
| `PROJECT_URL` | No | `https://github.com/orgs/cloudoperators/projects/9` | Full URL of the GitHub project |