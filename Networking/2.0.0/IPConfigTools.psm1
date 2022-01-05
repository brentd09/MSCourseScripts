function Get-IPConfig {
  [CmdletBinding()]
  Param(
    [switch]$All,
    [switch]$Connected  
  )
  $NetAdapters = Get-NetAdapter -IncludeHidden | Where-Object {$_.MacAddress -notmatch '^$'}
  $WMIAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {$_.InterfaceIndex -in $NetAdapters.ifIndex}
  $WMIAdapterConfigs = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object {$_.InterfaceIndex -in $NetAdapters.ifIndex} 
  $IPInterFaces = Get-NetIPInterface |  Where-Object {$_.ifIndex -in $NetAdapters.ifIndex}
  foreach ($NetAdapter in $NetAdapters) {
    $WMIAdapter     = $WMIAdapters | Where-Object {$_.InterfaceIndex -eq $NetAdapter.ifIndex}
    $WMIAdapterConf = $WMIAdapterConfigs | Where-Object {$_.InterfaceIndex -eq $NetAdapter.ifIndex}
    $IPInterFace    = $IPInterFaces | Where-Object {$_.ifIndex -eq $NetAdapter.ifIndex}
    if ($Connected -eq $true) {
      if ($IPInterFace.ConnectionState -notcontains "Connected") {continue}
    }
    if ($All -eq $false) {
      $AdapProp = [ordered]@{
        AdapterName           = $NetAdapter.Name
        Description           = $NetAdapter.InterfaceDescription
        LinkLocalAddress      = $WMIAdapterConf.IPAddress | Where-Object {$_ -match '^FE80'}
        IPv4Address           = $WMIAdapterConf.IPAddress | Where-Object {$_ -notmatch ':'}
        IPv4SubnetMask        = $WMIAdapterConf.IPSubnet | Where-Object {$_ -match '\.'}
        IPv6Address           = $WMIAdapterConf.IPAddress | Where-Object {$_ -match ':' -and $_ -notmatch '^FE80'}
        IPv6Mask              = $WMIAdapterConf.IPSubnet | Where-Object {$_ -notmatch '\.'}
      }
    }
    else {
      $AdapProp = [ordered]@{
        HostName              = $NetAdapter.SystemName
        AdapterName           = $NetAdapter.Name
        InterfaceID           = $NetAdapter.ifIndex
        Description           = $NetAdapter.InterfaceDescription
        PhysicalAddress       = $WMIAdapter.MacAddress
        DHCPEnabled           = $WMIAdapterConf.DHCPEnabled
        LinkLocalAddress      = $WMIAdapterConf.IPAddress | Where-Object {$_ -match '^FE80'}
        IPv4Address           = $WMIAdapterConf.IPAddress | Where-Object {$_ -notmatch ':'}
        IPv4SubnetMask        = $WMIAdapterConf.IPSubnet | Where-Object {$_ -match '\.'}
        IPv4ConnectionState   = ($IPInterFace | Where-Object {$_.AddressFamily -eq 'IPv4'}).ConnectionState
        IPv6Address           = $WMIAdapterConf.IPAddress | Where-Object {$_ -match ':' -and $_ -notmatch '^FE80'}
        IPv6Mask              = $WMIAdapterConf.IPSubnet | Where-Object {$_ -notmatch '\.'}
        IPv6ConnectionState   = ($IPInterFace | Where-Object {$_.AddressFamily -eq 'IPv6'}).ConnectionState
        DHCPLeaseObtained     = $WMIAdapterConf.DHCPLeaseObtained
        DHCPLeaseExpires      = $WMIAdapterConf.DHCPLeaseExpires
        DefaultGateway        = $WMIAdapterConf.DefaultIPGateway
        DHCPServer            = $WMIAdapterConf.DHCPServer
        DNSServer             = $WMIAdapterConf.DNSServerSearchOrder
      }
    }
    New-Object -TypeName psobject -Property $AdapProp 
  }
}