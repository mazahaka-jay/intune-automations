$ErrorActionPreference = 'Stop'

$Log = Join-Path $env:ProgramData '<APP>-Uninstall.log'
function Log([string]$msg) {
  "[{0}] {1}" -f (Get-Date -Format s), $msg | Out-File $Log -Append -Encoding utf8
}

Log "uninstall.ps1 started as $(whoami)"
Log ("Is64BitProcess={0}" -f [Environment]::Is64BitProcess)
Log ("cwd: {0}" -f (Get-Location))

$productName = '<PRODUCT_NAME_CONTAINS>'  # e.g. 'Notepad++'

# Read HKLM uninstall using 64-bit registry view (no WoW64 redirect)
$base = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
  [Microsoft.Win32.RegistryHive]::LocalMachine,
  [Microsoft.Win32.RegistryView]::Registry64
)

$uninstall = $base.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
if (-not $uninstall) { throw "Registry uninstall key not found (Registry64)." }

$hit = $null
foreach ($name in $uninstall.GetSubKeyNames()) {
  $k = $uninstall.OpenSubKey($name)
  if (-not $k) { continue }
  $dn = $k.GetValue('DisplayName')
  if ($dn -and $dn.ToString().ToLower().Contains($productName.ToLower())) {
    $hit = $name
    Log ("Found DisplayName='{0}' KeyName='{1}'" -f $dn, $name)
    break
  }
}

if (-not $hit) {
  Log "Product not found in Registry64 uninstall. Exiting 0."
  exit 0
}

# MSI ProductCode usually equals the subkey name (GUID)
if ($hit -notmatch '^\{[0-9A-Fa-f-]{36}\}$') { throw "Matched key is not a GUID: $hit" }

$args = @('/x', $hit, '/qn', '/norestart')
$p = Start-Process msiexec.exe -ArgumentList $args -Wait -PassThru -NoNewWindow
Log ("msiexec exit code: {0}" -f $p.ExitCode)
exit $p.ExitCode
