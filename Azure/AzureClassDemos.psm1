function Initialize-DemoResGrp {
  $Loc = 'EastUS'
  $ResGrpName = demoresgroup  
  New-AzResourceGroup -Name $ResGrpName -Location $Loc 
}
function Initialize-DemoVNetPair {
  $Loc = 'EastUS'
  $ResGrpName = demoresgroup
  $Net1 = [ordered]@{
    VNetName   = 'vnet1'
    VnetCIDR   = '10.2.0.0/16'
    SubnetName = 'subnet1'
    SubnetCIDR = '10.2.0.0/24'
  }
  
  $Net2 = [ordered]@{
    VNetName   = 'vnet2'
    VnetCIDR   = '12.3.0.0/16'
    SubnetName = 'subnet2'
    SubnetCIDR = '12.3.0.0/24'
  }
  
  $ResGroupFound = Get-AzResourceGroup -Name $ResGrpName
  if ($ResGroupFound.Count -ne 1) {Initialize-DemoResGrp}

  $Subnet1 = New-AzVirtualNetworkSubnetConfig -Name $Net1.SubnetName -AddressPrefix $Net1.SubnetCIDR 
  $Subnet2 = New-AzVirtualNetworkSubnetConfig -Name $Net2.SubnetName -AddressPrefix $Net2.SubnetCIDR 
  New-AzVirtualNetwork -Name $Net1.VNetName -ResourceGroupName $ResGrpName -Location $Loc -AddressPrefix $Net1.VnetCIDR -Subnet $Subnet1
  New-AzVirtualNetwork -Name $Net2.VNetName -ResourceGroupName $ResGrpName -Location $Loc -AddressPrefix $Net2.VnetCIDR -Subnet $Subnet2
}

function Initialize-DemoVMPair {
  
}