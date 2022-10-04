# Get IP info from interface
$connectedIF = Get-NetIPInterface -AddressFamily IPv4 -Dhcp Enabled -ConnectionState Connected 
$IPInfo = Get-NetIPAddress -InterfaceIndex $connectedIF.ifIndex -AddressFamily IPv4 
$BinSNM = '1' * $IPInfo.PrefixLength + '0' * (32 - $IPInfo.PrefixLength)
$DecSNM = ([System.Net.IPAddress]"$([System.Convert]::ToInt64($SNM,2))").IPAddressToString

# Create the Address objects
$IPObj = [ipaddress]$IPInfo.IPAddress
$SNObj = [ipaddress]$DecSNM
$ANDed = [ipaddress]($IPObj.Address -band $SNObj.Address)

# Calculate addresses in subnet
$TotalIPs = [math]::Pow(2,(32 - $IPInfo.PrefixLength))

# Reverse IP to make adding hosts easy
$RevIP = [ipaddress](($ANDed.IPAddressToString -split '\.')[-1..-4] -join '.')

# Add hosts to fill the subnet range and unreverse IP addresses
$AllIPs = 1..($TotalIPs - 2)  | ForEach-Object {
  $rev = [ipaddress]($RevIP.Address + $_)
  $unrev = [ipaddress](($rev.IPAddressToString -split '\.')[-1..-4] -join '.')
  $unrev.IPAddressToString
}

# List all IPs
$AllIPs