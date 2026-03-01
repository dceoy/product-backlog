# AGENTS.md

This repository includes local agent skills for managing GitHub Projects.

## Default workflow

1. Confirm `gh` authentication and repository context.
2. Use GraphQL for GitHub Projects v2 operations whenever possible.
3. Prefer idempotent operations (check first, then create/update).
4. Summarize changes with explicit project/item/field IDs.

## Skills available in this repo

- **github-projects-manager** (`.agents/skills/github-projects-manager/SKILL.md`)
  - Use when creating, updating, triaging, or reporting on GitHub Projects (Projects v2).
  - Includes command patterns, GraphQL snippets, and safety checks.

## Execution rules

- Never hardcode owner, repository, project, or field IDs when they can be discovered.
- Before mutating project data, preview the target item and intended field/value updates.
- When adding issues/PRs to a project, verify item is not already present.
- For status/date/iteration fields, fetch available options first and map by name.

## Output expectations

- Include commands run and the resulting IDs or URLs.
- Clearly call out no-op cases (e.g., issue already in project).
- If permissions are missing, provide exact `gh auth refresh -s ...` scopes needed.
