<#
.SYNOPSIS
  Builds a Markdown release checklist from Azure DevOps release data.

.DESCRIPTION
  Uses the authenticated Azure CLI session and Azure DevOps REST APIs to find
  releases, associated pull requests, and linked work items. Project-specific
  values are stored in the skill's projects.json file.

.EXAMPLE
  New-AdoReleaseChecklist -Project match -Stage QA -Branch main

.EXAMPLE
  ado-checklist lane-history -Stage Production -OutputPath .\release.md
#>
[CmdletBinding()]
param()

$script:AdoAccessToken = $null

function Get-AdoAccessToken {
  # Azure DevOps resource ID; cached per session to avoid re-invoking az for every call.
  if (-not $script:AdoAccessToken) {
    $token = & az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to acquire an Azure DevOps access token.`n$($token -join [Environment]::NewLine)"
    }
    $script:AdoAccessToken = ($token -join '').Trim()
  }

  return $script:AdoAccessToken
}

function Invoke-AdoRest {
  param(
    [Parameter(Mandatory = $true)][string]$Uri,
    [ValidateSet('get', 'post')][string]$Method = 'get',
    [switch]$IgnoreNotFound
  )

  # Invoke-RestMethod avoids az.cmd's cmd.exe argument parsing of '&' in query strings.
  $headers = @{ Authorization = "Bearer $(Get-AdoAccessToken)" }
  try {
    return Invoke-RestMethod -Uri $Uri -Headers $headers -Method $Method -ErrorAction Stop
  } catch {
    $statusCode = $null
    if ($_.Exception.PSObject.Properties.Match('Response').Count -gt 0 -and $_.Exception.Response) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }

    # The commits/{id}/pullrequests API returns 404 (instead of an empty list) when no PR is linked.
    if ($IgnoreNotFound -and $statusCode -eq 404) {
      return $null
    }

    throw "Azure DevOps request failed for $Uri`n$($_.Exception.Message)"
  }
}

function Get-AdoConfig {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Configuration file not found: $Path"
  }

  $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  if (-not $config.organization -or -not $config.project -or -not $config.projects) {
    throw "Configuration must contain organization, project, and projects."
  }

  return $config
}

function Confirm-AdoSession {
  $null = & az account show --output none 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw 'Azure CLI is not authenticated. Run az login, then try again.'
  }

  $null = Get-Command az -ErrorAction Stop
}

function Select-AdoProject {
  param(
    [Parameter(Mandatory = $true)]$Config,
    [string]$Name,
    [Parameter(Mandatory = $true)][string]$ConfigPath
  )

  if ($Name) {
    $match = @($Config.projects | Where-Object { $_.name -ieq $Name })
    if ($match.Count -eq 1) {
      return $match[0]
    }

    Write-Host "Unknown project '$Name'. Available release projects:"
    $Config.projects | ForEach-Object { Write-Host "- $($_.name) (definition $($_.definitionId))" }
    $add = Read-Host "Add '$Name' to projects.json? (y/n)"
    if ($add -notmatch '^(y|yes)$') {
      throw "Unknown project '$Name'."
    }

    $definitionId = [int](Read-Host 'Release definition ID')
    $releaseUrl = Read-Host 'Release definition URL'
    $defaultBranch = Read-Host 'Default branch (main or master)'
    $branches = @(Read-Host 'Branch names, comma-separated' -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $stages = @(Read-Host 'Stage names, comma-separated' -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $newProject = [pscustomobject]@{
      name = $Name
      definitionId = $definitionId
      releaseUrl = $releaseUrl
      defaultBranch = $defaultBranch
      branches = $branches
      stages = $stages
    }
    $Config.projects += $newProject
    $Config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ConfigPath -Encoding utf8
    return $newProject
  }

  if ($Config.projects.Count -eq 1) {
    return $Config.projects[0]
  }

  Write-Host 'Available release projects:'
  for ($index = 0; $index -lt $Config.projects.Count; $index++) {
    Write-Host "[$($index + 1)] $($Config.projects[$index].name) (definition $($Config.projects[$index].definitionId))"
  }

  $selection = [int](Read-Host 'Select a project number') - 1
  if ($selection -lt 0 -or $selection -ge $Config.projects.Count) {
    throw 'The selected project is not available.'
  }

  return $Config.projects[$selection]
}

function Select-ConfiguredValue {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string[]]$Values,
    [string]$Default
  )

  if ($Default -and $Values -contains $Default) {
    return $Default
  }

  if ($Values.Count -eq 1) {
    return $Values[0]
  }

  Write-Host "Available $Label values:"
  for ($index = 0; $index -lt $Values.Count; $index++) {
    Write-Host "[$($index + 1)] $($Values[$index])"
  }

  $selection = [int](Read-Host "Select a $Label number") - 1
  if ($selection -lt 0 -or $selection -ge $Values.Count) {
    throw "The selected $Label is not available."
  }

  return $Values[$selection]
}

function Get-AdoReleaseManagementUri {
  param([Parameter(Mandatory = $true)]$Config)

  # Release Management APIs are served from the vsrm subdomain, unlike git/work item APIs.
  $releaseOrganization = $Config.organization -replace '^https://dev\.azure\.com', 'https://vsrm.dev.azure.com'
  return "$releaseOrganization/$($Config.project)"
}

function Get-ReleaseData {
  param(
    [Parameter(Mandatory = $true)]$Config,
    [Parameter(Mandatory = $true)]$ProjectConfig
  )

  $baseUri = Get-AdoReleaseManagementUri -Config $Config
  # $expand is required; the list endpoint omits environments/artifacts by default.
  $uri = "$baseUri/_apis/release/releases?definitionId=$($ProjectConfig.definitionId)&`$top=200&`$expand=environments,artifacts&queryOrder=descending&api-version=7.1"
  return (Invoke-AdoRest -Uri $uri).value
}

function Get-LastSuccessfulRelease {
  param(
    [Parameter(Mandatory = $true)]$Releases,
    [Parameter(Mandatory = $true)][string]$Stage
  )

  $candidates = foreach ($release in $Releases) {
    $environment = @($release.environments | Where-Object {
        $_.name -ieq $Stage -and $_.status -ieq 'succeeded'
      } | Sort-Object { [datetime]$_.deploySteps[-1].lastModifiedOn } -Descending | Select-Object -First 1)

    if ($environment) {
      [pscustomobject]@{
        Release = $release
        CompletedOn = [datetime]$environment.deploySteps[-1].lastModifiedOn
      }
    }
  }

  return $candidates | Sort-Object CompletedOn -Descending | Select-Object -First 1
}

function Get-ReleaseBranch {
  param([Parameter(Mandatory = $true)]$Release)

  $artifact = @($Release.artifacts | Select-Object -First 1)
  if (-not $artifact) {
    return $null
  }

  $branch = $artifact.definitionReference.branch.name
  if (-not $branch) {
    $branch = $artifact.definitionReference.branch.id
  }

  return $branch -replace '^refs/heads/', ''
}

function Get-ReleasePullRequests {
  param(
    [Parameter(Mandatory = $true)]$Config,
    [Parameter(Mandatory = $true)]$Release
  )

  $artifact = @($Release.artifacts | Select-Object -First 1)
  if (-not $artifact) {
    return @()
  }

  $buildId = $null
  if ($artifact.definitionReference.buildUri -and $artifact.definitionReference.buildUri.id) {
    $buildId = ($artifact.definitionReference.buildUri.id -replace '^vstfs:///Build/Build/', '')
  }

  $repositoryId = $artifact.definitionReference.repository.id
  $repositoryName = $artifact.definitionReference.repository.name
  $commitId = $artifact.definitionReference.sourceVersion.id
  if (-not $commitId) {
    $commitId = $artifact.definitionReference.version.id
  }

  $baseUri = "$($Config.organization)/$($Config.project)"
  $build = $null
  if ($buildId) {
    $buildUri = "$baseUri/_apis/build/builds/$buildId`?api-version=7.1"
    $build = Invoke-AdoRest -Uri $buildUri -IgnoreNotFound
    if ($build) {
      $repositoryId = $build.repository.id
      $commitId = $build.sourceVersion
      $repositoryName = $build.repository.name
    }
  }

  $pullRequests = @()
  if ($repositoryId -and $commitId) {
    $uri = "$baseUri/_apis/git/repositories/$repositoryId/commits/$commitId/pullrequests?api-version=7.1"
    $result = Invoke-AdoRest -Uri $uri -IgnoreNotFound
    if ($result) {
      $pullRequests = @($result.value)
    }
  }

  # Squash-merge commits are not resolvable through the commits/{id}/pullrequests API. The
  # triggering build's triggerInfo carries the originating PR number in its ci.message field
  # (e.g. "Merged PR 520998: <title>"), so fall back to that when no PR was found above.
  if ($pullRequests.Count -eq 0 -and $build -and $build.triggerInfo.'ci.message' -match 'Merged PR (\d+)') {
    $pullRequestId = $Matches[1]
    $prUri = "$baseUri/_apis/git/pullrequests/$pullRequestId`?api-version=7.1"
    $pullRequest = Invoke-AdoRest -Uri $prUri -IgnoreNotFound
    if ($pullRequest) {
      $pullRequests = @($pullRequest)
    }
  }

  if ($repositoryName) {
    foreach ($pullRequest in $pullRequests) {
      if (-not $pullRequest.repository) {
        $repository = [pscustomobject]@{
            id = $repositoryId
            name = $repositoryName
          }
        if ($pullRequest.PSObject.Properties['repository']) {
          $pullRequest.repository = $repository
        } else {
          $pullRequest | Add-Member -NotePropertyName repository -NotePropertyValue $repository
        }
      }
    }
  }

  return @($pullRequests | Where-Object { $_.status -in @('completed', 'abandoned') })
}

function Get-PullRequestItems {
  param(
    [Parameter(Mandatory = $true)]$Config,
    [Parameter(Mandatory = $true)]$PullRequest
  )

  $baseUri = "$($Config.organization)/$($Config.project)"
  $uri = "$baseUri/_apis/git/repositories/$($PullRequest.repository.id)/pullRequests/$($PullRequest.pullRequestId)/workitems?api-version=7.1"
  return @(Invoke-AdoRest -Uri $uri).value
}

function ConvertTo-MarkdownText {
  param([AllowNull()][string]$Value)

  if ($null -eq $Value) {
    return ''
  }

  return ($Value -replace '[\r\n]+', ' ' -replace '\|', '\|')
}

function New-AdoReleaseChecklist {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)][string]$Project,
    [string]$Branch,
    [string]$Stage,
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\Skills\ado-release-checklist\projects.json'),
    [string]$OutputPath,
    [switch]$IncludeLastSuccessfulRelease
  )

  Confirm-AdoSession
  $config = Get-AdoConfig -Path $ConfigPath
  $projectConfig = Select-AdoProject -Config $config -Name $Project -ConfigPath $ConfigPath
  $releases = @(Get-ReleaseData -Config $config -ProjectConfig $projectConfig)

  if (-not $Branch) {
    $Branch = Select-ConfiguredValue -Label 'branch' -Values @($projectConfig.branches) -Default $projectConfig.defaultBranch
  }

  if (-not $Stage) {
    $stageNames = @($projectConfig.stages)
    if ($stageNames.Count -eq 0) {
      $stageNames = @($releases.environments.name | Sort-Object -Unique)
    }
    if ($stageNames.Count -eq 0) {
      throw 'No stages are configured or available in the release data.'
    }
    $Stage = Select-ConfiguredValue -Label 'stage' -Values $stageNames -Default $projectConfig.defaultStage
  }

  $lastSuccessful = Get-LastSuccessfulRelease -Releases $releases -Stage $Stage
  if (-not $lastSuccessful) {
    throw "No successful '$Stage' release was found for $($projectConfig.name)."
  }

  $rows = foreach ($release in $releases | Sort-Object { [datetime]$_.createdOn }) {
    if ((Get-ReleaseBranch -Release $release) -ne $Branch) {
      continue
    }

    # Compare by release id (monotonically increasing with creation), not the successful
    # release's deployment completion time, which can trail behind newer queued releases.
    if (-not $IncludeLastSuccessfulRelease -and $release.id -le $lastSuccessful.Release.id) {
      continue
    }

    $pullRequests = @(Get-ReleasePullRequests -Config $config -Release $release)
    if ($pullRequests.Count -eq 0) {
      $releaseLink = "$($Config.organization)/$($Config.project)/_releaseProgress?_a=release-pipeline-progress&releaseId=$($release.id)"
      $releaseLabel = ConvertTo-MarkdownText -Value $release.name
      "| [$releaseLabel]($releaseLink) | No PR linked |  |  |  |  |"
      continue
    }

    foreach ($pullRequest in $pullRequests) {
      $items = @(Get-PullRequestItems -Config $config -PullRequest $pullRequest)
      $itemLinks = $items | ForEach-Object {
        "[$($_.id)]($($Config.organization)/$($Config.project)/_workitems/edit/$($_.id)/)"
      }
      $releaseLink = "$($Config.organization)/$($Config.project)/_releaseProgress?_a=release-pipeline-progress&releaseId=$($release.id)"
      $releaseLabel = ConvertTo-MarkdownText -Value $release.name
      $prLabel = ConvertTo-MarkdownText -Value $pullRequest.title
      $owner = ConvertTo-MarkdownText -Value $pullRequest.createdBy.displayName
      $repositoryName = $pullRequest.repository.name
      $prLink = "[$prLabel]($($Config.organization)/$($Config.project)/_git/$repositoryName/pullrequest/$($pullRequest.pullRequestId))"

      "| [$releaseLabel]($releaseLink) | $prLink | $(($itemLinks -join '<br>')) | $owner |  |  |"
    }
  }

  $markdown = @(
    "## $($projectConfig.name) release checklist"
    ''
    '| Release Name | PR | Items | Owner | Test | Prod |'
    '| --- | --- | --- | --- | --- | --- |'
    $rows
  ) -join [Environment]::NewLine

  if ($OutputPath) {
    Set-Content -LiteralPath $OutputPath -Value $markdown -Encoding utf8
  }

  return $markdown
}

Set-Alias -Name ado-checklist -Value New-AdoReleaseChecklist