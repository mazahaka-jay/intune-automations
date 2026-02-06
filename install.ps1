$ErrorActionPreference = 'Stop'

$Log = Join-Path $env:ProgramData '<APP>-Install.log'
function Log([string]$msg) {
  "[{0}] {1}" -f (Get-Date -Format s), $msg | Out-File $Log -Append -Encoding utf8
}

Log "install.ps1 started as $(whoami)"
Log ("Is64BitProcess={0}" -f [Environment]::Is64BitProcess)
Log ("cwd: {0}" -f (Get-Location))

$msi = Join-Path $PSScriptRoot '<MSI_FILE_NAME>.msi'
if (-not (Test-Path $msi)) { throw "MSI not found: $msi" }

# Optional: MSI verbose log for troubleshooting
$msiLog = Join-Path $env:ProgramData '<APP>-msiexec-install.log'

$args = @(
  '/i', $msi,
  '/qn', '/norestart',
  "/l*v", $msiLog
  # <VENDOR_PROPERTIES> e.g. 'NOUPDATER=1'
)

$p = Start-Process msiexec.exe -ArgumentList $args -Wait -PassThru -NoNewWindow
Log ("msiexec exit code: {0}" -f $p.ExitCode)
exit $p.ExitCode
