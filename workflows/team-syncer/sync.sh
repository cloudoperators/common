#!/bin/bash

set -e

GITHUB_TOKEN=${GITHUB_TOKEN}

ORG_NAME=${GITHUB_ORG}
REPO_NAME=${GITHUB_REPO}

CONFIG_REPO="${GITHUB_ORG}/common"
CONFIG_FILE="teams_config.yaml"

SUPPORTED_PERMISSIONS=("pull" "push" "admin" "maintain" "triage")

fetch_config() {
  curl -s -H "Authorization: token $GITHUB_TOKEN" -L "https://raw.githubusercontent.com/${CONFIG_REPO}/main/${CONFIG_FILE}" -o $CONFIG_FILE
}

# Function to sync teams to a repository
sync_teams_to_repo() {
  local team=$1
  local permission=$2

  # Validate permission
  local valid_permission=false
  for p in "${SUPPORTED_PERMISSIONS[@]}"; do
    if [[ "$p" == "$permission" ]]; then
      valid_permission=true
      break
    fi
  done

  if [[ "$valid_permission" == false ]]; then
    echo "Invalid permission: $permission for team: $team. Skipping..."
    return
  fi

  curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/orgs/$ORG_NAME/teams/$team/repos/$ORG_NAME/$REPO_NAME" \
    -d "{\"permission\":\"$permission\"}"
}


fetch_config
teams=$(yq e '.teams[]' -o=json $CONFIG_FILE)

for team in $(echo "$teams" | jq -c '.'); do
  team_name=$(echo "$team" | jq -r '.name')
  team_permission=$(echo "$team" | jq -r '.permission')

  echo "Syncing team: $team_name with permission: $team_permission"
  sync_teams_to_repo $team_name $team_permission
done
