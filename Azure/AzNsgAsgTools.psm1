function Get-AzAsgToVMMapping {
  [CmdletBinding()]
  Param ()

  try {Get-AzSubscription -ErrorAction Stop *> $null}
  catch {  
    try {Connect-AzAccount -ErrorAction Stop *> $null}
    catch {Write-Warning "Please download the AZ module from PowerShell Gallery before running this again"; break}
  }
  
  $AllASGs = Get-AzApplicationSecurityGroup
  $AllAzNics = Get-AzNetworkInterface
  $AllAzNics | Select-Object Name,@{n='VM';e={$_.VirtualMachine.ID}},@{n='ASG';e={$_.IpConfigurations.ApplicationSecurityGroups.ID}} 
}

function Get-AzAsgMembership {
  <#
  .SYNOPSIS
    This lists the computers and their NICs that are in an ASG
  .DESCRIPTION
    Listing an ASG membership is difficult, the only way via the GUI is to visit each computer and
    check to see if it is a member of an ASG, if you had 100's of VMs this would be impractical.
  .NOTES
    Created By: Brent Denny
    Created On: 7-Nov-2023
  .EXAMPLE
    Get-AzAsgMembership 
    This command will list all of the ASGs and any VM that is a member of each ASG along with their NIC
  #>
  
  
  [CmdletBinding()]
  Param ()  
  
  try {Get-AzSubscription -ErrorAction Stop *> $null}
  catch {  
    try {Connect-AzAccount -ErrorAction Stop *> $null}
    catch {Write-Warning "Please download the AZ module from PowerShell Gallery before running this again"; break}
  }  
  
  $AzNics = Get-AzNetworkInterface
  $VMs    = Get-AzVM
  $ASGs   = Get-AzApplicationSecurityGroup 
  foreach ($ASG in $ASGs) {
    $MatchingNics = $AzNics | Where-Object {($_.IpConfigurations.ApplicationSecurityGroupsText | ConvertFrom-Json).ID -eq $ASG.Id}
    foreach ($MatchingNic in $MatchingNics) {
      $MatchingVM = $VMs | Where-Object {$_.NetworkProfile.NetworkInterfaces.Id -contains $MatchingNic.Id} 
      if ($MatchingVM) {
        [PSCustomObject][Ordered]@{
          ASG = $ASG.Name
          VM  = $MatchingVM.Name
          NIC = $MatchingNic.Name
        }
      } 
    } 
  }
}
