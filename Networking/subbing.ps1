function Find-ValidSubnet {
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
    if ($PSCmdlet.ParameterSetName -eq 'Default') {
      $BinaryString = '1' * $BitCount + '0' * (32 - $BitCount)
      $IPObj = [ipaddress]([convert]::ToInt64($BinaryString,2))
      $ObjProp = [ordered]@{
        FwdAddrIPObj = [ipaddress]($IPObj.IPAddressToString -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$4.$3.$2.$1')
        RevAddrIPObj = $IPObj
      }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'IPAddress') {
      $ObjProp = [ordered]@{
        FwdAddrIPObj = [ipaddress]$IPAddress
        RevAddrIPObj = [ipaddress]($IPAddress -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$4.$3.$2.$1')
      }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'DecAddress') {
      $IPObj = [ipaddress]$DecAddress
      $ObjProp = [ordered]@{
        FwdAddrIPObj = [ipaddress]($IPObj.IPAddressToString -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$4.$3.$2.$1')
        RevAddrIPObj = $IPObj
      }      
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
    $MaxSubnetIndex = [math]::Pow(2,($SubnetMask-$InitialMask)) - 1
    $OctetIndex = [math]::Truncate($SubnetMask / 8)
    $JumpValue = [math]::Pow(2,(8-($SubnetMask % 8)))
    [System.Collections.ArrayList]$InitJumpIPArray = @(0,0,0,0)
    $InitJumpIPArray[$OctetIndex] = $JumpValue
    $InitJumpIP = $InitJumpIPArray -join '.'
    $InitJumpObj = ConvertTo-IPAddressObject -IPAddress $InitJumpIP
    foreach ($SubnetIndex in (0..$MaxSubnetIndex)) {
      $ThisJump = $JumpValue * $SubnetIndex 
      [System.Collections.ArrayList]$JumpIPArray = @(0,0,0,0)
      $JumpIPArray[$OctetIndex] = $ThisJump
      $JumpIP = $JumpIPArray -join '.'
      $JumpObj = ConvertTo-IPAddressObject -IPAddress $JumpIP
      $IPObj = ConvertTo-IPAddressObject -IPAddress $IPAddress
      $StartSubnetAddress = $IPObj.RevAddrIPObj.Address + $JumpObj.RevAddrIPObj.Address
      $FirstValidIP = $IPObj.RevAddrIPObj.Address + $JumpObj.RevAddrIPObj.Address + 1
      $LastValidIP = $IPObj.RevAddrIPObj.Address + $JumpObj.RevAddrIPObj.Address + $InitJumpObj.RevAddrIPObj.Address - 2
      $SubnetObj = ConvertTo-IPAddressObject -DecAddress $StartSubnetAddress
      $FirstIPObj = ConvertTo-IPAddressObject -IPAddress $FirstValidIP
      $LastIPObj  = ConvertTo-IPAddressObject -IPAddress $LastValidIP
      $ObjProp = [ordered]@{
        Mask         = $SubnetMask
        SubnetID     = $SubnetObj.FwdAddrIPObj.IPAddressToString
        FirstValidIP = $FirstIPObj.FwdAddrIPObj.IPAddressToString
        LastValidIP  = $LastIPObj.FwdAddrIPObj.IPAddressToString
      }
      New-Object -TypeName psobject -Property $ObjProp
    } 
  }

  $CIDRParts     = $CIDRSubnetAddress -split '\/'
  $SubnetID      = $CIDRParts[0] -as [string]
  $InitialMask   = $CIDRParts[1] -as [int]
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
    $MaskObjects   = ConvertTo-IPAddressObject -BitCount $InitialMask
    $SubnetObjects = ConvertTo-IPAddressObject -IPAddress $SubnetID
    $NetBinAndMask  = $SubnetObjects.RevAddrIPObj.Address -band $MaskObjects.RevAddrIPObj.Address
    $FixedIPObjects = ConvertTo-IPAddressObject -DecAddress $NetBinAndMask
    if ($NetBinAndMask -ne $SubnetObjects.RevAddrIPObj.Address) {
      Write-Warning "This is not the network address that matches this mask: $CIDRSubnetAddress"
      Write-Warning "We will use this instead $($FixedIPObjects.FwdAddrIPObj.IPAddressToString)/$InitialMask"
    }
    $PropList =[ordered]@{
      SubnetsRequired    = $SubnetsRequired
      HostsPerSubnet     = $HostsPerSubnetRequired
      HostBitsRequired   = $HostBitsRequired
      NetworkBitsRequired = $NetworkBitsRequired
      InitialCIDRMask    = $InitialMask
      InitialSubnetID    = $SubnetObjects
      InitialMask        = $MaskObjects  
      FixedInitIP      = $FixedIPObjects
      SubnetSolutions    = 33 - $TotalBitsRequired
      SubnetingBitsArray = 0..(33 - $TotalBitsRequired -1) | ForEach-Object {
        [math]::Ceiling([math]::Log($SubnetsRequired)/[math]::log(2)) + $_ + $InitialMask
      }
    }
    $IPaddressInfo = New-Object -TypeName psobject -Property $PropList
    #$IPaddressInfo
    foreach ($SubnettedBits in $IPaddressInfo.SubnetingBitsArray) {
      Find-IPSubnetRange -IPAddress $IPaddressInfo.FixedInitIP.FwdAddrIPObj.IPAddressToString -InitialMask $IPaddressInfo.InitialCIDRMask -SubnetMask $SubnettedBits
    }
  }
}

Find-ValidSubnet -CIDRSubnetAddress 10.0.0.0/8 -SubnetsRequired 13 -HostsPerSubnetRequired 10 |  ft -groupby Mask