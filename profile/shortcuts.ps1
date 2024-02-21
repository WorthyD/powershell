function dev() {
    cd $env:devPath
}

function xp() {
    explorer .
}
function nvimedit() {
    cd $env:nvimPath
}

function notes() {
    cd $env:obsidianPath
}

function giteager() {
    git add .
    git commit -a -m "Stuff"
    git push
}


function nuke_node { rimraf .\node_modules } 

function foo() {
    & "$env:foobarPath\foobar2000.exe"
}

function fp() {
    & "$env:foobarPath\foobar2000.exe" /playpause
}

function fpause() {
    & "$env:foobarPath\foobar2000.exe" /stop
}

function fn() {
    & "$env:foobarPath\foobar2000.exe" /next
}

function winp() {
    & "$env:psPath\PowerShell\CLEveR.exe" stop
}


function edithost() {
    Start-Process code -ArgumentList C:\Windows\System32\drivers\etc\hosts -Verb RunAs
}