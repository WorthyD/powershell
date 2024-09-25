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

function callnvm() {
    # Always use argument version if there is one
    $versionDesired = $args[0]
  
    if (($versionDesired -eq "" -Or $versionDesired -eq $null) -And (Test-Path .nvmrc -PathType Any)) {
      # if we have an nvmrc and no argument supplied, use the version in the file
      $versionDesired = $(Get-Content .nvmrc).replace( 'v', '' );
    }
    Write-Host "Requesting version '$($versionDesired)'"
  
    if ($versionDesired -eq "") {
      Write-Host "A node version needs specifying as an argument if there is no .nvmrc"
    } else {
      $response = nvm use $versionDesired;
      if ($response -match 'is not installed') {
        if ($response -match '64-bit') {
          $response = nvm install $versionDesired x64
        } else {
          $response = nvm install $versionDesired x86
        }
        Write-Host $response
  
        $response = nvm use $versionDesired;
      }
  
      Write-Host $response
    }
  }
  Set-Alias nvmu -value "callnvm"