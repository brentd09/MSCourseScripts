function Get-AzAsgToVMMapping {
  [CmdletBinding()]
  Param ()

  try {Connect-AzAccount -ErrorAction Stop}
  catch {Write-Warning "Please download the AZ module from PowerShell Gallery before running this again"; break}

  $AllASGs = Get-AzApplicationSecurityGroup
  $AllAzNics = Get-AzNetworkInterface
  $AllAzNics | Select-Object Name,@{n='VM';e={$_.VirtualMachine.ID}},@{n='ASG';e={$_.IpConfigurations.ApplicationSecurityGroups.ID}} 
}

function Get-AzAsgMembership {
  [CmdletBinding()]
  Param ()  
  
  try {Connect-AzAccount -ErrorAction Stop}
  catch {Write-Warning "Please download the AZ module from PowerShell Gallery before running this again"; break}
  $AzNics = Get-AzNetworkInterface
  $VMs    = Get-AzVM
  $ASGs   = Get-AzApplicationSecurityGroup 
  foreach ($ASG in $ASGs) {
    $MatchingNics = $AzNics | Where-Object {($_.IpConfigurations.ApplicationSecurityGroupsText | ConvertFrom-Json).ID -eq $ASG.Id}
    foreach ($MatchingNic in $MatchingNics) {
      $MatchingVM = $VMs | Where-Object {$_.NetworkProfile.NetworkInterfaces.Id -contains $MatchingNic.Id} 
      if ($MatchingVM) {
        [PSCustomObject]@{
          ASG = $ASG.Name
          VM  = $MatchingVM.Name
          NIC = $MatchingNic.Name
        }
      } 
    } 
  }
}
