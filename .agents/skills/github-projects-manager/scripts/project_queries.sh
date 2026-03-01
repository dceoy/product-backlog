#!/usr/bin/env bash
set -euo pipefail

# Lightweight helpers for GitHub Projects v2 discovery.
# Usage examples:
#   ./project_queries.sh project <owner> <number>
#   ./project_queries.sh issue-node-id <owner> <repo> <issue_number>
#   ./project_queries.sh pr-node-id <owner> <repo> <pr_number>

usage() {
  cat <<'USAGE' >&2
Usage:
  project_queries.sh project <owner> <project_number>
  project_queries.sh issue-node-id <owner> <repo> <issue_number>
  project_queries.sh pr-node-id <owner> <repo> <pr_number>
USAGE
}

require_project_scope() {
  local auth_status scopes

  if ! auth_status="$(gh auth status -h github.com 2>&1)"; then
    printf '%s\n' "$auth_status" >&2
    printf 'Run: gh auth login\n' >&2
    return 2
  fi

  scopes="$(printf '%s\n' "$auth_status" | sed -n 's/^[[:space:]]*- Token scopes:[[:space:]]*//p' | head -n 1)"
  if [[ -z "$scopes" ]]; then
    printf "Could not determine token scopes from \`gh auth status -h github.com\`.\n" >&2
    printf 'Run: gh auth status -h github.com\n' >&2
    return 2
  fi

  if ! printf '%s\n' "$scopes" | grep -Eq '(^|[^[:alnum:]:_-])(read:project|project)($|[^[:alnum:]:_-])'; then
    printf 'Missing required GitHub scope for Projects v2. Current scopes: %s\n' "$scopes" >&2
    printf 'Run: gh auth refresh -h github.com -s read:project,project,repo\n' >&2
    return 2
  fi
}

cmd="${1:-}"

# shellcheck disable=SC2016 # GraphQL placeholders must remain literal.
readonly project_query='query($login:String!,$number:Int!){ user(login:$login){ projectV2(number:$number){ id title url number } } organization(login:$login){ projectV2(number:$number){ id title url number } } }'
# shellcheck disable=SC2016 # GraphQL placeholders must remain literal.
readonly issue_query='query($owner:String!,$repo:String!,$number:Int!){ repository(owner:$owner,name:$repo){ issue(number:$number){ id url title } } }'
# shellcheck disable=SC2016 # GraphQL placeholders must remain literal.
readonly pr_query='query($owner:String!,$repo:String!,$number:Int!){ repository(owner:$owner,name:$repo){ pullRequest(number:$number){ id url title } } }'

case "$cmd" in
project)
  owner="${2:?owner required}"
  number="${3:?project number required}"
  require_project_scope
  gh api graphql -f query="$project_query" -F login="$owner" -F number="$number"
  ;;
issue-node-id)
  owner="${2:?owner required}"
  repo="${3:?repo required}"
  number="${4:?issue number required}"
  gh api graphql -f query="$issue_query" -F owner="$owner" -F repo="$repo" -F number="$number"
  ;;
pr-node-id)
  owner="${2:?owner required}"
  repo="${3:?repo required}"
  number="${4:?pr number required}"
  gh api graphql -f query="$pr_query" -F owner="$owner" -F repo="$repo" -F number="$number"
  ;;
"" )
  usage
  exit 2
  ;;
*)
  printf 'Unknown command: %s\n' "$cmd" >&2
  usage
  exit 1
  ;;
esac
