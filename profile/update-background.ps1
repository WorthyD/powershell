function updateBackground() {
    $random = Get-ChildItem E:\Users\Daniel\Documents\PowerShell\profile\backgrounds\ | Get-Random -Count 1 
    $a = Get-Content "$env:rootTerminalPath\settings.json" -raw | ConvertFrom-Json
    $a.profiles.defaults.backgroundImage = $random.ToString()
    $a | ConvertTo-Json -Depth 4 | set-content "$env:rootTerminalPath\settings.json"
}