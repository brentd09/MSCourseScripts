function Build-ValidSubnet {
  <#
  .SYNOPSIS
    Takes an IPv4 network address and creates subnets based on hosts and networks needed 
  .DESCRIPTION
    From the information regarding hosts per subnet and subnets required, this command will
    create a list of all valid subnets that fit the stated criteria 
  .EXAMPLE
    Build-ValidSubnet -CIDRSubnetAddress 192.168.0.0/16 -SubnetsRequired 4 -HostsPerSubnetRequired 4000  | Format-Table -GroupBy Mask
    Using the 192.168.0.0/16 network as a base this will find all subnet masks that will allow
    for a minimum of 4 subnets, while still allowing 4000 hosts per subnet. The subnets willl be
    listed for each subnet mask discovered
  .PARAMETER CIDRSubnetAddress
    This parameter requires the network address to be entered with the CIDR mask as well. 
    In this format 192.168.0.0/16
  .PARAMETER SubnetsRequired
    This parameter declares how many subnets the CIDR network will need to be broken into as a minimum.
    Because this is the minimum subnets this command will also look for more subnetsas long as it does
    not impact the hosts per subnet -HostsPerSubnetRequired parameter value.
  .PARAMETER HostsPerSubnetRequired
    This parameter dictates the minimum amount of hosts that are required per subnet.
  .NOTES
    General notes
      Created by:    Brent Denny
      Created on:    09 Mar 2021
      Last Modified: 10 Mar 2021
  #>
  [cmdletbinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$CIDRSubnetAddress,
    [Parameter(Mandatory=$true)]
    [int]$SubnetsRequired,
    [Parameter(Mandatory=$true)]
    [int]$HostsPerSubnetRequired
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
    # convert them into an object that contains the forward and reverse versions 
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
    [int[]]$JumpIPArray = 0,0,0,0
    $JumpIPArray[$JumpIndex] = $JumpValue
    $JumpIPAddr = $JumpIPArray -join '.' 
    $JumpIPAddressSet = ConvertTo-IPAddressObject -IPAddress $JumpIPAddr
    $IPAddressSet = ConvertTo-IPAddressObject -IPAddress $IPAddress
    foreach ($SubnetIndex in (0..$MaxSubnetIndex)) {
      # The RevDec refers to the IP addresses decimal value, it turns out that the 
      # [IPAddress] object reverses the Decimal value of the IP, so by reversing the
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
        Mask         = $SubnetMask
        SubnetID     = $ThisSubnetSet.FwdAddrIP
        FirstValidIP = $FirstValidSet.FwdAddrIP
        LastValidIP  = $LastValidSet.FwdAddrIP
        BroadcastIP  = $BroadCastSet.FwdAddrIP
        HostsPerSubnet = [math]::Pow(2,32 -$SubnetMask) - 2
        Subnet       = $SubnetIndex + 1
      }
      New-Object -TypeName psobject -Property $ObjProp
    } 
  }

  ## MAIN Function BODY
  $CIDRParts    = $CIDRSubnetAddress -split '\/'
  $SubnetID     = $CIDRParts[0] -as [string]
  $InitialMask  = $CIDRParts[1] -as [int]
  $HostBitsRequired = [math]::Ceiling([math]::Log($HostsPerSubnetRequired+2)/[math]::log(2)) # +2 to cater for NetworkId and BroadcastID addresses
  $NetworkBitsRequired = [math]::Ceiling([math]::Log($SubnetsRequired)/[math]::log(2))
  $TotalBitsRequired = $InitialMask + $HostBitsRequired + $NetworkBitsRequired  
  if ($CIDRSubnetAddress -notmatch '^([1-9][0-9]?|(?!127)1[0-9][0-9]?|2[0-2][0-3])\.(([0-9]|1[0-9][0-9]?|[1-9][0-9?]|2[0-5][0-5])\.){2}([0-9]|1[0-9][0-9]?|[1-9][0-9?]|2[0-5][0-5])\/([2-8]|[1-2][0-9]|30)$') {
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
    $NetBinAndMaskDec  = $SubnetSet.RevAddrDec -band $MaskSet.RevAddrDec
    $FixedIPSet = ConvertTo-IPAddressObject -DecAddress $NetBinAndMask
    if ($NetBinAndMaskDec -ne $SubnetSet.RevAddrDec) {
      Write-Warning "This is not the network address that matches this mask: $CIDRSubnetAddress"
      Write-Warning "We will use this instead $($FixedIPSet.FwdAddrIP)/$InitialMask"
    }
    $SubnetingBitsArray = 0..(32 - $TotalBitsRequired ) | ForEach-Object {
      [math]::Ceiling([math]::Log($SubnetsRequired)/[math]::log(2)) + $_ + $InitialMask
    }
    foreach ($SubnettedBits in $SubnetingBitsArray) {
      Find-IPSubnetRange -IPAddress $SubnetID -InitialMask $InitialMask -SubnetMask $SubnettedBits
    }
  }
}