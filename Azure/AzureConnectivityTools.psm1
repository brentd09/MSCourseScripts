function Test-AzConnection {
  [cmdletbinding()]
  Param (
    [Parameter(Mandatory=$true)]
    $ResourceGroupName ,
    [Parameter(Mandatory=$true)]
    $SourceVMName,
    [Parameter(Mandatory=$true)]
    $DestinationIPAddress,
    [Parameter(Mandatory=$true)]
    $DestinationPort
  )
  try {Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop | Out-Null}
  catch {
    Write-Warning "$ResourceGroupName cannot be located"
    break
  }
  try {
    $SrcVM = Get-AzVM -AzResourceGroupName $ResourceGroupName -ErrorAction Stop | Where-Object {$_.Name -eq $SourceVMName}
    $NetWatcher = Get-AzNetworkWatcher -ErrorAction Stop | Where-Object {$_.Location -eq $SrcVM.Location}
    Test-AzNetworkWatcherConnectivity -ErrorAction Stop -NetworkWatcher $NetWatcher -SourceId $SrcVM.Id -DestinationAddress $DestinationIPAddress -DestinationPort $DestinationPort
  }
  catch {
    Write-Warning "Either the VM or the NetWorkWatcher cannot be found"
    break
  }
}