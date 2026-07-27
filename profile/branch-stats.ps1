function branchStats {
    param(
        [string]$Base = "origin/main"
    )

    git fetch --prune | Out-Null

    git branch -r |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -notmatch "HEAD" -and $_ -ne $Base } |
        ForEach-Object {
            $branch = $_
            $mergeBase = git merge-base $Base $branch 2>$null
            if (-not $mergeBase) { return }

            $numstat = git diff --numstat $mergeBase $branch 2>$null
            $filesChanged = 0
            $linesAdded = 0
            $linesRemoved = 0

            if ($numstat) {
                $numstat -split "`n" | ForEach-Object {
                    if ($_ -match '^(\d+|-)\s+(\d+|-)\s+') {
                        $added = $Matches[1]
                        $removed = $Matches[2]
                        $filesChanged++
                        if ($added -ne '-') { $linesAdded += [int]$added }
                        if ($removed -ne '-') { $linesRemoved += [int]$removed }
                    }
                }
            }

            $lastCommitDate = git log -1 --format="%ai" $branch 2>$null
            $lastCommitUser = git log -1 --format="%an" $branch 2>$null

            $ahead = 0
            $behind = 0
            $revList = git rev-list --left-right --count "$Base...$branch" 2>$null
            if ($revList -match '(\d+)\s+(\d+)') {
                $behind = [int]$Matches[1]
                $ahead = [int]$Matches[2]
            }

            [PSCustomObject]@{
                Branch         = $branch
                FilesChanged   = $filesChanged
                LinesAdded     = $linesAdded
                LinesRemoved   = $linesRemoved
                Ahead          = $ahead
                Behind         = $behind
                LastCommit     = $lastCommitDate
                LastCommitUser = $lastCommitUser
            }
        } |
        Sort-Object LastCommit -Descending |
        Export-Csv -Path "branch-stats.csv" -NoTypeInformation

    Write-Host "Exported to branch-stats.csv"
}
