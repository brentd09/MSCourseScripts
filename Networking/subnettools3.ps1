function Get-IPSubnetRange {
  [cmdletbinding()]
  Param (
    [string]$NetworkID,
    [int]$CIDRSNM,
    [int]$RequiredSubnets,
    [int]$RequiredHostsPerSubnet
  )

  function Get-SubnetMaskInfo {
    Param (
      [string]$SubnetMask
    )
    if ($SubnetMask -match '^255\.((0|128|192|224|240|248|252|254|255)\.0\.0|255\.(0|128|192|224|240|248|252|254|255).0|255\.255\.(0|128|192|224|240|248|252))$') {
      $DottedDecSNM = $SubnetMask
      [ipaddress]$FullBroadcastAddr = '255.255.255.255'
      [ipaddress]$RevSNM = Get-ReversedIPAddress -IPAddress $SubnetMask
      $NetBits = 32 - ([math]::Log($FullBroadcastAddr.Address - $RevSNM.Address + 1)/[math]::Log(2))
    }
    elseif (($SubnetMask -as [int]) -in (8..30)) {
      $NetBits = $SubnetMask -as [int]
      $DottedDecSNM = Get-ReversedIPAddress -IPAddress ([ipaddress]([convert]::ToInt64('1'*$NetBits+'0'*(32-$NetBits),2))).IPAddressToString
    }
    else {Write-Warning "Subnet mask not valid";break}
    $SNMHash = @{
      DottedDecimal = $DottedDecSNM
      CIDRMask = $NetBits
      HostsPerNet = [math]::Pow(2,(32-$NetBits)) - 2
    }
    $SNMHash 
  }

  
  ### MAIN CODE ###
  [ipaddress]$RevSNID = '1.1.1.1'
  foreach ($Scenario in (0..29)) { 
    $SubnetBits = [math]::Ceiling([math]::Log($RequiredSubnets)/[math]::Log(2)) + $Scenario
    $NumberOfHostBits = 32 - $CIDRSNM - $SubnetBits
    $SubnetInfo = Get-SubnetMaskInfo -SubnetMask ($CIDRSNM + $SubnetBits)
    $NumberOfSubnets = [math]::Pow(2,$SubnetBits)
    $NumberOfBitsToAdd = [math]::Pow(2,$NumberOfHostBits)
    if ($RequiredHostsPerSubnet -lt $NumberOfBitsToAdd - 2) {
      0..($NumberOfSubnets-1) | ForEach-Object {
        $RevSNID = Get-ReversedIPAddress -IPAddress $NetworkID
        $FirstRevIPNum = $RevSNID.Address + $NumberOfBitsToAdd * $_
        $LastRevIPNum  = $RevSNID.Address + ((1 + $_) * $NumberOfBitsToAdd - 1)
        $FirstValidNum = $RevSNID.Address + $NumberOfBitsToAdd * $_ + 1
        $LastValidNum  = $RevSNID.Address + ((1 + $_) * $NumberOfBitsToAdd - 2)
        $SubnetHash = [ordered]@{
          StartSubnetID =  ([ipaddress]$FirstRevIPNum).IPAddressToString
          EndSubnetID = ([ipaddress]$LastRevIPNum).IPAddressToString
          SubnetID = $SubnetInfo.DottedDecimal
          FirstValidIP = ([ipaddress]$FirstValidNum).IPAddressToString
          LastValidIP = ([ipaddress]$LastValidNum).IPAddressToString
          HostsPerSubnet = $NumberOfBitsToAdd - 2
        }
        [PSCustomObject]$SubnetHash
      }
    }
    else {
      break
    }
  }
}
Get-IPSubnetRange -NetworkID 192.168.0.0 -CIDRSNM 16 -RequiredSubnets 5 -RequiredHostsPerSubnet 1000 | ft