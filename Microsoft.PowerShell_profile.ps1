# https://ohmyposh.dev/
# https://www.nerdfonts.com/font-downloads -> Caskaydia Cove Nerd Font

$profileRoot = (Get-Item $profile).DirectoryName

. "$profileRoot\_variables.ps1"


#Enable Posh-Git
#Install-Module posh-git
$env:POSH_GIT_ENABLED = $true

# Start Windows SSH Agent service and add keys
$sshAgentService = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($sshAgentService.Status -ne 'Running') {
    Start-Service ssh-agent
}

# Add SSH keys to agent (suppresses output if already added)
ssh-add 2>$null

Import-Module posh-git


function Set-PoshGitStatus {
    $global:GitStatus = Get-GitStatus
    $env:POSH_GIT_STRING = Write-GitStatus -Status $global:GitStatus
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-PoshGitStatus' -Scope Global -Force

#Enable Terminal Icons 
## Install-Module -Name Terminal-Icons -Repository PSGallery
Import-Module -Name Terminal-Icons

# PSReadline Start
## Install-Module -Name PowerShellGet -Force
## Install-Module PSReadLine -AllowPrerelease -Force
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
# PSReadline End 


# Initialize Oh My Posh
oh-my-posh --init --shell pwsh --config $profileRoot\profile\ohmyposhv3-v4.json | Invoke-Expression

fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# Import User scripts
Get-ChildItem "$profileRoot\profile\*.ps1" | % { . $_ } 
