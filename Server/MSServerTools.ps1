function Get-ComputerUptime {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$StartingIP,
    [Parameter(Mandatory=$true)]
    [string]$EndingIP
  )
  function Convert-ValueToIP {
    Param([int64]$IPAddressVal)
    [ipaddress]$TempIPObj = '1.1.1.1'
    $TempIPObj.Address = $IPAddressVal
    [System.Collections.ArrayList]$SplitAddress = ($TempIPObj.IPAddressToString) -split '\.'
    $SplitAddress.reverse()
    New-Object -TypeName psobject -Property @{IPAddress=$SplitAddress -join '.'}
  } 
  function Convert-IPToValue {
    Param([string]$IPAddress)
    ([System.Collections.ArrayList]$RevIPArray = ($IPAddress -split '\.')).reverse()
    [ipaddress]$IPObj = $RevIPArray -join '.'
    $IPObj | Select-Object -Property Address
  }

  









  #$today = Get-Date
  #foreach ($CompIP in (10..20)) {
  #  $Ip = '172.16.0.' + $CompIP
  #  try {$ComputerInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Ip -ErrorAction stop}
  #  catch {}
  #  $sinceboot = $today - $computerInfo.LastBootUpTime
  #  $obj = @{
  #    ComputerName = $ComputerInfo.Name
  #    Uptime = $sinceboot.TotalDays 
  #  }
  #  New-Object -TypeName psobject -Property $obj
  #}
}  

Get-ComputerUptime -StartingIP '192.168.10.1' -EndingIP '192.168.10.5'
