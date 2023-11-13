function backup([string]$backupPath) {

    cd $backupPath

    git add .

    $date = Get-Date

    git commit -m "automated backup `date +'$date'`""

    git pull

    git push -u origin main

}

function backupTheThings() {
    #Backup User Profile
    if ( $profileRoot -is [string]) { 
        backup($profileRoot)
    }
    else {
        Write-Warning "Profile path not set"
    }

    #Backup NVIM
    if ( $env:nvimPath -is [string]) { 
        backup($env:nvimPath)
    }
    else {
        Write-Warning "Profile path not set"
    }

    #backup Obsidian
}