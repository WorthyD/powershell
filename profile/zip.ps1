function zip($in){
    $date = Get-Date -format yyyy.MM.dd

    7z a -r $in-$date.zip $in/*
}
