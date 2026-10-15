<#
.SYNOPSIS
    Links the Copilot ~/.copilot/instructions folder to this repo's Instructions folder via a directory junction.

.DESCRIPTION
    Run this from a clone of the PowerShell repo (or point -RepoInstructionsPath at it) to make
    $env:USERPROFILE\.copilot\instructions a junction into the repo's Instructions folder, so instructions are
    version-controlled. Safe to re-run: if the link already points at the right place, it does nothing.

.PARAMETER RepoInstructionsPath
    Path to the Instructions folder in the repo. Defaults to the folder this script lives in.

.EXAMPLE
    .\New-CopilotInstructionsLink.ps1
#>
[CmdletBinding()]
param(
    [string]$RepoInstructionsPath = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'

$linkPath = Join-Path $env:USERPROFILE '.copilot\instructions'

if (-not (Test-Path $RepoInstructionsPath)) {
    throw "Repo Instructions path not found: $RepoInstructionsPath"
}

$existing = Get-Item -Path $linkPath -Force -ErrorAction SilentlyContinue

if ($existing) {
    if ($existing.LinkType -eq 'Junction' -and $existing.Target -eq $RepoInstructionsPath) {
        Write-Host "Already linked: $linkPath -> $RepoInstructionsPath"
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
        throw "$linkPath already exists and is not empty. Move its contents into '$RepoInstructionsPath' first, then re-run."
    }
}
else {
    $parent = Split-Path $linkPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

New-Item -ItemType Junction -Path $linkPath -Target $RepoInstructionsPath | Out-Null
Write-Host "Linked $linkPath -> $RepoInstructionsPath"
