function Send-WakeOnLan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$True,Position=1,
               ValueFromPipeline,
               ValueFromPipelineByPropertyName)]
    [ValidatePattern('([a-f0-9]{2}[:.-]?){5}[a-f0-9]{2}')]           
    [string[]]$MACAddress,
    [string]$IPAddress = "255.255.255.255", 
    [int]$PortNumber = 9
  )
  begin {}
  process {
    foreach ($MAC in $MACAddress) {
      $BroadcastAddress = [Net.IPAddress]::Parse($IPAddress)
      $MAC = $MAC -replace '[:.-]',''
      $Target = 0,2,4,6,8,10 | ForEach-Object {
        [convert]::ToByte($MAC.substring($_,2),16)
      }
      $Packet = (,[byte]255 * 6) + ($Target * 16)
      $UDPclient = new-Object System.Net.Sockets.UdpClient
      $UDPclient.Connect($BroadcastAddress,$PortNumber)
      [void]$UDPclient.Send($Packet, 102)
    } 
  }
  end {}
}



Clear-Host
# Get IP info from interface
$PhysicalNetAdapter = Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'UP'}
$IPInfo = Get-NetIPAddress -InterfaceIndex $PhysicalNetAdapter.ifIndex -AddressFamily IPv4 
$BinSNM = '1' * $IPInfo.PrefixLength + '0' * (32 - $IPInfo.PrefixLength)
$DecSNM = ([System.Net.IPAddress]"$([System.Convert]::ToInt64($BinSNM,2))").IPAddressToString

# Create the Address objects
$IPObj = [ipaddress]$IPInfo.IPAddress
$SNMObj = [ipaddress]$DecSNM
$SNIDObj = [ipaddress]($IPObj.Address -band $SNMObj.Address)

# Calculate addresses in subnet
$TotalIPs = [math]::Pow(2,(32 - $IPInfo.PrefixLength))

# Reverse IP to make adding hosts easy
$RevIP = [ipaddress](($SNIDObj.IPAddressToString -split '\.')[-1..-4] -join '.')

$RemoveIPsFromList = @()
$RemoveIPsFromList += (Get-NetIPConfiguration -InterfaceIndex $PhysicalNetAdapter.ifIndex | ForEach-Object { $_.IPv4DefaultGateway}).NextHop
$RemoveIPsFromList += ([System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()).getIPproperties().dhcpserveraddresses.ipaddresstostring
$RemoveIPsFromList += $IPInfo.Address
# Add hosts to fill the subnet range and unreverse IP addresses
# $AllIPs = 1..($TotalIPs - 2)  | ForEach-Object {
$AllIPs = 10..99  | ForEach-Object {
  $rev = [ipaddress]($RevIP.Address + $_)
  $unrev = [ipaddress](($rev.IPAddressToString -split '\.')[-1..-4] -join '.')
  if ($unrev.IPAddressToString -notin $RemoveIPsFromList) {$unrev.IPAddressToString}
}

# clear arp cache, test for active IPs
Get-NetNeighbor | Remove-NetNeighbor -Confirm:$false
foreach ($IP in $AllIPs) {Test-Connection  -ComputerName $IP -AsJob *> $null} 

$ReachablePCs = Get-NetNeighbor -State Reachable -AddressFamily IPv4 | Where-Object {$_.IPAddress -in $AllIPs}

# Determine who is reachable and is a Classroom PC and pickup their hostnames
$PCsInClass = foreach ($ReachablePC in $ReachablePCs) { 
  if ($ReachablePC.IPAddress -in $AllIPs) {
    $PingResult = ping -n 1 -w 5 -a $ReachablePC.IPAddress
    if ($PingResult -match 'DDLS') {$ReachablePC | Select-Object -Property @{n='ComputerName';e={($PingResult -split '\s+')[2]}},*}
  } 
}

# Display the computers that have been found
Clear-Host
Write-Host -ForegroundColor Cyan "Classroom Computers Located"
Write-Host -ForegroundColor Cyan "---------------------------"
"{0,20} {1,20} {2,20}" -f 'MAC Address','IP Address','Computer Name'
"{0,20} {1,20} {2,20}" -f '-----------','----------','-------------'
foreach ($PC in $PCsInClass) {"{0,20} {1,20} {2,20}" -f $PC.LinkLayerAddress,$PC.IPAddress,$PC.ComputerName}
Read-Host "`ngot them all?"


# Shutdown each computer and wait for them to do so
# Stop-Computer -ComputerName $PCsInClass.IPAddress -Force
# Start-Sleep -Seconds 60 

#Send Wake on LAN packet to each machine
$PCsInClass.MACAddress | Send-WakeOnLan 