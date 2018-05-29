function Get-ADFsmoMasters {
  Param (
    [string]$DomainController = [system.net.dns]::GetHostByName($env:COMPUTERNAME)
  )
  # Query with the current credentials
    $ForestInfo = Get-ADForest -Server $DomainController
    $DomainInfo = Get-ADDomain -Server $DomainController
  
  # Define Properties
  $NewObjProp = [ordered]@{
    SchemaMaster = $ForestInfo.SchemaMaster
    DomainNamingMaster = $ForestInfo.DomainNamingMaster
    InfraStructureMaster = $DomainInfo.InfraStructureMaster
    RIDMaster = $DomainInfo.RIDMaster
    PDCEmulator = $DomainInfo.PDCEmulator
  }
  
  New-Object -TypeName PSObject -Property $NewObjProp
}