
#Backup User Profile
if ( $profileRoot -is [string]){ 
    backup($profileRoot)
} else{
    Write-Warning "Profile path not set"
}

#Backup NVIM
if ( $env:nvimPath -is [string]){ 
    backup($env:nvimPath)
} else{
    Write-Warning "Profile path not set"
}

#backup($env:nvimPath)
