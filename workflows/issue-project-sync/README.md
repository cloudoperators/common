# Issue Project Sync Workflow

A reusable composite action that automatically adds issues to [cloudoperators project #9](https://github.com/orgs/cloudoperators/projects/9) when the `backlog` label is applied.

## Usage

Create `.github/workflows/issue-project-sync.yml` in your repository:

```yaml
name: Issue Project Sync
on:
  issues:
    types: [labeled]

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
3. Uses the GitHub GraphQL API to add the issue to the organization project

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
| `PROJECT_NUMBER` | No | `9` | The GitHub project number to add issues to |
| `ORG` | No | `cloudoperators` | The GitHub organization owning the project |

## How it works

The action uses the GitHub GraphQL API to:

1. Look up the project node ID from the org and project number
2. Add the issue (by its node ID) to the project using `addProjectV2ItemById`

This replaces the built-in GitHub Project "Auto-add" UI workflow with a code-based approach that can be version-controlled and applied consistently across repositories.