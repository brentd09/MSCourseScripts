function Get-AzNicToVM {
  [cmdletbinding()]
  param ()

  try {
    $AllNics = Get-AzNetworkInterface -ErrorAction Stop
    $AllVms  = get-AzVM -ErrorAction Stop
  }
  catch {
    Write-Warning 'There was an error getting the interfaces or VMs'
    break
  }
  if ($AllVms) {
    foreach ($Nic in $AllNics) {
      if ($Nic.VirtualMachine) {
        $AttatchedVM = ($Nic.VirtualMachine.id -split '/')[-1]
      }
      else {
        $AttatchedVM = 'Unassigned'
      }
      [PSCustomObject][ordered]@{
        VM = $AttatchedVM
        NIC = $Nic.Name
        Location = $Nic.Location
        ResourceGroup = $Nic.ResourceGroupName
      } # Output object
    } # foreach
  } # if vms
} # function
