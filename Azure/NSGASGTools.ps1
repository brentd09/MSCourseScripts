function Get-AzAsgToVMMapping {
  [CmdletBinding()]
  Param ()

  try {Connect-AzAccount -ErrorAction Stop *> $null}
  catch {Write-Warning "Please download the AZ module from PowerShell Gallery before running this again";break}

  $AllAzNics = Get-AzNetworkInterface
  $AsgToNic = $AllAzNics | Select-Object @{n='ASG';e={($_.IpConfigurations.ApplicationSecurityGroups.ID -split '\/')[-1] -as [string]}},
                                         @{n='NicName';e={$_.Name -as [string]}},
                                         @{n='VM';e={($_.VirtualMachine.ID -split '\/')[-1] -as [string]}}

  return $AsgToNic
}

function Get-AsgUsage {
  [cmdletbinding()]
  Param ()

  $AllNsgs = Get-AzNetworkSecurityGroup
  return $AllNsgs | Select-Object -Property Name, 
                                                @{n='AsgAsSrc';e={($_.SecurityRules.SourceApplicationSecurityGroups.ID -split '\/')[-1]}},
                                                @{n='AsgAsDst';e={($_.SecurityRules.DestinationApplicationSecurityGroups.ID -split '\/')[-1]}}
} 

Get-AsgUsage