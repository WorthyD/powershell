function Get-Attachments() {

    $searchPath = "C:\dev\Match-wiki"
    $searchString = "/.attachments/*.(png|jpg)"

    Get-ChildItem -Path $searchPath -Recurse -File | Select-String -Pattern $searchString
}
