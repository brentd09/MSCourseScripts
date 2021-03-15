function Find-ValidSubnet {
  <#
  .SYNOPSIS
    Takes an IPv4 network address and creates subnets based on hosts and networks needed. 
  .DESCRIPTION
    This command calculates all possible subnet masks that will accommodate the required
    subnets and hosts/subnet. Once the masks are found it will then produce all of the possible
    subnet ranges per subnet mask. It also has the option to show only the smallest subnets in
    regard to hosts/subnet (largest CIDR mask). These is also an option to show all subnets and
    this is very useful when trying to plan for VLSM subnets.
    
    This is a basic example:

  Find-ValidSubnet -CIDRSubnetAddress 172.16.0.0/16 -SubnetsRequired 4 -HostsPerSubnetRequired 6000 | Format-Table -GroupBy Mask
  
     Mask: 18
  
  Mask SubnetID      FirstValidIP  LastValidIP     BroadcastIP     HostsPerSubnet Subnet TotalSubnets
  ---- --------      ------------  -----------     -----------     -------------- ------ ------------
    18 172.16.0.0   172.16.0.1   172.16.63.254  172.16.63.255           16382      1            4
    18 172.16.64.0  172.16.64.1  172.16.127.254 172.16.127.255          16382      2            4
    18 172.16.128.0 172.16.128.1 172.16.191.254 172.16.191.255          16382      3            4
    18 172.16.192.0 172.16.192.1 172.16.255.254 172.16.255.255          16382      4            4
  
     Mask: 19
  
  Mask SubnetID      FirstValidIP  LastValidIP     BroadcastIP     HostsPerSubnet Subnet TotalSubnets
  ---- --------      ------------  -----------     -----------     -------------- ------ ------------
    19 172.16.0.0   172.16.0.1   172.16.31.254  172.16.31.255            8190      1            8
    19 172.16.32.0  172.16.32.1  172.16.63.254  172.16.63.255            8190      2            8
    19 172.16.64.0  172.16.64.1  172.16.95.254  172.16.95.255            8190      3            8
    19 172.16.96.0  172.16.96.1  172.16.127.254 172.16.127.255           8190      4            8
    19 172.16.128.0 172.16.128.1 172.16.159.254 172.16.159.255           8190      5            8
    19 172.16.160.0 172.16.160.1 172.16.191.254 172.16.191.255           8190      6            8
    19 172.16.192.0 172.16.192.1 172.16.223.254 172.16.223.255           8190      7            8
    19 172.16.224.0 172.16.224.1 172.16.255.254 172.16.255.255           8190      8            8

    It will also make sure the original network address is a network address and if it is not it
    will AND the given address with the oiginal mask to find the network address. 
    It is suggested that the output be formated into a table with a -groupby Mask parameter. 
  .EXAMPLE
    Find-ValidSubnet -CIDRSubnetAddress 172.16.0.0/16 -SubnetsRequired 4 -HostsPerSubnetRequired 4000  | Format-Table -GroupBy Mask
    Using the 172.16.0.0/16 network as a base this will find all subnet masks that will allow
    for a minimum of 4 subnets, while still allowing 4000 hosts per subnet. The subnets willl be
    listed for each subnet mask discovered
  .EXAMPLE
    Find-ValidSubnet -CIDRSubnetAddress 192.168.20.0/24 -AllSubnetsVLSM | Format-Table -GroupBy Mask
    Using the 192.168.20.0/24 network as a base this will find all subnets that are possible, this is very
    handy when trying to plan VLSM subnets.
  .PARAMETER CIDRSubnetAddress
    This parameter requires the network address to be entered with the CIDR mask as well. 
    In this format 172.16.0.0/16
  .PARAMETER SubnetsRequired
    This parameter declares how many subnets the CIDR network will need to be broken into as a minimum.
    Because this is a minimum, this command will also look for all valid subnets as long as it still
    allows for the number of hosts per subnet, -HostsPerSubnetRequired parameter value.
  .PARAMETER HostsPerSubnetRequired
    This parameter dictates the minimum amount of hosts that are required per subnet.
  .PARAMETER SmallestSubnets
    This parameter only shows the smallest subnets, those with the bigest subnet mask.
  .PARAMETER AllSubnetsVLSM
    This parameter show all possible subnets which can be very handy when planning VLSM subnets.
  .NOTES
    General notes
      Created by:    Brent Denny
      Created on:    09 Mar 2021
      Last Modified: 16 Mar 2021
      Version:       0.9.3
  #>
  [cmdletbinding(DefaultParameterSetName='Default',PositionalBinding=$false)]
  Param (
    [Parameter(Mandatory=$true,ParameterSetName='VLSM')]
    [Parameter(Mandatory=$true,ParameterSetName='Subnet')]
    [string]$CIDRSubnetAddress,
    [Parameter(Mandatory=$true,ParameterSetName='Subnet')]
    [int]$SubnetsRequired,
    [Parameter(Mandatory=$true,ParameterSetName='Subnet')]
    [int]$HostsPerSubnetRequired,
    [Parameter(ParameterSetName='Subnet')]
    [switch]$SmallestSubnets,
    [Parameter(ParameterSetName='VLSM')]
    [switch]$AllSubnetsVLSM
  )

  function ConvertTo-IPAddressObject {
    [cmdletbinding(DefaultParameterSetName='Default')]
    Param (
      [int]$BitCount,
      [Parameter(ParameterSetName='IPAddress')]
      [string]$IPAddress,
      [Parameter(ParameterSetName='DecAddress')]
      [int64]$DecAddress
    )
    # this function will take a bit count, IPaddress or decimal address, and 
    # convert any of them into an object that contains a forward and reverse versions 
    # of the IPAddresses and their decimal values
    if ($PSCmdlet.ParameterSetName -eq 'Default') {
      $BinaryString = '1' * $BitCount + '0' * (32 - $BitCount)
      $IPObj = [ipaddress]([convert]::ToInt64($BinaryString,2))
      $FwdAddrIPObj = [ipaddress]($IPObj.IPAddressToString -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$4.$3.$2.$1')
      $RevAddrIPObj = $IPObj
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'IPAddress') {
      $FwdAddrIPObj = [ipaddress]$IPAddress
      $RevAddrIPObj = [ipaddress]($IPAddress -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$4.$3.$2.$1')
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'DecAddress') {
      $IPObj = [ipaddress]$DecAddress
      $FwdAddrIPObj = [ipaddress]($IPObj.IPAddressToString -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$4.$3.$2.$1')
      $RevAddrIPObj = $IPObj
    }
    $ObjProp = [ordered]@{
      FwdAddrIP = $FwdAddrIPObj.IPAddressToString
      FwdAddrDec = $FwdAddrIPObj.Address
      RevAddrIP = $RevAddrIPObj.IPAddressToString
      RevAddrDec = $RevAddrIPObj.Address 
    }
    New-object -TypeName psobject -Property $ObjProp
  }

  function Find-IPSubnetRange {
    [cmdletbinding()]
    Param (
      [string]$IPAddress,
      [int]$InitialMask,
      [int]$SubnetMask
    )
    # This function will find all of the valid subnets for a subnetted mask, and list the following
    # Mask,Subnet,FirstValidIP,LastValidIP,BroadcastIP,HostsPerSubnet and Subnet Number
    $MaxSubnetIndex = [math]::Pow(2,$SubnetMask - $InitialMask) - 1
    $JumpValue = [math]::Pow(2,8-$SubnetMask % 8)
    $JumpIndex = [math]::Truncate($SubnetMask / 8)
    if ($JumpValue -eq 256) {
      $JumpValue = 1
      $JumpIndex = $JumpIndex - 1
    }
    [int[]]$JumpIPArray = 0,0,0,0
    $JumpIPArray[$JumpIndex] = $JumpValue
    $JumpIPAddr = $JumpIPArray -join '.' 
    $JumpIPAddressSet = ConvertTo-IPAddressObject -IPAddress $JumpIPAddr
    $IPAddressSet = ConvertTo-IPAddressObject -IPAddress $IPAddress
    foreach ($SubnetIndex in (0..$MaxSubnetIndex)) {
      # The ...RevDec refers to the IP addresses decimal value, it 'turns out' that the 
      # [IPAddress] object reverses the decimal value of the IP, so by reversing the
      # reverse we get the actual decimal value. This is why you see this everywhere 
      # within this function
      $ThisSubnetRevDec = $IPAddressSet.RevAddrDec + ($SubnetIndex * $JumpIPAddressSet.RevAddrDec)
      $ThisSubnetSet = ConvertTo-IPAddressObject -DecAddress $ThisSubnetRevDec
      $FirstValidRevDec = $ThisSubnetRevDec + 1
      $LastValidRevDec  = $ThisSubnetRevDec + $JumpIPAddressSet.RevAddrDec - 2
      $BroadCastRevDec  = $ThisSubnetRevDec + $JumpIPAddressSet.RevAddrDec - 1
      $FirstValidSet = ConvertTo-IPAddressObject -DecAddress $FirstValidRevDec
      $LastValidSet = ConvertTo-IPAddressObject -DecAddress $LastValidRevDec
      $BroadCastSet = ConvertTo-IPAddressObject -DecAddress $BroadCastRevDec
      $ObjProp = [ordered]@{
        Mask           = $SubnetMask
        SubnetID       = $ThisSubnetSet.FwdAddrIP
        FirstValidIP   = $FirstValidSet.FwdAddrIP
        LastValidIP    = $LastValidSet.FwdAddrIP
        BroadcastIP    = $BroadCastSet.FwdAddrIP
        HostsPerSubnet = [math]::Pow(2,32 -$SubnetMask) - 2
        Subnet         = $SubnetIndex + 1
        TotalSubnets   = $MaxSubnetIndex + 1
      }
      New-Object -TypeName psobject -Property $ObjProp
    } 
  }

  ## MAIN Function BODY
  if ($AllSubnetsVLSM -eq $true) {
    $SubnetsRequired = 1
    $HostsPerSubnetRequired = 1
  }
  $CIDRParts    = $CIDRSubnetAddress -split '\/'
  $SubnetID     = $CIDRParts[0] -as [string]
  $InitialMask  = $CIDRParts[1] -as [int]
  $HostBitsRequired = [math]::Ceiling([math]::Log($HostsPerSubnetRequired+2)/[math]::log(2)) # +2 to cater for NetworkId and BroadcastID addresses
  $NetworkBitsRequired = [math]::Floor([math]::Log($SubnetsRequired)/[math]::log(2))
  $TotalBitsRequired = $InitialMask + $HostBitsRequired + $NetworkBitsRequired  
  # Make sure the given IP addres is an IP Address 
  if ($CIDRSubnetAddress -notmatch '^([1-9]|[1-9][0-9]|1[01][0-9]|12[0-6]|12[89]|1[3-9][0-9]|2[0-2][0-3])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}\/([2-9]|[12][0-9]|30)$') {
    write-warning "$CIDRSubnetAddress - is not a valid address please enter the address and mask, for example: 164.12.0.0/16"
    break
  }
  elseif ($TotalBitsRequired -gt 32) {
    Write-Warning "The solution you requested requires $TotalBitsRequired bits in the address, we only have 32 bits in IPv4"
    break
  }
  else { 
    $MaskSet   = ConvertTo-IPAddressObject -BitCount $InitialMask
    $SubnetSet = ConvertTo-IPAddressObject -IPAddress $SubnetID
    # ANDing the Network address with original mask to produce a real network address
    # this is just in case an address that was entered was a host address and 
    # not the network address.
    $NetBinAndMaskDec  = $SubnetSet.RevAddrDec -band $MaskSet.RevAddrDec
    # Fixed IP uses ANDing to make sure the subnet address is the actual address of the subnet and not a host address 
    # the subnet.
    $ActualNetworkAddrSet = ConvertTo-IPAddressObject -DecAddress $NetBinAndMaskDec
    $SubnetingBitsArray = 0..(32 - $TotalBitsRequired ) | ForEach-Object {
      # Finding how many subnet bits are required for the number of subnets requested
      [math]::Ceiling([math]::Log($SubnetsRequired)/[math]::log(2)) + $_ + $InitialMask
    }
    $SubnetResults = foreach ($SubnettedBits in $SubnetingBitsArray) {
      # Go find the valid subnet ranges per valid subnet mask
      Find-IPSubnetRange -IPAddress $ActualNetworkAddrSet.FwdAddrIP -InitialMask $InitialMask -SubnetMask $SubnettedBits
    }
    if ($SmallestSubnets -eq $false) {$SubnetResults}
    else {$SubnetResults | Where-Object {$_.Mask -eq $SubnetResults[-1].Mask}}
  }
}