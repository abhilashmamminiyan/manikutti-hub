<#
.SYNOPSIS
    Automated Pull Request lifecycle script for Manikutti Ecosystem.
.DESCRIPTION
    Validates tests, synchronizes with main, pushes to remote, creates/reuses PR,
    monitors GitHub Actions CI run logs, and merges the PR once checks pass.
.EXAMPLE
    .\scripts\automate_pr.ps1 -Repo "mobile" -Title "feat(balance): accurate bank balances" -Body "Resolves balance mismatch"
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateSet('mobile', 'hub', 'web', 'current')]
    [string]$Repo = 'mobile',

    [Parameter(Position = 1)]
    [string]$Title,

    [Parameter(Position = 2)]
    [string]$Body,

    [string]$Base = 'main',
    [string]$Branch,
    [switch]$AutoMerge = $true,
    [switch]$SkipTests = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param ([string]$Message)
    Write-Host "`n=== [STEP] $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param ([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarningMsg {
    param ([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param ([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Auto-resolve GH_TOKEN from Git Credential Manager if not already set
if (-not $env:GH_TOKEN) {
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "git"
        $psi.Arguments = "credential fill"
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.StandardInput.WriteLine("protocol=https")
        $proc.StandardInput.WriteLine("host=github.com")
        $proc.StandardInput.WriteLine("")
        $proc.StandardInput.Close()
        $credOutput = $proc.StandardOutput.ReadToEnd()
        $proc.WaitForExit()
        foreach ($line in ($credOutput -split "`r?`n")) {
            if ($line -match "^password=(.+)$") {
                $env:GH_TOKEN = $Matches[1].Trim()
                Write-Host "[INFO] Injected GitHub PAT from Git Credential Manager." -ForegroundColor Gray
                break
            }
        }
    } catch {
        # ignore error if credential manager is not available
    }
}

if (-not $env:GH_TOKEN) {
    try {
        $tok = (gh auth token 2>$null)
        if ($tok -and $tok.Trim().Length -gt 10) {
            $env:GH_TOKEN = $tok.Trim()
            Write-Host "[INFO] Injected GitHub PAT from system keyring." -ForegroundColor Gray
        }
    } catch {}
}

# 1. Resolve Target Directory
$WorkspaceRoot = "d:\MERN\Personal\my-apps\finance-tracker"
if (Test-Path "$WorkspaceRoot\.gh") {
    $env:GH_CONFIG_DIR = "$WorkspaceRoot\.gh"
    Write-Host "Using repository-scoped GH_CONFIG_DIR: $env:GH_CONFIG_DIR" -ForegroundColor Gray
}
$TargetDir = switch ($Repo) {
    'mobile'  { "$WorkspaceRoot\manikutti_mobile" }
    'web'     { "$WorkspaceRoot\Manikutti" }
    'hub'     { "$WorkspaceRoot" }
    'current' { (Get-Location).Path }
}

if (-not (Test-Path $TargetDir)) {
    Write-ErrorMsg "Target repository path '$TargetDir' does not exist."
    exit 1
}

Push-Location $TargetDir
try {
    Write-Step "Resolving Repository and Branch Context ($TargetDir)"

    # Get Current Branch
    if (-not $Branch) {
        $Branch = (git rev-parse --abbrev-ref HEAD).Trim()
    }
    Write-Host "Current Branch : $Branch" -ForegroundColor White
    Write-Host "Target Base    : $Base" -ForegroundColor White

    if ($Branch -eq $Base) {
        Write-ErrorMsg "You are currently on base branch '$Base'. Switch to a feature branch first."
        exit 1
    }

    # Extract GitHub Repo Slug from Origin
    $OriginUrl = (git remote get-url origin).Trim()
    $RepoSlug = $OriginUrl -replace '.*github\.com[:/]', '' -replace '\.git$', ''
    Write-Host "GitHub Repo    : $RepoSlug" -ForegroundColor White

    # 2. Pre-flight Checks & Test Execution
    if (-not $SkipTests) {
        Write-Step "Running Pre-Flight Tests in $TargetDir"
        if (Test-Path "pubspec.yaml") {
            Write-Host "Running Flutter test suite..." -ForegroundColor Gray
            flutter test
            if ($LASTEXITCODE -ne 0) {
                Write-ErrorMsg "Flutter tests failed! Aborting PR creation. Fix failing tests first."
                exit 1
            }
            Write-Success "All Flutter tests passed."
        } elseif (Test-Path "package.json") {
            Write-Host "Running npm test..." -ForegroundColor Gray
            npm test --if-present
            if ($LASTEXITCODE -ne 0) {
                Write-ErrorMsg "npm tests failed! Aborting PR creation."
                exit 1
            }
            Write-Success "All npm tests passed."
        }
    } else {
        Write-WarningMsg "Skipping tests as requested."
    }

    # 3. Synchronize with Base Branch
    Write-Step "Syncing with origin/$Base"
    git fetch origin $Base
    git merge "origin/$Base" --no-edit
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Merge conflict detected while integrating origin/$Base. Please resolve conflicts before continuing."
        exit 1
    }
    Write-Success "Branch is up-to-date with origin/$Base."

    # 4. Push Feature Branch
    Write-Step "Pushing $Branch to origin"
    git push origin $Branch
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Failed to push $Branch to origin."
        exit 1
    }
    Write-Success "Branch $Branch successfully pushed to origin."

    # 5. User Confirmation
    if (-not $Force) {
        Write-Step "Confirmation Required"
        Write-Host "Ready to create and merge Pull Request:" -ForegroundColor White
        Write-Host "  Repository: $RepoSlug" -ForegroundColor Gray
        Write-Host "  Branch    : $Branch -> $Base" -ForegroundColor Gray
        Write-Host "  Title     : $(if ($Title) { $Title } else { '(Will use latest commit)' })" -ForegroundColor Gray

        $resp = Read-Host "Proceed with raising PR and monitoring CI? (y/n)"
        if ($resp -notmatch '^[yY]') {
            Write-WarningMsg "PR creation aborted by user."
            exit 0
        }
    }

    # 6. Check for Existing Open PR or Create New One
    Write-Step "Checking for existing Pull Request"
    $ExistingPrJson = ""
    try {
        $ExistingPrJson = gh pr list --repo $RepoSlug --head $Branch --state open --json number,title,url | ConvertFrom-Json
    } catch {
        # ignore error if gh isn't fully authenticated
    }

    $PrNumber = $null
    $PrUrl = $null

    if ($ExistingPrJson -and $ExistingPrJson.Count -gt 0) {
        $PrNumber = $ExistingPrJson[0].number
        $PrUrl = $ExistingPrJson[0].url
        Write-Success "Found existing open PR #$PrNumber ($PrUrl)"
    } else {
        Write-Step "Raising New Pull Request"
        if (-not $Title) {
            $Title = (git log -1 --pretty=%s).Trim()
        }
        if (-not $Body) {
            $Body = (git log -1 --pretty=%b).Trim()
            if (-not $Body) {
                $Body = "Automated Pull Request for feature branch $Branch."
            }
        }

        # Attempt to create via GitHub CLI
        $Created = $false
        try {
            $PrUrl = (gh pr create --repo $RepoSlug --head $Branch --base $Base --title "$Title" --body "$Body").Trim()
            if ($PrUrl -match '/pull/(\d+)') {
                $PrNumber = $Matches[1]
                $Created = $true
                Write-Success "PR #$PrNumber created: $PrUrl"
            }
        } catch {
            Write-WarningMsg "GitHub CLI could not create PR automatically ($($_.Exception.Message))."
        }

        if (-not $Created) {
            $WebCreateUrl = "https://github.com/$RepoSlug/pull/new/$Branch"
            Write-Host "`nOpening PR creation in browser: $WebCreateUrl" -ForegroundColor Cyan
            Start-Process $WebCreateUrl

            Write-Host "`nPlease click 'Create pull request' on the opened page." -ForegroundColor Yellow
            $inputVal = Read-Host "Enter the PR number once created (e.g., 42), or press Enter to auto-detect"
            if ($inputVal -match '^\d+$') {
                $PrNumber = [int]$inputVal
            } else {
                Start-Sleep -Seconds 5
                $detected = gh pr list --repo $RepoSlug --head $Branch --state open --json number,url | ConvertFrom-Json
                if ($detected -and $detected.Count -gt 0) {
                    $PrNumber = $detected[0].number
                    $PrUrl = $detected[0].url
                }
            }
        }
    }

    if (-not $PrNumber) {
        Write-ErrorMsg "Could not determine PR number. Please check https://github.com/$RepoSlug/pulls."
        exit 1
    }

    # 7. Monitor CI / GitHub Actions Run
    Write-Step "Monitoring GitHub Actions CI Pipeline for PR #$PrNumber"
    Write-Host "Waiting for workflow run to register on GitHub Actions..." -ForegroundColor Gray

    $RunId = $null
    for ($i = 0; $i -lt 12; $i++) {
        Start-Sleep -Seconds 5
        try {
            $runs = gh run list --repo $RepoSlug --branch $Branch --limit 1 --json databaseId,status,conclusion,name,url | ConvertFrom-Json
            if ($runs -and $runs.Count -gt 0) {
                $RunId = $runs[0].databaseId
                Write-Host "Detected Workflow Run: $($runs[0].name) (Run ID: $RunId)" -ForegroundColor Cyan
                break
            }
        } catch {}
    }

    if ($RunId) {
        Write-Host "Watching CI execution logs in real-time..." -ForegroundColor Gray
        try {
            gh run watch $RunId --repo $RepoSlug --exit-status
            Write-Success "GitHub Actions CI pipeline PASSED successfully!"
        } catch {
            Write-ErrorMsg "GitHub Actions CI pipeline FAILED or timed out!"
            Write-Host "`n=== FAILED CI LOG SUMMARY ===" -ForegroundColor Red
            gh run view $RunId --repo $RepoSlug --log-failed
            Write-Host "=============================" -ForegroundColor Red
            Write-ErrorMsg "Please fix the compilation/test errors shown above and re-run this script."
            exit 1
        }
    } else {
        Write-WarningMsg "No active GitHub Actions workflow run detected for branch $Branch. Continuing..."
    }

    # 8. Merge PR to Base
    if ($AutoMerge) {
        Write-Step "Merging PR #$PrNumber into $Base"
        $Merged = $false
        try {
            $prState = (gh pr view $PrNumber --repo $RepoSlug --json state -q .state).Trim()
            if ($prState -eq 'MERGED') {
                $Merged = $true
                Write-Success "PR #$PrNumber was automatically merged by GitHub Actions!"
            } else {
                gh pr merge $PrNumber --repo $RepoSlug --squash --delete-branch
                $Merged = $true
                Write-Success "PR #$PrNumber has been successfully merged into $Base!"
            }
        } catch {
            Start-Sleep -Seconds 3
            $prState = (gh pr view $PrNumber --repo $RepoSlug --json state -q .state 2>$null)
            if ($prState -and $prState.Trim() -eq 'MERGED') {
                $Merged = $true
                Write-Success "PR #$PrNumber was successfully merged!"
            } else {
                Write-WarningMsg "GitHub CLI could not execute merge ($($_.Exception.Message))."
            }
        }

        if (-not $Merged) {
            $PrPage = "https://github.com/$RepoSlug/pull/$PrNumber"
            Write-Host "Opening PR page to confirm merge: $PrPage" -ForegroundColor Cyan
            Start-Process $PrPage
            Read-Host "Press Enter once PR #$PrNumber has been merged on GitHub"
        }

        # 9. Sync Local Base Branch
        Write-Step "Syncing local $Base branch"
        git checkout $Base
        git pull origin $Base
        Write-Success "Local $Base branch is now fully up to date."

        # If we modified mobile submodule, update the master hub repository pointer as well
        if ($Repo -eq 'mobile' -and (Test-Path "$WorkspaceRoot\.gitmodules")) {
            Write-Step "Updating Master Hub Submodule Reference"
            Push-Location $WorkspaceRoot
            try {
                git add manikutti_mobile
                git commit -m "feat(hub): link manikutti_mobile PR #$PrNumber merge commit" -q
                git push origin $Base
                Write-Success "Master hub submodule commit pointer synchronized and pushed to $Base."
            } catch {
                Write-WarningMsg "Could not automatically update master hub pointer: $($_.Exception.Message)"
            } finally {
                Pop-Location
            }
        }
    }

    Write-Host "`nAll tasks completed successfully! PR #$PrNumber verified and merged." -ForegroundColor Green
} finally {
    Pop-Location
}
