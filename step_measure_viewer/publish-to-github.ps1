# Publish STEP measure viewer to GitHub (run from repo root)
# Usage: .\step_measure_viewer\publish-to-github.ps1

$ErrorActionPreference = "Stop"

$Root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path "$Root\step_measure_viewer\src\main.cpp")) {
    throw "Run this script from welding_robot_mition_plan repo root."
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    throw "gh not found. Install: winget install GitHub.cli"
}

gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Login to GitHub in browser..."
    gh auth login -h github.com -p https -w
}

$repoName = Read-Host "GitHub repo name [step-measure-viewer]"
if ([string]::IsNullOrWhiteSpace($repoName)) {
    $repoName = "step-measure-viewer"
}

$staging = Join-Path $env:TEMP "step_measure_viewer_github_publish"
if (Test-Path $staging) {
    Remove-Item $staging -Recurse -Force
}
New-Item -ItemType Directory -Path $staging | Out-Null

Copy-Item -Recurse "$Root\step_measure_viewer" "$staging\step_measure_viewer"
Copy-Item -Recurse "$Root\.github" "$staging\.github"

Push-Location $staging
try {
    git init -b main
    git add .
    git commit -m "Add STEP measure viewer with GitHub Actions CI"

    $visibility = Read-Host "Visibility public/private [public]"
    if ([string]::IsNullOrWhiteSpace($visibility)) {
        $visibility = "public"
    }

    gh repo create $repoName --$visibility --source=. --remote=origin --push

    $user = gh api user -q .login
    Write-Host ""
    Write-Host "Done. Next steps:"
    Write-Host "  1. Open https://github.com/$user/$repoName/actions"
    Write-Host "  2. Run workflow: Build STEP Measure Viewer"
    Write-Host "  3. Download artifact: step_measure_viewer-windows.zip"
}
finally {
    Pop-Location
}
