function Test-CMManagementPoint {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$ManagementPointFQDN
  )
  $URI = 'http://' + $ManagementPointFQDN + "/sms_mp/.sms_aut?mplist"
  try {
    $ErrorActionPreference = 'Stop'
    [xml]$MPResponse = Invoke-WebRequest -UseBasicParsing -Uri $URI 
    $MPResponse.mplist.mp | Select-Object -Property Name,@{n='BuildNumber';e={$_.Version}}
  }
  Catch {Write-Warning "There appear to be a problem communicating with $ManagementPointFQDN"}   
}