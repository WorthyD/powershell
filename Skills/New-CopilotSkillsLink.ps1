<#
.SYNOPSIS
    Links the Copilot ~/.copilot/skills folder to this repo's Skills folder via a directory junction.

.DESCRIPTION
    Run this from a clone of the PowerShell repo (or point -RepoSkillsPath at it) to make
    $env:USERPROFILE\.copilot\skills a junction into the repo's Skills folder, so skills are
    version-controlled. Safe to re-run: if the link already points at the right place, it does nothing.

.PARAMETER RepoSkillsPath
    Path to the Skills folder in the repo. Defaults to the folder this script lives in.

.EXAMPLE
    .\New-CopilotSkillsLink.ps1
#>
[CmdletBinding()]
param(
    [string]$RepoSkillsPath = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'

$linkPath = Join-Path $env:USERPROFILE '.copilot\skills'

if (-not (Test-Path $RepoSkillsPath)) {
    throw "Repo Skills path not found: $RepoSkillsPath"
}

$existing = Get-Item -Path $linkPath -Force -ErrorAction SilentlyContinue

if ($existing) {
    if ($existing.LinkType -eq 'Junction' -and $existing.Target -eq $RepoSkillsPath) {
        Write-Host "Already linked: $linkPath -> $RepoSkillsPath"
        return
    }
    if ($existing.LinkType) {
        Write-Host "Removing existing link at $linkPath"
        Remove-Item -Path $linkPath -Force
    }
    elseif ((Get-ChildItem -Path $linkPath -Force -ErrorAction SilentlyContinue).Count -eq 0) {
        Write-Host "Removing empty folder at $linkPath"
        Remove-Item -Path $linkPath -Force
    }
    else {
        throw "$linkPath already exists and is not empty. Move its contents into '$RepoSkillsPath' first, then re-run."
    }
}
else {
    $parent = Split-Path $linkPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

New-Item -ItemType Junction -Path $linkPath -Target $RepoSkillsPath | Out-Null
Write-Host "Linked $linkPath -> $RepoSkillsPath"
