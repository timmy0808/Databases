[CmdletBinding()]
param([switch]$Reset)

& "$PSScriptRoot\scripts\deploy.ps1" -Reset:$Reset
exit $LASTEXITCODE
