function Invoke-DhcpDiscover {
  <#
  .SYNOPSIS
    Sends DHCP Discover packet to detect DHCP Servers sending DHCP Offers
  .DESCRIPTION
    This command sends a DHCP Discover packet to show all of the DHCP Offers that
    are responding. This is similar to the legacy DHCPLoc.exe tool.
  .EXAMPLE
    Invoke-DhcpDiscover 
    Sends DHCP Discover packet to detect DHCP Servers sending DHCP Offers
  .PARAMETER MacAddress
    MAC Address String in Hex-Decimal Format can be delimited with 
    dot, dash or colon (or none)
  .PARAMETER UUIDString
    The UUID/GUID-based Client Machine Identifier option is defined in [RFC4578], 
    with option code 97. The option is part of a set of options for Intel 
    Preboot eXecution Environment (PXE). The purpose of the PXE system is to perform 
    management functions on a device before its main OS is operational. 
    The Client Machine Identifier carries a 16-octet Globally Unique Identifier (GUID), 
    which uniquely identifies the device.
  .PARAMETER Option60String
    The DHCP functionality supports the DHCP vendor class identifier option (option 60). 
    This support allows DHCP relay to compare option 60 strings in received DHCP client 
    packets against strings that you configure on the router. You can use the DHCP relay 
    option 60 feature when providing converged services in your network environment—option 60
    support enables DHCP relay to direct client traffic to the specific DHCP server 
    (the vendor-option server) that provides the service that the client requires. 
    Or, as another option, you can configure option 60 strings to direct traffic to the DHCP 
    local server in the current virtual router.
  .PARAMETER ProcessorArchitecture
    Possible Processor Architecture values here: https://www.iana.org/assignments/dhcpv6-parameters/processor-architecture.csv
     x86-x64 Bios = 0
     x86 UEFI = 6
     x64 UEFI = 7
     xEFIBC = 9 
  .PARAMETER DiscoverTimeout
    Length of time (in seconds) to spend waiting for Offers if
    the connection does not timeout first
  .NOTES
    General notes
  
    Net-DhcpDiscover.ps1 Originating Author: Chris Dent from Origin Date: 16/02/2010 
    Origin Source: http://www.indented.co.uk/2010/02/17/dhcp-discovery/ 
    Major Rework Author: Andreas Hammarskjöld @ 2Pint Software Rework Date: 7/02/2017 Http://2pintsoftware.com 
    A script to send a DHCPDISCOVER request and report on DHCPOFFER responses returned by all DHCP Servers on the current subnet. 
    Also adding PXE Option to discover ProxyDHCP servers. DHCP Packet Format (RFC 2131 - http://www.ietf.org/rfc/rfc2131.txt): 
  
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |     op (1)    |   htype (1)   |   hlen (1)    |   hops (1)    |
    +---------------+---------------+---------------+---------------+
    |                            xid (4)                            |
    +-------------------------------+-------------------------------+
    |           secs (2)            |           flags (2)           |
    +-------------------------------+-------------------------------+
    |                          ciaddr  (4)                          |
    +---------------------------------------------------------------+
    |                          yiaddr  (4)                          |
    +---------------------------------------------------------------+
    |                          siaddr  (4)                          |
    +---------------------------------------------------------------+
    |                          giaddr  (4)                          |
    +---------------------------------------------------------------+
    |                                                               |
    |                          chaddr  (16)                         |
    |                                                               |
    |                                                               |
    +---------------------------------------------------------------+
    |                                                               |
    |                          sname   (64)                         |
    +---------------------------------------------------------------+
    |                                                               |
    |                          file    (128)                        |
    +---------------------------------------------------------------+
    |                                                               |
    |                          options (variable)                   |
    +---------------------------------------------------------------+
  #>
  
  
  # Parameters
  
  Param(
    [String]$MacAddress = "AA:BB:CC:DD:EE:FF",
    [String]$UUIDString = "AABBCCDD-AABB-AABB-AABB-AABBCCDDEEFF",
    [string]$Option60String = "PXEClient",
    [ValidateSet(0,6,7,9)]
    [int]$ProcessorArchitecture  = 0, 
    [Byte]$DiscoverTimeout = 60
  )
   
  Function New-DhcpDiscoverPacket {
    Param([String]$MacAddress = "AA:BB:CC:DD:EE:FF")
    $XID = New-Object Byte[] 4
    $Random = New-Object Random
    $Random.NextBytes($XID)
    $MacAddress = $MacAddress -Replace "-|:" 
    $MacAddress = [BitConverter]::GetBytes(([UInt64]::Parse($MacAddress, [Globalization.NumberStyles]::HexNumber)))
    [Array]::Reverse($MacAddress)
    $DhcpDiscover = New-Object Byte[] 243
    [Array]::Copy($XID, 0, $DhcpDiscover, 4, 4)
    [Array]::Copy($MACAddress, 2, $DhcpDiscover, 28, 6)
    $DhcpDiscover[0] = 1
    $DhcpDiscover[1] = 1
    $DhcpDiscover[2] = 6
    $DhcpDiscover[10] = 128
    $DhcpDiscover[236] = 99
    $DhcpDiscover[237] = 130
    $DhcpDiscover[238] = 83
    $DhcpDiscover[239] = 99
    $DhcpDiscover[240] = 53
    $DhcpDiscover[241] = 1
    $DhcpDiscover[242] = 1
    $DhcpDiscover_Option60 = New-Object Byte[] 2
    $DhcpDiscover_Option60[0] = 60
    $DhcpDiscover_Option60[1] = [System.Text.Encoding]::ASCII.GetBytes($Option60String).Length;
    $Option60Array = [System.Text.Encoding]::ASCII.GetBytes($Option60String);
    $DhcpDiscover_Option60 = $DhcpDiscover_Option60 + $Option60Array;
    $DhcpDiscover = $DhcpDiscover + $DhcpDiscover_Option60;
    $DhcpDiscover_Option93 = New-Object Byte[] 4
    $DhcpDiscover_Option93[0] = 93
    $DhcpDiscover_Option93[1] = 2
    $DhcpDiscover_Option93[2] = 0
    $DhcpDiscover_Option93[3] = $ProcessorArchitecture
    $DhcpDiscover = $DhcpDiscover + $DhcpDiscover_Option93;
    $DhcpDiscover_Option97 = New-Object Byte[] 2
    $DhcpDiscover_Option97[0] = 97
    $DhcpDiscover_Option97[1] = 36 
    $UUIDarray = [System.Text.Encoding]::ASCII.GetBytes($UUIDString);
    $DhcpDiscover_Option97 = $DhcpDiscover_Option97 + $UUIDarray;
    $DhcpDiscover = $DhcpDiscover + $DhcpDiscover_Option97;
    Return $DhcpDiscover
  }
   
  Function Read-DhcpPacket( [Byte[]]$Packet ) {
    $Reader = New-Object IO.BinaryReader(New-Object IO.MemoryStream(@(,$Packet)))
    $DhcpResponse = New-Object Object
    $DhcpResponse | Add-Member NoteProperty Op $Reader.ReadByte()
    if ($DhcpResponse.Op -eq 1) {$DhcpResponse.Op = "BootRequest"} 
    else {$DhcpResponse.Op = "BootResponse" }
    $DhcpResponse | Add-Member NoteProperty HType -Value $Reader.ReadByte()
    if ($DhcpResponse.HType -eq 1) { $DhcpResponse.HType = "Ethernet" }
    $DhcpResponse | Add-Member NoteProperty HLen $Reader.ReadByte()
    $DhcpResponse | Add-Member NoteProperty Hops $Reader.ReadByte()
    $DhcpResponse | Add-Member NoteProperty XID $Reader.ReadUInt32()
    $DhcpResponse | Add-Member NoteProperty Secs $Reader.ReadUInt16()
    $DhcpResponse | Add-Member NoteProperty Flags $Reader.ReadUInt16()
    if ($DhcpResponse.Flags -BAnd 128) { $DhcpResponse.Flags = @("Broadcast") }
    $DhcpResponse | Add-Member NoteProperty CIAddr $("$($Reader.ReadByte()).$($Reader.ReadByte())." + "$($Reader.ReadByte()).$($Reader.ReadByte())")
    $DhcpResponse | Add-Member NoteProperty YIAddr $("$($Reader.ReadByte()).$($Reader.ReadByte())." + "$($Reader.ReadByte()).$($Reader.ReadByte())")
    $DhcpResponse | Add-Member NoteProperty SIAddr $("$($Reader.ReadByte()).$($Reader.ReadByte())." + "$($Reader.ReadByte()).$($Reader.ReadByte())")
    $DhcpResponse | Add-Member NoteProperty GIAddr $("$($Reader.ReadByte()).$($Reader.ReadByte())." + "$($Reader.ReadByte()).$($Reader.ReadByte())")
    $MacAddrBytes = New-Object Byte[] 16
    [Void]$Reader.Read($MacAddrBytes, 0, 16)
    $MacAddress = [String]::Join(":", $($MacAddrBytes[0..5] | ForEach-Object { [String]::Format('{0:X2}', $_) }))
    $DhcpResponse | Add-Member NoteProperty CHAddr $MacAddress
    $DhcpResponse | Add-Member NoteProperty SName $([String]::Join("", $Reader.ReadChars(64)).Trim())
    $DhcpResponse | Add-Member NoteProperty File $([String]::Join("", $Reader.ReadChars(128)).Trim())
    $DhcpResponse | Add-Member NoteProperty MagicCookie $("$($Reader.ReadByte()).$($Reader.ReadByte())." + "$($Reader.ReadByte()).$($Reader.ReadByte())")
    $DhcpResponse | Add-Member NoteProperty Options @()
    While ($Reader.BaseStream.Position -lt $Reader.BaseStream.Length) {
      $Option = New-Object Object
      $Option | Add-Member NoteProperty OptionCode $Reader.ReadByte()
      $Option | Add-Member NoteProperty OptionName ""
      $Option | Add-Member NoteProperty Length 0
      $Option | Add-Member NoteProperty OptionValue ""
      If ($Option.OptionCode -ne 0 -And $Option.OptionCode -ne 255) {
        $Option.Length = $Reader.ReadByte()
      }
      Switch ($Option.OptionCode) {
        0 { $Option.OptionName = "PadOption" }
        1 {
          $Option.OptionName = "SubnetMask"
          $Option.OptionValue = `
            $("$($Reader.ReadByte()).$($Reader.ReadByte())." + `
            "$($Reader.ReadByte()).$($Reader.ReadByte())") }
        3 {
          $Option.OptionName = "Router"
          $Option.OptionValue = `
            $("$($Reader.ReadByte()).$($Reader.ReadByte())." + `
            "$($Reader.ReadByte()).$($Reader.ReadByte())") }
        6 {
          $Option.OptionName = "DomainNameServer"
          $Option.OptionValue = @()
          For ($i = 0; $i -lt ($Option.Length / 4); $i++) { 
            $Option.OptionValue += $("$($Reader.ReadByte()).$($Reader.ReadByte())." + "$($Reader.ReadByte()).$($Reader.ReadByte())")
          } 
        }
        15 {
          $Option.OptionName = "DomainName"
          $Option.OptionValue = [String]::Join("", $Reader.ReadChars($Option.Length)) 
        }
        51 {
          $Option.OptionName = "IPAddressLeaseTime"
          $Value = ($Reader.ReadByte() * [Math]::Pow(256, 3)) + ($Reader.ReadByte() * [Math]::Pow(256, 2)) + ($Reader.ReadByte() * 256) + $Reader.ReadByte()
          $Option.OptionValue = $(New-TimeSpan -Seconds $Value) 
        }
        53 { 
          $Option.OptionName = "DhcpMessageType"
          Switch ($Reader.ReadByte()) {
            1 { $Option.OptionValue = "DHCPDISCOVER" }
            2 { $Option.OptionValue = "DHCPOFFER" }
            3 { $Option.OptionValue = "DHCPREQUEST" }
            4 { $Option.OptionValue = "DHCPDECLINE" }
            5 { $Option.OptionValue = "DHCPACK" }
            6 { $Option.OptionValue = "DHCPNAK" }
            7 { $Option.OptionValue = "DHCPRELEASE" }
          } 
        }
        54 {
          $Option.OptionName = "DhcpServerIdentifier"
          $Option.OptionValue = $("$($Reader.ReadByte()).$($Reader.ReadByte())." + "$($Reader.ReadByte()).$($Reader.ReadByte())") 
        }
        58 {
          $Option.OptionName = "RenewalTime"
          $Value = ($Reader.ReadByte() * [Math]::Pow(256, 3)) + ($Reader.ReadByte() * [Math]::Pow(256, 2)) + ($Reader.ReadByte() * 256) + $Reader.ReadByte()
          $Option.OptionValue = $(New-TimeSpan -Seconds $Value) 
        }
        59 {
          $Option.OptionName = "RebindingTime"
          $Value = ($Reader.ReadByte() * [Math]::Pow(256, 3)) + ($Reader.ReadByte() * [Math]::Pow(256, 2)) + ($Reader.ReadByte() * 256) + $Reader.ReadByte()
          $Option.OptionValue = $(New-TimeSpan -Seconds $Value) 
        }
        67 {
          $Option.OptionName = "vendor-class-identifier"
          $Value = ($Reader.ReadByte() * [Math]::Pow(256, 3)) + ($Reader.ReadByte() * [Math]::Pow(256, 2)) + ($Reader.ReadByte() * 256) + $Reader.ReadByte()
          $Option.OptionValue = $(New-TimeSpan -Seconds $Value) 
        }
        255 { 
          $Option.OptionName = "EndOption" 
        }
        default {
          $Option.OptionName = "NoOptionDecode"
          $Buffer = New-Object Byte[] $Option.Length
          [Void]$Reader.Read($Buffer, 0, $Option.Length)
          $Option.OptionValue = $Buffer
        }
      }
      $Option | Add-Member ScriptMethod ToString { Return "$($this.OptionName) ($($this.OptionValue))" } -Force
      $DhcpResponse.Options += $Option
    }
    Return $DhcpResponse
  }
   
  Function New-UdpSocket {
    Param(
      [Int32]$SendTimeOut = 5,
      [Int32]$ReceiveTimeOut = 5
    )
    $UdpSocket = New-Object Net.Sockets.Socket([Net.Sockets.AddressFamily]::InterNetwork,[Net.Sockets.SocketType]::Dgram,[Net.Sockets.ProtocolType]::Udp)
    $UdpSocket.EnableBroadcast = $True
    $UdpSocket.ExclusiveAddressUse = $False
    $UdpSocket.SendTimeOut = $SendTimeOut * 1000
    $UdpSocket.ReceiveTimeOut = $ReceiveTimeOut * 1000
    Return $UdpSocket
  }

  Function Remove-Socket {
    Param([Net.Sockets.Socket]$Socket)
    $Socket.Shutdown("Both")
    $Socket.Close()
  }

  # Main

  $Message = New-DhcpDiscoverPacket -Send 10 -Receive 10
  $UdpSocket = New-UdpSocket
  $EndPoint = [Net.EndPoint](New-Object Net.IPEndPoint($([Net.IPAddress]::Any, 68)))
  $UdpSocket.Bind($EndPoint)
  $EndPoint = [Net.EndPoint](
  New-Object Net.IPEndPoint($([Net.IPAddress]::Broadcast, 67)))
  $UdpSocket.SendTo($Message, $EndPoint) | Out-Null
  $NoConnectionTimeOut = $True
  $Start = Get-Date
  While ($NoConnectionTimeOut) {
    $BytesReceived = 0
    Try {
      $SenderEndPoint = [Net.EndPoint](New-Object Net.IPEndPoint($([Net.IPAddress]::Any, 0)))
      $ReceiveBuffer = New-Object Byte[] 1024
      $BytesReceived = $UdpSocket.ReceiveFrom($ReceiveBuffer, [Ref]$SenderEndPoint)
    }
    Catch [Net.Sockets.SocketException] {$NoConnectionTimeOut = $False}
    If ($BytesReceived -gt 0) {Read-DhcpPacket $ReceiveBuffer[0..$BytesReceived]}
    If ((Get-Date) -gt $Start.AddSeconds($DiscoverTimeout)) {$NoConnectionTimeOut = $False}
  }
  Remove-Socket $UdpSocket
}