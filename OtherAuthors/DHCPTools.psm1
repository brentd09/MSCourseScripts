function Invoke-DhcpDiscover {
  Param(
    # MAC Address String in Hex-Decimal Format can be delimited with 
    # dot, dash or colon (or none)
    [String]$MacAddressString = "AA:BB:CC:DD:EE:FF",
    [String]$UUIDString = "AABBCCDD-AABB-AABB-AABB-AABBCCDDEEFF",
    #Possible Processor Architecture values here: https://www.iana.org/assignments/dhcpv6-parameters/processor-architecture.csv
    # x86-x64 Bios = 0
    # x86 UEFI = 6
    # x64 UEFI = 7
    # xEFIBC = 9
    [string]$Option60String = "PXEClient",
    [int]$ProcessorArchitecture  = 0, 
    # Length of time (in seconds) to spend waiting for Offers if
    # the connection does not timeout first
    [Byte]$DiscoverTimeout = 60
  )
   
  # Build a DHCPDISCOVER packet to send
  #
  # Caller: Main
   
  Function New-DhcpDiscoverPacket {
    Param(
      [String]$MacAddressString = "AA:BB:CC:DD:EE:FF"
    )
    # Generate a Transaction ID for this request
    $XID = New-Object Byte[] 4
    $Random = New-Object Random
    $Random.NextBytes($XID)
    # Convert the MAC Address String into a Byte Array
    # Drop any characters which might be used to delimit the string
    $MacAddressString = $MacAddressString -Replace "-|:" 
    $MacAddress = [BitConverter]::GetBytes(([UInt64]::Parse($MacAddressString, [Globalization.NumberStyles]::HexNumber)))
    # Reverse the MAC Address array
    [Array]::Reverse($MacAddress)
    # Create the Byte Array
    $DhcpDiscover = New-Object Byte[] 243
    # Copy the Transaction ID Bytes into the array
    [Array]::Copy($XID, 0, $DhcpDiscover, 4, 4)
    # Copy the MacAddress Bytes into the array (drop the first 2 bytes, 
    # too many bytes returned from UInt64)
    [Array]::Copy($MACAddress, 2, $DhcpDiscover, 28, 6)
    # Set the OP Code to BOOTREQUEST
    $DhcpDiscover[0] = 1
    # Set the Hardware Address Type to Ethernet
    $DhcpDiscover[1] = 1
    # Set the Hardware Address Length (number of bytes)
    $DhcpDiscover[2] = 6
    # Set the Broadcast Flag
    $DhcpDiscover[10] = 128
    # Set the Magic Cookie values
    $DhcpDiscover[236] = 99
    $DhcpDiscover[237] = 130
    $DhcpDiscover[238] = 83
    $DhcpDiscover[239] = 99
    # Set the DHCPDiscover Message Type Option
    $DhcpDiscover[240] = 53
    $DhcpDiscover[241] = 1
    $DhcpDiscover[242] = 1
    # Set the Option #60
    $DhcpDiscover_Option60 = New-Object Byte[] 2
    $DhcpDiscover_Option60[0] = 60
    $DhcpDiscover_Option60[1] = [System.Text.Encoding]::ASCII.GetBytes($Option60String).Length;
    $Option60Array = [System.Text.Encoding]::ASCII.GetBytes($Option60String);
    $DhcpDiscover_Option60 = $DhcpDiscover_Option60 + $Option60Array;
    $DhcpDiscover = $DhcpDiscover + $DhcpDiscover_Option60;
    # Set the Option #93
    $DhcpDiscover_Option93 = New-Object Byte[] 4
    $DhcpDiscover_Option93[0] = 93
    $DhcpDiscover_Option93[1] = 2
    $DhcpDiscover_Option93[2] = 0
    $DhcpDiscover_Option93[3] = $ProcessorArchitecture
    $DhcpDiscover = $DhcpDiscover + $DhcpDiscover_Option93;
    # Set the Option #97
    $DhcpDiscover_Option97 = New-Object Byte[] 2
    $DhcpDiscover_Option97[0] = 97
    $DhcpDiscover_Option97[1] = 36 #Length of UUID
    $UUIDarray = [System.Text.Encoding]::ASCII.GetBytes($UUIDString);
    $DhcpDiscover_Option97 = $DhcpDiscover_Option97 + $UUIDarray;
    $DhcpDiscover = $DhcpDiscover + $DhcpDiscover_Option97;
    Return $DhcpDiscover
  }
   
  # Parse a DHCP Packet, returning an object containing each field
  # 
  # Caller: Main
   
  Function Read-DhcpPacket( [Byte[]]$Packet ) {
    $Reader = New-Object IO.BinaryReader(New-Object IO.MemoryStream(@(,$Packet)))
    $DhcpResponse = New-Object Object
    # Get and translate the Op code
    $DhcpResponse | Add-Member NoteProperty Op $Reader.ReadByte()
    if ($DhcpResponse.Op -eq 1) { 
      $DhcpResponse.Op = "BootRequest" 
    } 
    else { 
      $DhcpResponse.Op = "BootResponse" 
    }
    $DhcpResponse | Add-Member NoteProperty HType -Value $Reader.ReadByte()
    if ($DhcpResponse.HType -eq 1) { $DhcpResponse.HType = "Ethernet" }
    $DhcpResponse | Add-Member NoteProperty HLen $Reader.ReadByte()
    $DhcpResponse | Add-Member NoteProperty Hops $Reader.ReadByte()
    $DhcpResponse | Add-Member NoteProperty XID $Reader.ReadUInt32()
    $DhcpResponse | Add-Member NoteProperty Secs $Reader.ReadUInt16()
    $DhcpResponse | Add-Member NoteProperty Flags $Reader.ReadUInt16()
    # Broadcast is the only flag that can be present, the other bits are reserved
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
    # Start reading Options
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
          # Read as Big Endian
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
          # Read as Big Endian
          $Value = ($Reader.ReadByte() * [Math]::Pow(256, 3)) + ($Reader.ReadByte() * [Math]::Pow(256, 2)) + ($Reader.ReadByte() * 256) + $Reader.ReadByte()
          $Option.OptionValue = $(New-TimeSpan -Seconds $Value) 
        }
        59 {
          $Option.OptionName = "RebindingTime"
          # Read as Big Endian
          $Value = ($Reader.ReadByte() * [Math]::Pow(256, 3)) + ($Reader.ReadByte() * [Math]::Pow(256, 2)) + ($Reader.ReadByte() * 256) + $Reader.ReadByte()
          $Option.OptionValue = $(New-TimeSpan -Seconds $Value) 
        }
        67 {
          $Option.OptionName = "vendor-class-identifier"
          # Read as Big Endian
          $Value = ($Reader.ReadByte() * [Math]::Pow(256, 3)) + ($Reader.ReadByte() * [Math]::Pow(256, 2)) + ($Reader.ReadByte() * 256) + $Reader.ReadByte()
          $Option.OptionValue = $(New-TimeSpan -Seconds $Value) 
        }
        255 { 
          $Option.OptionName = "EndOption" 
        }
        default {
          # For all options which are not decoded here
          $Option.OptionName = "NoOptionDecode"
          $Buffer = New-Object Byte[] $Option.Length
          [Void]$Reader.Read($Buffer, 0, $Option.Length)
          $Option.OptionValue = $Buffer
        }
      }
      # Override the ToString method
      $Option | Add-Member ScriptMethod ToString { Return "$($this.OptionName) ($($this.OptionValue))" } -Force
      $DhcpResponse.Options += $Option
    }
   
    Return $DhcpResponse
  }
   
  # Create a UDP Socket with Broadcast and Address Re-use enabled.
  #
  # Caller: Main
   
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
   
  # Close down a Socket
  #
  # Caller: Main
   
  Function Remove-Socket {
    Param(
      [Net.Sockets.Socket]$Socket
    )
    $Socket.Shutdown("Both")
    $Socket.Close()
  }
   
  #
  # Main
  #
   
  # Create a Byte Array for the DHCPDISCOVER packet
  $Message = New-DhcpDiscoverPacket -Send 10 -Receive 10
  # Create a socket
  $UdpSocket = New-UdpSocket
  # UDP Port 68 (Server-to-Client port)
  $EndPoint = [Net.EndPoint](New-Object Net.IPEndPoint($([Net.IPAddress]::Any, 68)))
  # Listen on $EndPoint
  $UdpSocket.Bind($EndPoint)
  # UDP Port 67 (Client-to-Server port)
  $EndPoint = [Net.EndPoint](
  New-Object Net.IPEndPoint($([Net.IPAddress]::Broadcast, 67)))
  # Send the DHCPDISCOVER packet
  $BytesSent = $UdpSocket.SendTo($Message, $EndPoint)
  # Begin receiving and processing responses
  $NoConnectionTimeOut = $True
  $Start = Get-Date
  While ($NoConnectionTimeOut) {
    $BytesReceived = 0
    Try {
      # Placeholder EndPoint for the Sender
      $SenderEndPoint = [Net.EndPoint](New-Object Net.IPEndPoint($([Net.IPAddress]::Any, 0)))
      # Receive Buffer
      $ReceiveBuffer = New-Object Byte[] 1024
      $BytesReceived = $UdpSocket.ReceiveFrom($ReceiveBuffer, [Ref]$SenderEndPoint)
    }
    #
    # Catch a SocketException, thrown when the Receive TimeOut value is reached
    #
    Catch [Net.Sockets.SocketException] {
      $NoConnectionTimeOut = $False
    }
    If ($BytesReceived -gt 0) {
       Read-DhcpPacket $ReceiveBuffer[0..$BytesReceived]
    }
    If ((Get-Date) -gt $Start.AddSeconds($DiscoverTimeout)) {
      # Exit condition, not error condition
      $NoConnectionTimeOut = $False
    }
  }
  Remove-Socket $UdpSocket
}