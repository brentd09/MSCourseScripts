function Show-SubnetReport {  
  [cmdletbinding()]
  Param (
    [string]$OriginalNetworkID,
    [string]$OriginalSubnetMask,
    [int]$RequiredSubnets,
    [int]$RequiredHostsPerNet,
    [validateSet('HTML','CSV','ONSCREEN')]
    [string]$ReportType
  ) 
  
  function Rev-IPAddress {
    Param (
      [string]$IPAddress
    )
    if ($IPAddress -match '^(\d{1,3}\.){3}\d{1,3}$') {
      $OctetArray   = $IPAddress -split '\.'
      $RevOctArray  = $OctetArray[3..0]
      [string]$RevIPAddress = $RevOctArray -join '.' 
      $RevIPAddress
    }
  }
  
  function Find-IPSubnetRange {
    [cmdletbinding()]
    Param (
      [string]$SubnetAddress,
      [int]$NumberOfBitsToAdd,
      [int]$SubnetNumber
    )
    [ipaddress]$RevSNID = '1.1.1.1'
    $RevSNID = Rev-IPAddress -IPAddress $SubnetAddress
    $FirstRevIPNum = $RevSNID.Address + $NumberOfBitsToAdd * $SubnetNumber
    $LastRevIPNum  = $RevSNID.Address + ((1 + $SubnetNumber) * $NumberOfBitsToAdd - 1)
    $FirstValidNum = $RevSNID.Address + $NumberOfBitsToAdd * $SubnetNumber + 1
    $LastValidNum  = $RevSNID.Address + ((1 + $SubnetNumber) * $NumberOfBitsToAdd - 2)
    $SubnetHash = [ordered]@{
      StartSubnet = Rev-IPAddress -IPAddress ([ipaddress]$FirstRevIPNum).IPAddressToString
      EndSubnet = Rev-IPAddress -IPAddress ([ipaddress]$LastRevIPNum).IPAddressToString
      FirstValidIP = Rev-IPAddress -IPAddress ([ipaddress]$FirstValidNum).IPAddressToString
      LastValidIP =Rev-IPAddress -IPAddress ([ipaddress]$LastValidNum).IPAddressToString
    }
    $SubnetHash
  }
  
  function Get-BitsFromSNM {
    Param (
      [string]$SubnetMask
    )
    if ($SubnetMask -match '^255\.((0|128|192|224|240|248|252|254|255)\.0\.0|255\.(0|128|192|224|240|248|252|254|255).0|255\.255\.(0|128|192|224|240|248|252))$') {
      $DottedDecSNM = $SubnetMask
      [ipaddress]$FullBroadcastAddr = '255.255.255.255'
      [ipaddress]$RevSNM = Rev-IPAddress -IPAddress $SubnetMask
      $NetBits = 32 - ([math]::Log($FullBroadcastAddr.Address - $RevSNM.Address + 1)/[math]::Log(2))
    }
    elseif (($SubnetMask -as [int]) -in (8..30)) {
      $NetBits = $SubnetMask -as [int]
      $DottedDecSNM = Rev-IPAddress -IPAddress ([ipaddress]([convert]::ToInt64('1'*$NetBits+'0'*(32-$NetBits),2))).IPAddressToString
    }
    else {Write-Warning "Subnet mask not valid";break}
    $SNMHash = @{
      DottedDecimal = $DottedDecSNM
      CIDRMask = $NetBits
      HostsPerNet = [math]::Pow(2,(32-$NetBits)) - 2
    }
    $SNMHash 
  }
  
  function Get-BitDifference {
    Param (
      [string]$SubnetMask1,
      [string]$SubnetMask2
    )
    $Sub1Info = Get-BitsFromSNM -SubnetMask $SubnetMask1
    $Sub2Info = Get-BitsFromSNM -SubnetMask $SubnetMask2
    $BitDifference = [math]::Abs($Sub1Info.CIDRMask - $Sub2Info.CIDRMask)
    $DiffHash = [ordered]@{
      Subnet1 = $Sub1Info.DottedDecimal
      Subnet2 = $Sub2Info.DottedDecimal
      BitDifference = $BitDifference
      Networks = [math]::Pow(2,$BitDifference)
      HostsPerNet = [math]::Min($Sub1Info.HostsPerNet,$Sub2Info.HostsPerNet)
    }
    $DiffHash
  }
  
  ### MAIN CODE ###
  foreach ($SubnetCount in ($RequiredSubnets..32)) {  
    $NetBitsNeeded      = [math]::Ceiling([math]::Log($RequiredSubnets)/[math]::Log(2))
    $OrigSubnetMaskInfo = Get-BitsFromSNM -SubnetMask $OriginalSubnetMask    
    $NewMaskBitCount    = $OrigSubnetMaskInfo.CIDRMask + $NetBitsNeeded
    $TotalHosts         = [math]::Pow(2,
    if (){}

    $NewSubnetMask = Get-BitsFromSNM -SubnetMask $NewMaskBitCount
    $NewSubnetMask
  }
}  

Show-SubnetReport -OriginalNetworkID 192.168.0.0 -OriginalSubnetMask 255.255.0.0 -RequiredSubnets 5 -RequiredHostsPerNet 1000