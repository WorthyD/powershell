function match() {
    wt -w 0 -d "C:\dev\match" pwsh -NoExit -Command startMatch `; `
        split-pane  -d "C:\dev\match" pwsh -NoExit -Command startMatchTests
        # move-focus right `; `
        # split-pane  -d "C:\dev\match" pwsh -NoExit -Command startMatchE2E  

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
    npm run start
}

function startMatchTests() {
    npm run test:ci
}