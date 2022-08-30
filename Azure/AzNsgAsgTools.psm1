function Get-AzAsgToVMMapping {
  [CmdletBinding()]
  Param ()

  try {Connect-AzAccount -ErrorAction Stop}
  catch {Write-Warning "Please download the AZ module from PowerShell Gallery before running this again";break}

  $AllASGs = Get-AzApplicationSecurityGroup
  $AllAzNics = Get-AzNetworkInterface
  $AllAzNics | Select-Object Name,@{n='VM';e={$_.VirtualMachine.ID}},@{n='ASG';e={$_.IpConfigurations.ApplicationSecurityGroups.ID}} 
}