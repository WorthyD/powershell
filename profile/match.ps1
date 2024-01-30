function match() {
    wt -w 0 -d "C:\dev\match" pwsh -NoExit -Command startMatch `; `
        split-pane  -d "C:\dev\match" pwsh -NoExit -Command startMatchTests `; `
        move-focus right `; `
        split-pane  -d "C:\dev\match" pwsh -NoExit -Command startMatchE2E  

}

function startMatchE2E() {
    set-location ".\apps\match-e2e\" 
    npx cy2 open
}

function startMatch() {
    npm run start
}

function startMatchTests() {
    npm run test:ci
}