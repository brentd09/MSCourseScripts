function Get-SubnetRanges {
  [cmdletbinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$StartingSubnet,
    [Parameter(Mandatory=$true)]
    [string]$SubnetMask,
    [Parameter(Mandatory=$true)]
    [int]$RequiredSubnets,
    [Parameter(Mandatory=$true)]
    [int]$RequiredHostsPerSubnet
  )
  function Reverse-Octets {
    Param (
      [string]$IPtoReverse
    )
    [System.Collections.ArrayList]$IPOctets = $IPtoReverse -split '\.'
    $IPRevOctets = $IPOctets.Clone()
    $IPRevOctets.Reverse()
    $IPRevOctets -join '.'
  }
  function Add-IPAddress {
    Param (
      [string]$IPAddr,
      [int]$NumberByteToAdd
    )
    [ipaddress]$RevIP = Reverse-Octets -IPtoReverse $IPAddr
    $ModifiedRevIp = $RevIP.Address + $NumberByteToAdd
    [ipaddress]$ip = '1.1.1.1'
    $ip.address = $ModifiedRevIp
    Reverse-Octets -IPtoReverse $ip.ipaddresstostring
  }
  $IPRegex = '^(\d{1,3}\.){3}\d{1,3}$'
  if ($StartingSubnet -match $IPRegex) {
    $RevOctets = Reverse-Octets -IPtoReverse $StartingSubnet
    $MinTradingHostsBits = [math]::Ceiling([math]::Log($RequiredSubnets)/[math]::Log(2))
    $MinHostBits = [math]::Ceiling([math]::Log($RequiredHostsPerSubnet)/[math]::Log(2))
    if ($SubnetMask -match '^255\.((0|128|192|224|240|248|252|254|255)\.0\.0|255\.(0|128|192|224|240|248|252|254|255).0|255\.255\.(0|128|192|224|240|248|252|254|255))$') {
      $SubnetMaskOctets = $SubnetMask -split '\.'
      $Binary = ''
      foreach ($SMOctet in $SubnetMaskOctets) {
        $Binary = $Binary + ([convert]::ToString($SMOctet,2)).TrimEnd('0')
      }
      [int]$CIDRMask = $Binary.Length
      $SNMask = $SubnetMask
    }
    elseif (($SubnetMask -as [int]) -in (8..30)) {
      $SNMask =''
      [int]$TempCIDR = $SubnetMask
      [int]$CIDRMask = $SubnetMask
      do {
        $SubtractionResult = $TempCIDR - 8
        if ($SubtractionResult -ge 0) {
          $SNMask = $SNMask + '255.'
          $TempCIDR = $SubtractionResult
        } 
        else {
          $Hostbits = [math]::abs($SubtractionResult)
          $Binary = '1'*$TempCIDR + '0'* $Hostbits
          $SNMask = $SNMask + ([convert]::ToInt32($Binary,2)) + '.0.0.0'
          $Ended = $true
        }
        $steps++
      } until ($Ended -eq $true)
      $SNMask = $SNMask -replace '^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*','$1'
    }
    else {Write-Warning 'Subnet Mask is not valid';break}

    Write-Verbose "StartingSubnet $StartingSubnet "
    Write-Verbose "SNMask $SNMask                 "
    Write-Verbose "CIDRMask $CIDRMask             "
    Write-Verbose "RequiredSubnets $RequiredSubnets"
    Write-Verbose "RequiredHostsPerSubnet $RequiredHostsPerSubnet"
    Write-Verbose "MinTradingHostsBits $MinTradingHostsBits"
    Write-Verbose "MinHostBits $MinHostBits"
    $HostBitsRemaining = 32 - $CIDRMask
    $hostsAfterSubnetting = $HostBitsRemaining - $MinTradingHostsBits
    $ThisSubnetsNetBits = $MinTradingHostsBits
    if (([math]::Pow(2,$hostsAfterSubnetting) - 2) -lt $RequiredHostsPerSubnet) {
      Write-Warning "There are no solutions where this will work"
      break 
    }    
    $ValidSubnets = do {
      $ThisSubnetsHostsBits = $HostBitsRemaining - $ThisSubnetsNetBits
      $ThisSNMBinary = '1'*$CIDRMask +'1'*$ThisSubnetsNetBits + '0'*$ThisSubnetsHostsBits
      $ThisSNMNumber = [convert]::ToInt64($ThisSNMBinary,2)
      [ipaddress]$Addr = '1.1.1.1'
      $Addr.Address = $ThisSNMNumber
      $ThisSubnetsMask = Reverse-Octets -IPtoReverse $Addr.IPAddressToString
      $SNMToSubtract = [convert]::ToInt64('1'*(($CIDRMask+$ThisSubnetsNetBits)%8)+'0'*(8-($CIDRMask+$ThisSubnetsNetBits)%8),2)
      if ($SNMToSubtract -eq 0) {
        $SNMToSubtract = 255
        $NextOctet = 1
      }
      else {$NextOctet = 0}
      $ThisSubnetHash = [ordered]@{
        SubnetID         = $StartingSubnet
        SubnetMask       = $ThisSubnetsMask
        CIDRMask         = $CIDRMask+$ThisSubnetsNetBits
        Subnets          = [math]::Pow(2,$ThisSubnetsNetBits)
        IPsPerSubnet     = [math]::Pow(2,$ThisSubnetsHostsBits) 
        HostsIPsPerSubet = [math]::Pow(2,$ThisSubnetsHostsBits) -2
        SubnetJumpValue  = 256 - $SNMToSubtract
        JumpOctet        = [math]::Ceiling(($CIDRMask+$ThisSubnetsNetBits) / 8) + $NextOctet
      }
      $ThisSubnetsNetBits++
      [PSCustomobject]$ThisSubnetHash
    } until ($ThisSubnetsHostsBits -eq $MinHostBits)
    foreach ($ValidSubnet in $ValidSubnets) {
      0..($ValidSubnet.Subnets-1) | ForEach-Object {
        Add-IPAddress -IPAddr $ValidSubnet.SubnetID -NumberByteToAdd ($ValidSubnet.IPsPerSubnet * $_)
      }
    }
  }
  else {
    Write-Warning 'The subnet address is not valid'
  }
}

Get-SubnetRanges -StartingSubnet '192.168.0.0' -SubnetMask 16 -RequiredSubnets 14 -RequiredHostsPerSubnet 1000 | ft
