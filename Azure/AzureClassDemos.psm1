function Initialize-DemoResGrp {
  $Loc = 'EastUS'
  $ResGrpName = 'demoresgroup'
  New-AzResourceGroup -Name $ResGrpName -Location $Loc 
}
function Initialize-DemoVNetPair {
  $Loc = 'EastUS'
  $ResGrpName = 'demoresgroup'
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
  $Loc = 'EastUS'
  $ResGrpName = 'demoresgroup'
  $VM1 = @{
    Name = 'demovm1'
    VNet = 'vnet1'
    Subnet = 'subnet1'
    SecurityGroup = 'secgrp1'
    PublicIP = 'publicip1'
  }  
  $VM2 = @{
    Name = 'demovm2'
    VNet = 'vnet2'
    Subnet = 'subnet2'
    SecurityGroup = 'secgrp2'
    PublicIP = 'publicip2'
  }

  $cred = Get-Credential
  $vmInfo1 = New-AzVMConfig -VMName $VM1.Name -VMSize Standard_D1
  $vmInfo1 = Set-AzVMOperatingSystem -VM $VMInfo1 -Windows -ComputerName $VM1.Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate 
  $vmInfo1 = Set-AzVMSourceImage -VM $VMInfo1 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus '2016-Datacenter' -Version latest
  New-AzVm -ResourceGroupName $ResGrpName -Name $VM1.Name -Location $Loc -VirtualNetworkName $VM1.VNet -SubnetName $VM1.Subnet -SecurityGroupName $VM1.SecurityGroup -PublicIpAddressName $VM1.PublicIP -OpenPorts 80,3389

  $vmInfo2 = New-AzVMConfig -VMName $VM2.Name -VMSize Standard_D1
  $vmInfo2 = Set-AzVMOperatingSystem -VM $VMInfo2 -Windows -ComputerName $VM2.Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate 
  $vmInfo2 = Set-AzVMSourceImage -VM $VMInfo2 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus '2016-Datacenter' -Version latest
  New-AzVm -ResourceGroupName $ResGrpName -Name $VM2.Name -Location $Loc -VirtualNetworkName $VM2.VNet -SubnetName $VM2.Subnet -SecurityGroupName $VM2.SecurityGroup -PublicIpAddressName $VM2.PublicIP -OpenPorts 80,3389
}