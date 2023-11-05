# https://ohmyposh.dev/

$profileRoot = (Get-Item $profile).DirectoryName

. "$profileRoot\_variables.ps1"

# https://www.nerdfonts.com/font-downloads -> Caskaydia Cove Nerd Font
#Enable Posh-Git
$env:POSH_GIT_ENABLED = $true
Import-Module posh-git

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
oh-my-posh --init --shell pwsh --config $profileRoot\profile\ohmyposhv3-v2.json | Invoke-Expression

# Import User scripts
Get-ChildItem "$profileRoot\profile\*.ps1" | % { . $_ } 
