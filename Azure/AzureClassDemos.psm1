function Initialize-DemoVMPair {

  $ResourceGroup = "demoresgroup"
  $Location = "EastUS"
  $vmName = "myVM"
  $VMs = @( 
    @{
      Name = 'demovm1'
      VNet = 'vnet1'
      Subnet = 'subnet1'
      SecurityGroup = 'secgrp1'
      PublicIP = 'publicip1'
      VNetPrefix  = '10.5.0.0/16'
      SubnetPrefix = '10.5.0.0/24'
    } , 
    @{
      Name = 'demovm2'
      VNet = 'vnet2'
      Subnet = 'subnet2'
      SecurityGroup = 'secgrp2'
      PublicIP = 'publicip2'
      VNetPrefix  = '100.50.0.0/16'
      SubnetPrefix = '100.50.0.0/24'  
    }
  )
  $Cred = Get-Credential -Message "Enter a username and password for the virtual machine."
  New-AzResourceGroup -Name $ResourceGroup -Location $Location
  foreach ($VM in $VMs) {
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $VM.Subnet -AddressPrefix $VM.SubnetPrefix
    $vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Location $Location -Name $VM.VNet -AddressPrefix $VM.VNetPrefix -Subnet $subnetConfig
    $pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroup -Location $Location -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4
    $nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $Location -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP
    $nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D1 | 
      Set-AzVMOperatingSystem -Windows -ComputerName $VM.Name -Credential $cred | 
      Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus '2016-Datacenter' -Version latest | 
      Add-AzVMNetworkInterface -Id $nic.Id
    New-AzVM -ResourceGroupName $ResourceGroup -Location $Location -VM $vmConfig
  }  
}   