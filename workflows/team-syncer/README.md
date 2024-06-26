# Team syncer

Synchronizes configured teams to all repositories within the current organization.

Usage:
```yaml
name: Sync teams

on:
  schedule:
    - cron: '0 * * * *'  # Every hour.

jobs:
  call-sync-teams:
    uses: cloudoperators/common/workflows//team-syncer/sync.yml@main
    with:
      CONFIG_REPO: 'your-org/config-repo'  # Optional, defaults to 'your-org/config-repo'
      CONFIG_FILE: 'teams_config.yml'  # Optional, defaults to 'teams_config.yml'
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
