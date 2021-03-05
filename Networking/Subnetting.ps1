
function Find-ValidSubnetRange {
  Param (
    [Parameter(Mandatory=$true)]
    [string]$NetworkAddress,
    [Parameter(Mandatory=$true)]
    [int]$CIDRSubnetMask,
    [Parameter(Mandatory=$true)]
    [int]$RequiredHostsPerSubnet,
    [Parameter(Mandatory=$true)]
    [int]$RequiredSubnets
  )
  function Get-FwdRevAddress {
    Param (
      [string]$IPAddress
    )
    [ipaddress]$FwdAddress = '1.1.1.1'
    [ipaddress]$RevIPAddress = '1.1.1.1'
    $FwdAddress = $IPAddress
    $RevIPAddress = ($IPAddress -replace '^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$','$4.$3.$2.$1')

    $IPProperties = [ordered]@{
      FwdIPAddress = $FwdAddress.IPAddressToString
      FwdAddress = $FwdAddress.Address 
      RevIPAddress = $RevIPAddress.IPAddressToString
      RevAddress = $RevIPAddress.Address
    }
    New-object -TypeName psobject -Property $IPProperties
  }
  $HostBitsRequired = [math]::Ceiling([math]::Log($RequiredHostsPerSubnet+2)/[math]::log(2)) # +2 to cater for NetworkId and BroadcastID addresses
  $NetworkBitsRequired = [math]::Ceiling([math]::Log($RequiredSubnets)/[math]::log(2))
  $TotalBitsRequired = $CIDRSubnetMask + $HostBitsRequired + $NetworkBitsRequired  
  if ($TotalBitsRequired -le 32) {
    $IPDetails = Get-FwdRevAddress -IPAddress $NetworkAddress 
    $NewCIDRMask = $CIDRSubnetMask + $NetworkBitsRequired
    $MaskBitPosition = 8 - ($NewCIDRMask % 8)
    $JumpVal = [math]::Pow(2,$MaskBitPosition) 
    $OctetIndex = [math]::Truncate($CIDRSubnetMask / 8)
    $Prop = [ordered]@{
      IPStuff = $IPDetails
      OriginalMask = $CIDRSubnetMask
      NewCIDRMask = $NewCIDRMask
      HostBits = $HostBitsRequired
      SubnetBits = $NetworkBitsRequired
      BitsRemaining = 32 - ($NetworkBitsRequired + $HostBitsRequired + $CIDRSubnetMask)
      MaskBitPosition = $MaskBitPosition 
      JumpVal = $JumpVal
      OctetIndex = $OctetIndex
    }
    $SubnetInfo = New-Object -TypeName psobject -Property $Prop
    $SubnetInfo
  } 
  else {
    Write-Warning "The subnetting you have requested is impossible"
    break
  }  
}

$NetworkIPObj = Find-ValidSubnetRange -NetworkAddress '173.13.0.0' -CIDRSubnetMask 16 -RequiredHostsPerSubnet 1000 -RequiredSubnets 14
$NetworkIPObj