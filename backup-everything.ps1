
#Backup User Profile
if ( $profileRoot -is [string]){ 
    backup($profileRoot)
} else{
    Write-Warning "Profile path not set"
}

#Backup NVIM
#backup($env:nvimPath)
