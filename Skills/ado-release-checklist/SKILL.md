---
name: ado-release-checklist
description: >-
  Build a Markdown Azure DevOps release checklist using the authenticated Azure
  CLI session. Use when the user asks to create a release checklist, says
  "create a release for match" or "create a release for lane-history", or asks
  for releases, pull requests, owners, and linked work items from a branch.
  This workflow is read-only and does not create or deploy releases.
---

## Purpose

Use the reusable PowerShell helper to collect the last successful stage release,
branch releases after that point, associated pull requests, and linked work
items. Produce a Markdown table with these columns:

| Release Name | PR | Items | Owner | Test | Prod |
| --- | --- | --- | --- | --- | --- |

`Test` and `Prod` must remain empty for later validation tracking in Teams.

## Phase 0: Load the configuration

1. Read `Skills/ado-release-checklist/projects.json`.
2. Resolve the project name from the user's request. The known shortcuts are:

   | Shortcut | Release definition |
   | --- | --- |
   | `match` | [Match releases](https://dev.azure.com/jbhunt/EngAndTech/_release?_a=releases&view=mine&definitionId=2976) |
   | `lane-history` | [Lane history releases](https://dev.azure.com/jbhunt/EngAndTech/_release?_a=releases&view=mine&definitionId=14284) |

3. If the project is unknown, show every configured project and ask whether to
   add a new release definition. New entries must be saved in the JSON file;
   do not invent a definition ID or silently use a different project.
4. Resolve the branch and stage. Use configured defaults when present. If a
   value is missing or multiple configured values are available, prompt with
   the available names and save only deliberate configuration changes.

## Phase 1: Check Azure CLI access

Run the following before any read:

```powershell
az account show
```

If it fails, ask the user to run `az login`. Do not request or store a PAT in
the project JSON. The helper uses `az rest`, so the active Azure CLI identity
must have permission to read the Azure DevOps project and repositories.

Load the helper into the current PowerShell session when needed:

```powershell
. .\profile\ado-release-checklist.ps1
```

## Phase 2: Gather release data

Run the helper with the resolved values:

```powershell
New-AdoReleaseChecklist -Project match -Branch main -Stage QA
```

The default scope is releases on the selected branch created after the most
recent successful deployment to the selected stage. The helper must:

1. Query the configured release definition.
2. Find the last successful release for the requested stage.
3. Filter releases by source branch.
4. Resolve each release artifact's commit to associated pull requests.
5. Query linked work items for each pull request.
6. Keep the release order deterministic and preserve releases with multiple
   linked work items.

For releases whose artifact is a build rather than a Git commit, resolve the
artifact's build ID through the Builds API first. Use the build's
`sourceVersion` and repository to query associated pull requests, then retain
closed PRs with `completed` or `abandoned` status.

If a release has no associated pull request, report it clearly and omit it from
the checklist rather than generating an unlinked or guessed PR.

## Phase 3: Render the checklist

The output must use these link rules:

- Release Name: a short linked release name pointing to the release progress
  URL, such as `[352](https://dev.azure.com/.../_releaseProgress?...&releaseId=1132871)`.
- PR: the pull request title linked to the created PR.
- Items: every linked work item as a link, separated with `<br>` when there is
  more than one.
- Owner: the pull request creator's display name.
- Test and Prod: empty cells.

Titles and names must escape pipes and line breaks so they cannot corrupt the
Markdown table. Write a file when requested:

```powershell
New-AdoReleaseChecklist -Project lane-history -Stage Production `
  -OutputPath .\lane-history-release-checklist.md
```

## Phase 4: Configuration changes

Edit only `projects.json` for project-specific values. Each project entry may
define:

```json
{
  "name": "example",
  "definitionId": 12345,
  "releaseUrl": "https://dev.azure.com/jbhunt/EngAndTech/_release?...",
  "defaultBranch": "main",
  "defaultStage": "Production",
  "branches": ["main", "master"],
  "stages": ["QA", "Production"]
}
```

Never save credentials, access tokens, or personal access tokens in this file.

## Validation

- Parse the PowerShell file before using it:

  ```powershell
  [System.Management.Automation.Language.Parser]::ParseFile(
    '.\profile\ado-release-checklist.ps1', [ref]$null, [ref]$null)
  ```

- Load the JSON with `Get-Content ... | ConvertFrom-Json`.
- Confirm the generated header has exactly six columns.
- Confirm every release and PR link is present and `Test`/`Prod` cells are
  empty.
- Confirm a missing project or stage produces a prompt/error rather than an
  incorrect release query.

The skill link can be refreshed with `Skills/New-CopilotSkillsLink.ps1`; do not
remove or overwrite a non-empty unmanaged skills directory.