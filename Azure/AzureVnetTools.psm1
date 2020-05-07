function Get-AzPeeringTypes {
  <#
  .SYNOPSIS
    Lists all of Virtual Networks in Azure and determines their type
  .DESCRIPTION
    This cmdlet finds all of the Vnets that have peerings and determines 
    if the peering is a global or regional type of peering. There are 
    restrictions on what you can do with a global peering and so it is 
    important to know which peering is what type  
  .EXAMPLE
    Get-AzPeeringType
    This expects that you have already signed into Azure using 
    Connect-AzAccount it will then find all of the VNets that have 
    peerings and determine each type
  .EXAMPLE
    Get-AzPeeringType -PeeringFilter Global
    This will show peerings of a Global type   
  .EXAMPLE
    Get-AzPeeringType -PeeringFilter NoPeering
    This will show VNets that do not have any peering configured       
  .PARAMETER PeeringFilter
    This will filter the peerings so that either a single peering type
    is shown or all are shown. The values for the PeeringFilter are:
    Regional - Shows only Regional
    Global - Shows only Global
    All - Shows all types of peering
    NoPeering - Shows only VNets with no peerings 
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 6 May 2020
  #>
  [cmdletbinding()]
  Param(
    [ValidateSet('Regional','Global','All','NoPeering')]
    [string]$PeeringFilter = 'All'
  )
  try {
    $VNets = Get-AzVirtualNetwork -ErrorAction Stop
    foreach ($VNet in $VNets){
      if ($VNet.VirtualNetworkPeerings.Count -ge 1) {
        $Peerings = $VNet.VirtualNetworkPeerings
        foreach ($Peering in $Peerings) {
          $PeerName = $Peering.remotevirtualnetwork.id -replace '.+\/(.+)$','$1'
          $PeerID = $Peering.remotevirtualnetwork.Id
          $PeerVNetInfo = $VNets | Where-Object {$_.Id -eq $PeerID}
          $PeerVNetLocation = $PeerVNetInfo.Location
          if ($VNet.Location -eq $PeerVNetLocation) {$PeerType = 'Regional'}
          else {$PeerType = 'Global'}
          $Hash = [ordered]@{
            VNetName = $VNet.Name
            VnetLocation = $VNet.Location
            PeeredVNet = $PeerName
            PeerVNetLocation = $PeerVNetLocation
            PeerType = $PeerType
            VNetID = $VNet.Id
          }
          if ($PeeringFilter -eq $PeerType -or $PeeringFilter -eq 'All') {
            New-Object -TypeName psobject -Property $Hash   
          }
        }
      }
      else {
        $Hash = [ordered]@{
          VNetName = $VNet.Name
          VnetLocation = $VNet.Location
          PeeredVNet = 'No Peerings'
          PeerVNetLocation = 'N/A'
          PeerType = 'N/A'
          VNetID = $VNet.Id
        }
        if ($PeeringFilter -eq 'NoPeering' -or $PeeringFilter -eq 'All') {
          New-Object -TypeName psobject -Property $Hash    
        }       
      }  
    }
  }  
  catch { Write-Warning 'An error occured trying to access the Virtual Networks'}
}