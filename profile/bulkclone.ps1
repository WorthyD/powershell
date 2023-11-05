function bulkclone($in) {
    $content = Get-Content $in
    foreach ($line in $content) {

        $arr = $line -split " "
        $gitUrl = $arr[0]
        $folderName = $arr[1]
        git clone  $gitUrl $folderName
    }
}