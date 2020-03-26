function Get-AZSku {
  <#
  .SYNOPSIS
    This finds what resources can be created in what region
  .DESCRIPTION
    The free and sponsered azure account can be limited to the types of 
    resources that can be created. This command will show what compute 
    type resources are available per region
  .PARAMETER type
    You can search for the following types of resources using the type parameter
    availabilitySets
    disks
    hostGroups/hosts
    snapshots
    virtualMachines (this is the default)
  .EXAMPLE
    Get-AZSku
    This will by default show virtual machine resources sizes per region 
    and this may assist us in picking regions that support the sizes required 
    by the labs
  .EXAMPLE
    Get-AZSku -Type disks
    This will by default show disk resources  per region and this may assist
    us in picking regions that support the disks required by the labs    
  .NOTES
    General notes
    Created By: Brent Denny
    Created On: 26-Mar-2020
  #>
  Param (
    [ValidateSet('availabilitySets','disks','hostGroups/hosts','snapshots','virtualMachines')]
    [string]$Type = "virtualMachines"
  )
  try {$AzSub = Get-AzSubscription -ErrorAction stop}
  catch {Connect-AzAccount}
  $AzAccount = Get-AzSubscription -ErrorAction SilentlyContinue
  if ($AzAccount) {
    Write-Progress -Activity "Retrieving the list of resources requested... Please wait" 
    $allSku = Get-AzComputeResourceSku
    Write-Progress -Activity "Retrieving the list of resources requested... Please wait" -Completed
    $noRestrictionsSku = $allSku | Where-Object {$_.ResourceType -eq $type -and -not $_.Restrictions}
    $availableSkuSummary = $noRestrictionsSku | Select-Object ResourceType,@{n='Location';e={$_.Locations}},@{n='Name';e={$_.Name}} 
    $availableSkuSummary
  }
  else {Write-Warning 'Please use: Connect-AzAccount to login to Azure, your logon attempt failed'}  
}