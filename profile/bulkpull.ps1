function bulkpull() {


    Get-ChildItem -Directory | ForEach-Object {
        Set-Location  $_
        git pull
        cd ..
    }

    $isPullable = checkStatus;
    if (!$isPullable) {
        'Can Pull'
    }
    else {
        'No Pull'
    }
}

function checkStatus() {
    $debug = $true


    if ($debug) {
        $sw = [Diagnostics.Stopwatch]::StartNew(); Write-Host ''
    }
    else {
        $sw = $null
    }


    $stashCount = 0

    dbg 'Getting status' $sw
    $status = git -c color.status=false status --short --branch 2>$null
    if ($settings.EnableStashStatus) {
        dbg 'Getting stash count' $sw
        $stashCount = $null | git stash list 2>$null | measure-object | select -expand Count
    }

    dbg 'Parsing status' $sw 
    $branch = $null
    $aheadBy = 0
    $behindBy = 0
    $indexAdded = @()
    $indexModified = @()
    $indexDeleted = @()
    $indexUnmerged = @()
    $filesAdded = @()
    $filesModified = @()
    $filesDeleted = @()
    $filesUnmerged = @()
    $stashCount = 0


    $status | foreach {
        dbg "Status: $_" $sw
        if ($_) {
            switch -regex ($_) {
                '^(?<index>[^#])(?<working>.) (?<path1>.*?)(?: -> (?<path2>.*))?$' {
                    switch ($matches['index']) {
                        'A' { $indexAdded += $matches['path1'] }
                        'M' { $indexModified += $matches['path1'] }
                        'R' { $indexModified += $matches['path1'] }
                        'C' { $indexModified += $matches['path1'] }
                        'D' { $indexDeleted += $matches['path1'] }
                        'U' { $indexUnmerged += $matches['path1'] }
                    }
                    switch ($matches['working']) {
                        '?' { $filesAdded += $matches['path1'] }
                        'A' { $filesAdded += $matches['path1'] }
                        'M' { $filesModified += $matches['path1'] }
                        'D' { $filesDeleted += $matches['path1'] }
                        'U' { $filesUnmerged += $matches['path1'] }
                    }
                }

                '^## (?<branch>\S+?)(?:\.\.\.(?<upstream>\S+))?(?: \[(?:ahead (?<ahead>\d+))?(?:, )?(?:behind (?<behind>\d+))?\])?$' {
                    $branch = $matches['branch']
                    $upstream = $matches['upstream']
                    $aheadBy = [int]$matches['ahead']
                    $behindBy = [int]$matches['behind']
                }

                '^## Initial commit on (?<branch>\S+)$' {
                    $branch = $matches['branch']
                }
            }
        }
    }
    if (!$branch) { $branch = Get-GitBranch $gitDir $sw }
    dbg 'Building status object' $sw
    $indexPaths = $indexAdded + $indexModified + $indexDeleted + $indexUnmerged
    $workingPaths = $filesAdded + $filesModified + $filesDeleted + $filesUnmerged
    $index = New-Object PSObject @(, @($indexPaths | ? { $_ } | Select -Unique)) |
        Add-Member -PassThru NoteProperty Added    $indexAdded |
        Add-Member -PassThru NoteProperty Modified $indexModified |
        Add-Member -PassThru NoteProperty Deleted  $indexDeleted |
        Add-Member -PassThru NoteProperty Unmerged $indexUnmerged
    $working = New-Object PSObject @(, @($workingPaths | ? { $_ } | Select -Unique)) |
        Add-Member -PassThru NoteProperty Added    $filesAdded |
        Add-Member -PassThru NoteProperty Modified $filesModified |
        Add-Member -PassThru NoteProperty Deleted  $filesDeleted |
        Add-Member -PassThru NoteProperty Unmerged $filesUnmerged

    $result = New-Object PSObject -Property @{
        GitDir       = $gitDir
        Branch       = $branch
        AheadBy      = $aheadBy
        BehindBy     = $behindBy
        Upstream     = $upstream
        HasIndex     = [bool]$index
        Index        = $index
        HasWorking   = [bool]$working
        Working      = $working
        HasUntracked = [bool]$filesAdded
        StashCount   = $stashCount
    }

    dbg 'Finished' $sw
    if ($sw) { $sw.Stop() }
    return $result.HasWorking
}

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if ($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds, $Message) -Verbose # -ForegroundColor Yellow
    }
}
