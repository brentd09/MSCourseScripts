function New-AZDemoVMs {
  <#
  .SYNOPSIS
    This creates Three Azure VMs, two in one VNet and another in a seperate VNet
  .DESCRIPTION
    I Azure this will create by default 1 VM in one VNet and 2 other VMs in another
    VNet the 2 VMs in the second VNet will also be created in two subnets within the 
    Vnet
  .EXAMPLE
    New-AZDemoVMs 
    This creates all of the infrastructure to support two Azure VMs in
    two different VNets
  .EXAMPLE
    New-AZDemoVMs -ResourceGroup Resgrpname -Location EastUS -VMs @{
        Name = 'demovm1'
        NICName = 'NIC1'
        VNet = 'vnet1'
        Subnet = 'subnet1'
        SecurityGroup = 'secgrp1'
        NSGName = 'myNetworkSecurityGroupRuleRDP1'
        PublicIP = 'publicip1'
        VNetPrefix  = '10.5.0.0/16'
        SubnetPrefix = '10.5.0.0/24'
      }
    This creates all of the infrastructure to support the VM shown in
    the vnet1 VNet, as seen here the resource group name, the location
    and the VM information in a hash table can be presented as paramters to
    set your own values, make sure all of the VM information is in the hash
    table. The VMs parameter can also take an array of hastables if more than
    on VM is required.
  .PARAMETER ResourceGroup
    This is the name of the resource group that the demo resources will 
    be created in
  .PARAMETER Location
    This is the location code to create the resources in
  .PARAMETER VMs
    This is a hash table of names of resources that relate to the VM, this 
    can take an array of hash tables to create more than one VM. 
    The Format of these hash tables look like this:
      @{
        Name = 'demovm1'
        NICName = 'NIC1'
        VNet = 'vnet1'
        Subnet = 'subnet1'
        SecurityGroup = 'secgrp1'
        NSGName = 'myNetworkSecurityGroupRuleRDP1'
        PublicIP = 'publicip1'
        VNetPrefix  = '10.5.0.0/16'
        SubnetPrefix = '10.5.0.0/24'
      } , 
      @{
        Name = 'demovm2'
        NICName = 'NIC2'
        VNet = 'vnet2'
        Subnet = 'subnet2'
        SecurityGroup = 'secgrp2'
        NSGName = 'myNetworkSecurityGroupRuleRDP2'
        PublicIP = 'publicip2'
        VNetPrefix  = '100.50.0.0/16'
        SubnetPrefix = '100.50.0.0/24'  
      }
  .NOTES
    General notes
      Created by:   Brent Denny
      Created on:   30 Jan 2020 (Creating 2 VMs)
      Modified on:  25 Feb 2020 (creating 3 VMs)
  #>
  [Cmdletbinding()]
  Param (
    [string]$ResourceGroup = "demoresgroup",
    [string]$Location = "EastUS",
    [pscredential]$Cred = (Get-Credential -Message "Enter a username and password for the virtual machine."),
    [hashtable[]]$VMs = @( 
      @{
        Name = 'demovm1'
        NICName = 'NIC1'
        VNet = 'vnet1'
        Subnet = 'subnet1'
        SecurityGroup = 'secgrp1'
        NSGName = 'myNetworkSecurityGroupRuleRDP1'
        PublicIP = 'publicip1'
        VNetPrefix  = '10.5.0.0/16'
        SubnetPrefix = '10.5.0.0/24'
      } , 
      @{
        Name = 'demovm2'
        NICName = 'NIC2'
        VNet = 'vnet2'
        Subnet = 'subnet2'
        SecurityGroup = 'secgrp2'
        NSGName = 'myNetworkSecurityGroupRuleRDP2'
        PublicIP = 'publicip2'
        VNetPrefix  = '100.50.0.0/16'
        SubnetPrefix = '100.50.0.0/24'  
      },
      @{
        Name = 'demovm3'
        NICName = 'NIC3'
        VNet = 'vnet2'
        Subnet = 'subnet3'
        SecurityGroup = 'secgrp3'
        NSGName = 'myNetworkSecurityGroupRuleRDP3'
        PublicIP = 'publicip3'
        VNetPrefix  = '100.50.0.0/16'
        SubnetPrefix = '100.50.1.0/24'  
      }
    )
  )

  Clear-Host
  $CurrentResGrps = Get-AzResourceGroup
  Write-Progress -Activity "Creating Azure resources" -Status "Starting the build" -PercentComplete 0 
  if ($ResourceGroup -notin $CurrentResGrps.ResourceGroupName) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location > $null
  }
  foreach ($VM in $VMs) {
    $WarningPreference = 'SilentlyContinue'
    $ErrorActionPreference = 'SilentlyContinue'
    try {
      $CurrentVnets = Get-AzVirtualNetwork
      if ($VM.Vnet -notin $CurrentVnets.Name) {
        Write-Progress -Activity "Creating Azure resources - $($VM.Name)" -Status "Creating VNet and Subnet" -PercentComplete 15  
        $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $VM.Subnet -AddressPrefix $VM.SubnetPrefix -ErrorAction stop
        $VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Location $Location -Name $VM.VNet -AddressPrefix $VM.VNetPrefix -Subnet $subnetConfig  -ErrorAction stop
        Write-Progress -Activity "Creating Azure resources - $($VM.Name)" -Status "Creating Public IP" -PercentComplete 30
      }
      if ($VM.SubnetPrefix -notin $CurrentVnets.Subnets.AddressPrefix) {
        $VNetToModify = Get-AzVirtualNetwork -Name $VM.VNet
        Add-AzVirtualNetworkSubnetConfig -Name $VM.subnet -VirtualNetwork $VNetToModify -AddressPrefix $VM.SubnetPrefix 
        Set-AzVirtualNetwork -VirtualNetwork $VNetToModify
      }
      $PubIp = New-AzPublicIpAddress -ResourceGroupName $ResourceGroup -Location $Location -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4  -ErrorAction stop
      Write-Progress -Activity "Creating Azure resources - $($VM.Name)" -Status "Creating NSG" -PercentComplete 45
      $NSGRuleRDP = New-AzNetworkSecurityRuleConfig -Name $VM.NSGName  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow  -ErrorAction stop
      $NSG = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $Location -Name $VM.SecurityGroup -SecurityRules $NSGRuleRDP  -ErrorAction stop
      Write-Progress -Activity "Creating Azure resources - $($VM.Name)" -Status "Creating NIC" -PercentComplete 60  
      $NIC = New-AzNetworkInterface -Name $VM.NICName -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PubIp.Id -NetworkSecurityGroupId $NSG.Id  -ErrorAction stop
      $VMConfig = New-AzVMConfig -VMName $VM.Name -VMSize Standard_D1  -ErrorAction stop  | 
        Set-AzVMOperatingSystem -Windows -ComputerName $VM.Name -Credential $Cred -ErrorAction stop | 
        Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus '2016-Datacenter' -Version latest -ErrorAction stop | 
        Add-AzVMNetworkInterface -Id $NIC.Id  -ErrorAction stop
      Write-Progress -Activity "Creating Azure resources - $($VM.Name)" -Status "Creating VM" -PercentComplete 75 
      New-AzVM -ResourceGroupName $ResourceGroup -Location $Location -VM $VMConfig -ErrorAction stop
      Write-Progress -Activity "Creating Azure resources - $($VM.Name)" -Status "Creating VM" -PercentComplete 100 -Completed
    }
    catch {
      $WarningPreference = 'Continue'
      Write-Warning 'Please check resourses, some may not have been created '
    }
  }  
}   