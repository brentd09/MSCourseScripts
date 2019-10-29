function Get-ComputerUptime {
  <#
  .SYNOPSIS
    Looks for computers in the IP range and reports on Uptime (in Days)
  .DESCRIPTION
    By supplying parameters to show the start and end of an IP range the
    command will test for each hosts existence and if found will report its 
    Name, Uptime (in Days), IP address and Operating System
  .EXAMPLE
    Get-ComputerUpTime -StartingIP 172.16.0.10  -EndingIP 172.16.0.90
    This will scan the entire range of IP addresses for computers and
    then report the computers information including UpTime (in Days).
  .EXAMPLE
    Get-ComputerUpTime -StartingIP 172.16.0.10  -EndingIP 172.16.0.90 -Protocol WSMAN
    This will scan the entire range of IP addresses for computers using
    the WSMAN protocol instead of the default, which for this command is DCOM,
    and will then report the computers information including UpTime (in Days).    
  .PARAMETER StartingIP
    This is the first IP of the range
  .PARAMETER EndingIP
    This is the last IP of the range, make sure the ending IP address is larger 
    than the starting IP address 
  .PARAMETER Protocol
    This command uses CIM to query the computers, to make it more adaptable 
    this parameter was added to allow the CIM Session to use DCOM or WSMAN
    The default in this case is DCOM.  
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 28 Oct 2019
      Modified on: 29 Oct 2019
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$StartingIP,
    [Parameter(Mandatory=$true)]
    [string]$EndingIP,
    [ValidateSet('DCOM','WSMAN')]
    [string]$Protocol = 'DCOM'
  )
  function Approve-IP {
    Param($IP)
    if ($IP -match '^(1[0-9]?[0-9]?|2[0-1][0-9]|22[0-3]|[1-9][0-9])\.((1[0-9]?[0-9]?|[0-9][0-9]?|2[0-1][0-9]|2[2-5][0-5]|[1-9][0-9])\.){2}(1[0-9]?[0-9]?|[0-9][0-9]?|2[0-1][0-9]|2[2-5][0-5]|[1-9][0-9])$') {
      return $true
    }
    else {return $false}
  }
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
    [System.Collections.ArrayList]$RevIPArray = $IPAddress -split '\.'
    $RevIPArray.Reverse()
    [ipaddress]$IPObj = $RevIPArray -join '.'
    $IPObj | Select-Object -Property @{n='RevIPValue';e={$_.Address}}
  }
  $IPGood = $false
  if ((Approve-IP -IP $StartingIP) -and (Approve-IP -IP $EndingIP)) {$IPGood = $true}
  if ($IPGood -eq $true) {
    [string[]]$PossibleIPArray = @()
    $StartVal = (Convert-IPToValue -IPAddress $StartingIP).RevIPValue
    $EndVal = (Convert-IPToValue -IPAddress $EndingIP).RevIPValue
    if ($StartVal -gt $EndVal) {
      Write-Warning "The last IP address is before the first IP Address"
      break
    }
    $Today = Get-Date
    for ($IPVal=$StartVal;$IPVal -le $EndVal;$IPVal++) {
      $ConvertedIPAddress = (Convert-ValueToIP -IPAddressVal $IPVal).IPAddress
      $PossibleIPArray += $ConvertedIPAddress
    }  
    $IPCurrentCount = 0
    foreach ($IPAddress in $PossibleIPArray) {
      $IPCurrentCount++
      $IPTotal = $PossibleIPArray.Count
      Write-Progress -Activity "Detecting the computer within the IP range $StartingIP - $EndingIP" -PercentComplete ($IPCurrentCount/$IPTotal*100) -CurrentOperation "Detecting $IPAddress"
      if (Test-Connection -ComputerName $IPAddress -Quiet -Count 1) {
        $CimOpt = New-CimSessionOption -Protocol w
        $CimSession = New-CimSession -ComputerName $IPAddress -SessionOption $CimOpt
        $OSInfo = Get-CimInstance -ClassName  Win32_OperatingSystem -CimSession $CimSession 2> $null   
        $UPtimeObj = $Today - $OSInfo.LastBootUpTime
        $ReportProp = [ordered]@{
          ComputerName = $OSInfo.CSName
          IPAddress = $IPAddress
          Uptime = [math]::Round($UPtimeObj.TotalDays,3) 
          OSVersion = $OSInfo.Caption
        }
        $Report =  New-Object -TypeName psobject -Property $ReportProp
        $Report
      }
    }
  }
  else {Write-warning "One or more of the IP addresses entered were not valid"}
}  
