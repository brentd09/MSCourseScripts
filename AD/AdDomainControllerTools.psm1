function Get-ADConfigurationLevel {
  <#
  .SYNOPSIS
    Determine SYSVOL replication type
  .DESCRIPTION
    Determines whether the SYSVOL replication is via FRS or DFS-R. The FRS replication
    is a very old technology and was in place from Windows 2000 up until the end of 
    Windows server 2003. Domain Controllers that were in-place upgraded will still be 
    using FRS unless the DFS migration was undertaken 
  .EXAMPLE
    Get-ADConfigurationLevel -ComputerName 'LON-DC1' -Domain 'adatum.com'
    This will check for the the domain adatum.com by communicating with the DC LON-DC1
    to determine which type of SYSVOL replication is being used.
  .PARAMETER ComputerName
    This directs the command to communicate with this computer which will be a domain
    controller withing the domain that is being checked.
  .PARAMETER Domain
    This is the DNS name of the domain that is being checked
  .NOTES
    General notes
      Created By:    Brent Denny 
      Created On:    29 Sep 2021
      Last Modified: 29 Sep 2021
      Change log:
        290921 - Created this script based on a question in class
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$ComputerName,
    [Parameter(Mandatory=$true)]
    [string]$DNSDomainName 
  )
  Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    $FrsSysvolString = "CN=Domain System Volume (SYSVOL share),CN=File Replication Service,CN=System,$((Get-ADDomain $DNSDomainName).DistinguishedName)"
    $DfsrSysvolString = "CN=Domain System Volume,CN=DFSR-GlobalSettings,CN=System,$((Get-ADDomain $DNSDomainName).DistinguishedName)"
    $FRSStatus = Get-ADObject -Filter { distinguishedName -eq $FrsSysvolString }
    $DFSRStatus = Get-ADObject -Filter { distinguishedName -eq $DfsrSysvolString } 
    $DomainFL = Get-Domain -Identity $DNSDomainName
    $ForestFL = Get-Forest 
    if ($FRSStatus) { $SysVolRep = 'FRS'}
    elseif ($DFSRStatus) { $SysVolRep = 'DFS-R' }
    else { $SysVolRep = 'undetermined' }
  }
  $ObjProp = [ordered]@{
    Domain = $DNSDomainName
    DomainFuctionalLevel = $DomainFL.DomainMode
    ForestFuctionalLevel = $ForestFL.ForestMode
    SysvolReplication = $SysVolRep
  }
  return (New-Object -TypeName psobject -Property $ObjProp)
}