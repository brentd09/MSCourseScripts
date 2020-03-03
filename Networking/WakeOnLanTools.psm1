function Send-WakeOnLan {
  <# 
    .SYNOPSIS  
      This command sends a broadcast WakeOnLan packet
    .DESCRIPTION
      This command will send a WakeOnLan packet to a MAC and IPAddress however
      the IPAddress is optional. The computer that you are sending the WOL packet 
      to must be configured in the BIOS not to go into deep sleep, so that when 
      it is shut down the NIC is still active.
      For DELL BIOS make sure these settings are in place:
      Enable USB Wake Support - Enabled
      Deep Sleep - Disabled  
      Wake On LAN - Enabled OR Enabled with PXE Boot
    .PARAMETER MACAddress
      The MAC address of the device that need to wake up
    .PARAMETER IPAddress
      The IPAddress address where the WOL packet will be sent to
    .EXAMPLE 
      Send-WakeOnLan -MACAddress 00:11:32:21:2D:11 
    .EXAMPLE 
      Send-WakeOnLan -MACAddress 00:11:32:21:2D:11,00:11:32:21:2E:15       
  #>
  
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$True,Position=1,
               ValueFromPipeline,
               ValueFromPipelineByPropertyName)]
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