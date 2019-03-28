<#
  Functions in this module
    Get-ADFsmoMasters
#>
function Get-ADFsmoMasters {
  <#
  .Synopsis
    Retrieves the FSMO Role holders
  .DESCRIPTION
    This command get the FSMO role owners from AD relative to the domain
    controller the script is directed to. If no ADDC is chosen the default
    if the current computer the script is run on. This also accepts the 
    NETBIOS name of the domain controller and will translate it into 
    the FQDN. 
  .EXAMPLE
    Get-ADFsmoMasters
  .EXAMPLE
    Get-ADFsmoMasters -DomainController dc1.company.com
  .PARAMETER DomainController
    Points the script to a domain controller this could either be the FQDN 
    or the NETBIOS name both will work as long as DNS can resolve this name 
    to the FQDN.
  .NOTES
    General notes
    Created By  : Brent Denny
    Date Created: 30-May-2018
  #>
  Param (
    [string]$DomainController = ([system.net.dns]::GetHostByName($env:COMPUTERNAME)).HostName
    
  )
  # Query with the current credentials
  try {
    $DomainController = ([system.net.dns]::GetHostByName($DomainController)).HostName
    $ErrorActionPreference = "Stop"
    $Ldap = '_ldap._tcp.' + $env:USERDNSDOMAIN
    $DnsAnswer = Resolve-DnsName -Type SRV $Ldap
    $DCs = $DnsAnswer.NameTarget
  }
  Catch {
    Write-Warning "There appears to be a problem, wrong name or DNS resolving issue"
    break
  }
  Finally {
    $ErrorActionPreference = "Continue"
  }
  if ($DomainController -notin $DCs) {
    Write-Warning "$DomainController is not a Domain Controller"
    break
  }
  try {
    $ForestInfo = Invoke-Command -ComputerName $DomainController -ScriptBlock {Get-ADForest} -ErrorAction Stop
    $DomainInfo = Invoke-Command -ComputerName $DomainController -ScriptBlock {Get-ADDomain} -ErrorAction Stop
  }
  catch {
    Write-Warning "The FSMO Role owners were not able to be determined"
    break
  }
  # Define Properties
  $NewObjProp = [ordered]@{
    SchemaMaster         = $ForestInfo.SchemaMaster
    DomainNamingMaster   = $ForestInfo.DomainNamingMaster
    InfraStructureMaster = $DomainInfo.InfraStructureMaster
    RIDMaster            = $DomainInfo.RIDMaster
    PDCEmulator          = $DomainInfo.PDCEmulator
  }
  New-Object -TypeName PSObject -Property $NewObjProp
}
