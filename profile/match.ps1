function match() {
    wt -w 0 -d "C:\dev\match" pwsh  -Command startMatch -NoExit `; `
        split-pane  -d "C:\dev\match\apps\match-e2e" pwsh -NoExit `; `
         split-pane  -d "C:\dev\match" pwsh -NoExit  -Command git status

}

function matchreview() {
    wt -w 0 -d "C:\dev\match-review" pwsh -NoExit -Command startMatch `; `
        split-pane  -d "C:\dev\match-review" pwsh -NoExit -Command startMatchTests
        # move-focus right `; `
        # split-pane  -d "C:\dev\match" pwsh -NoExit -Command startMatchE2E  

}

function startMatchE2E() {
    npm run cypress-open
}

function startMatch() {
    pm run start
}

function startMatchTests() {
    npm run test:ci
}