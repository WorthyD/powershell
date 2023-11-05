function backup([string]$backupPath){

    cd $backupPath

    git add .

    git commit -m "automated backup `date +'%d-%m-%Y %H:%M:%S'`""

    git pull

    git push -u origin main

}