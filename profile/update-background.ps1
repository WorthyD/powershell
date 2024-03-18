function updateBackground() {
    $random = Get-ChildItem $profileRoot\profile\backgrounds\ | Get-Random -Count 1 
    $a = Get-Content "$env:rootTerminalPath\settings.json" -raw | ConvertFrom-Json
    $a.profiles.defaults.backgroundImage = $random.ToString()
    $a | ConvertTo-Json -Depth 4 | set-content "$env:rootTerminalPath\settings.json"
}