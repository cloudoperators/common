# Issue Triage Workflow

A reusable composite action that automatically labels new issues with `needs-triage` and posts a welcome comment directing the reporter to the [Issue Lifecycle documentation](../../ISSUE_LIFECYCLE.md).

## Usage

Create `.github/workflows/issue-triage.yml` in your repository:

```yaml
name: Issue Triage
on:
  issues:
    types: [opened]

jobs:
  triage:
    runs-on: ubuntu-latest
    steps:
      - uses: cloudoperators/common/workflows/issue-triage@main
```

## What it does

1. Adds the `needs-triage` label to the newly opened issue
2. Posts a welcome comment with:
   - Acknowledgment of the issue
   - Link to the Issue Lifecycle documentation
   - Reminder of what information helps with triage

## Prerequisites

- The `needs-triage` label must exist in the repository (see label setup below)
- The default `GITHUB_TOKEN` is sufficient — no additional secrets needed

## Label Setup

Create the required label in your repository:

```bash
gh label create "needs-triage" --color "fbca04" --description "New issue, not yet reviewed" --repo cloudoperators/<repo-name>
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `GH_TOKEN` | No | `github.token` | GitHub token with issues write permission |