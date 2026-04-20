param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PassThroughArgs
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$coreDir   = Join-Path $scriptDir 'no0-core'
$dlcDir    = Join-Path $scriptDir 'no0-dlc-internal-control'

$pythonExe = $env:NO0_PYTHON
$pythonArgs = @()

if ([string]::IsNullOrWhiteSpace($pythonExe)) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $pythonExe = "py"
        $pythonArgs = @("-3")
    }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonExe = "python3"
    }
    elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonExe = "python"
    }
    else {
        Write-Error "[no0] Python interpreter not found (py/python3/python)."
        exit 127
    }
}

if ($PassThroughArgs.Count -gt 0 -and $PassThroughArgs[0] -eq "/no0") {
    if ($PassThroughArgs.Count -gt 1) {
        $PassThroughArgs = $PassThroughArgs[1..($PassThroughArgs.Count - 1)]
    }
    else {
        $PassThroughArgs = @()
    }
}

$coreCommands = @('status','start','stop','rollback','versions','diff','log','clear','clean','test','report')
$dlcCommands  = @('classify','audit','auth','init','decide')

$cmd = if ($PassThroughArgs.Count -gt 0) { $PassThroughArgs[0] } else { '' }

function Show-Help {
@"
No.0 — AI Agent Safety Guardian

Core commands (always available):
  status                 Check guardian status
  start / stop           Manage the guardian daemon
  rollback <f> <v>       Rollback a file to a version
  versions <f>           List versions of a file
  diff <f> <v>           Show diff against a version
  log [--last N]         Show recent change events
  clear                  Clear logs, training output, backups
  test                   Run local self-check

DLC commands (require No.0-DLC-Internal Control):
  classify               Data classification operations
  audit                  View audit log
  auth                   Authorization management
  decide <f> <action>    Resolve a pending L5 decision (rollback v<n> | keep | status)

For details: ./no0 <command> --help
"@
}

if ([string]::IsNullOrEmpty($cmd) -or $cmd -eq 'help' -or $cmd -eq '--help' -or $cmd -eq '-h') {
    Show-Help
    exit 0
}

if ($coreCommands -contains $cmd) {
    if ($cmd -eq 'start' -and -not [string]::IsNullOrWhiteSpace($env:NO0_RECONCILE_INTERVAL)) {
        if (-not ($PassThroughArgs -contains '--reconcile-interval')) {
            $PassThroughArgs += @('--reconcile-interval', $env:NO0_RECONCILE_INTERVAL)
        }
    }
    & $pythonExe @pythonArgs (Join-Path $coreDir 'scripts/skill_launcher.py') @PassThroughArgs
    exit $LASTEXITCODE
}

if ($dlcCommands -contains $cmd) {
    if (-not (Test-Path $dlcDir)) {
        Write-Error "[no0] '$cmd' requires No.0-DLC-Internal Control, which is not installed.`n       Install: ./install-dlc.sh"
        exit 2
    }
    & $pythonExe @pythonArgs (Join-Path $dlcDir 'cli/dlc_cli.py') @PassThroughArgs
    exit $LASTEXITCODE
}

Write-Error "[no0] Unknown command: $cmd`n       Run './no0 help' for usage."
exit 1
