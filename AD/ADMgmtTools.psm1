function Get-ADFsmoMasters {
  <#
  .Synopsis
    Retrieves the FSMO Role holders
  .DESCRIPTION
    This command get the FSMO role owners from AD relative to the domain
    controller the script is directed to. If no ADDC is chosen the default
    if the current computer the script is run on.
  .EXAMPLE
    Get-ADFsmoMasters
  .EXAMPLE
    Get-ADFsmoMasters -DomainController dc1.company.com
  .PARAMETER DomainController
    Points the script to a domain controller
  .NOTES
    General notes
    Created By  : Brent Denny
    Date Created: 30-May-2018
  #>
  Param (
    [string]$DomainController = [system.net.dns]::GetHostByName($env:COMPUTERNAME)
  )
  # Query with the current credentials
  try {
    $ForestInfo = Get-ADForest -Server $DomainController -ErrorAction Stop
    $DomainInfo = Get-ADDomain -Server $DomainController -ErrorAction Stop
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