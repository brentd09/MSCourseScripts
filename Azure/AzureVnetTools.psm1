function Get-AzPeeringType {
  <#
  .SYNOPSIS
    Lists all of the Azure virtual networks peerings and determines their type
  .DESCRIPTION
    This cmdlet finds all of the virtual networks that have peerings and 
    determines if the peering is a global or regional type of peering. 
    It will also show Virtual Networks that do not have any peerings as 
    well. 
    There are restrictions on what you can do with a global peering 
    so it is important to know which peering is what type.
    This command will prompt you if you need to login to Azure via a 
    Connect-AzAccount command
  .EXAMPLE
    Get-AzPeeringType
    This will show all peerings (Global, Regional and NoPeering).
  .EXAMPLE
    Get-AzPeeringType -PeeringFilter Global
    This will only show peerings of a Global type   
  .EXAMPLE
    Get-AzPeeringType -PeeringFilter NoPeering
    This will only show VNets that do not have any peering configured       
  .PARAMETER PeeringFilter
    This will filter the peerings so that either a single peering type
    is shown or all are shown. The values for the PeeringFilter are:
    Regional - Shows only Regional
    Global - Shows only Global
    All - Shows all types of peering
    NoPeering - Shows only VNets with no peerings 
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 6 May 2020
      Last Modified: 1 Jul 2020
  #>
  [cmdletbinding()]
  Param(
    [ValidateSet('Regional','Global','All','NoPeering')]
    [string]$PeeringFilter = 'All'
  )
  try {Get-AzSubscription -ErrorAction Stop > $null}
  catch {Connect-AzAccount}
  try {
    $VNets = Get-AzVirtualNetwork -ErrorAction Stop
    foreach ($VNet in $VNets){
      if ($VNet.VirtualNetworkPeerings.Count -ge 1) {
        $Peerings = $VNet.VirtualNetworkPeerings
        foreach ($Peering in $Peerings) {
          $PeerID = $Peering.remotevirtualnetwork.Id
          $PeerName = $PeerID -replace '.+\/(.+)$','$1'
          $PeerVNetInfo = $VNets | Where-Object {$_.Id -eq $PeerID}
          $PeerVNetLocation = $PeerVNetInfo.Location
          if ($VNet.Location -eq $PeerVNetLocation) {$PeerType = 'Regional'}
          else {$PeerType = 'Global'}
          if ($PeeringFilter -eq $PeerType -or $PeeringFilter -eq 'All') {
            $Hash = [ordered]@{
              VNetName = $VNet.Name
              ResourceGroup = $VNet.ResourceGroupName
              VNetLocation = $VNet.Location
              PeeringVNet = $PeerName
              PeeringVNetLocation = $PeerVNetLocation
              PeeringType = $PeerType
              VNetID = $VNet.Id
            }
            New-Object -TypeName psobject -Property $Hash   
          }
        }
      }
      else {
        if ($PeeringFilter -eq 'NoPeering' -or $PeeringFilter -eq 'All') {
          $Hash = [ordered]@{
            VNetName = $VNet.Name
            ResourceGroup = $VNet.ResourceGroupName
            VNetLocation = $VNet.Location
            PeeringVNet = 'No Peerings'
            PeeringVNetLocation = 'N/A'
            PeeringType = 'N/A'
            VNetID = $VNet.Id
          }
          New-Object -TypeName psobject -Property $Hash    
        }       
      }  
    }
  }  
  catch { Write-Warning 'An error occured trying to access the Virtual Networks'}
}

function Find-AzureSubnetting {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.Application]::EnableVisualStyles()
  
  $Form                            = New-Object system.Windows.Forms.Form
  $Form.ClientSize                 = New-Object System.Drawing.Point(521,625)
  $Form.text                       = "Azure VNet Address Calculator"
  $Form.TopMost                    = $false
  
  $VNetOctet1                      = New-Object system.Windows.Forms.TextBox
  $VNetOctet1.multiline            = $false
  $VNetOctet1.width                = 53
  $VNetOctet1.height               = 40
  $VNetOctet1.location             = New-Object System.Drawing.Point(50,70)
  $VNetOctet1.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $VNetOctet2                      = New-Object system.Windows.Forms.TextBox
  $VNetOctet2.multiline            = $false
  $VNetOctet2.width                = 53
  $VNetOctet2.height               = 40
  $VNetOctet2.location             = New-Object System.Drawing.Point(120,70)
  $VNetOctet2.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $VNetOctet3                      = New-Object system.Windows.Forms.TextBox
  $VNetOctet3.multiline            = $false
  $VNetOctet3.width                = 53
  $VNetOctet3.height               = 40
  $VNetOctet3.location             = New-Object System.Drawing.Point(190,70)
  $VNetOctet3.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $VNetOctet4                      = New-Object system.Windows.Forms.TextBox
  $VNetOctet4.multiline            = $false
  $VNetOctet4.width                = 53
  $VNetOctet4.height               = 40
  $VNetOctet4.location             = New-Object System.Drawing.Point(260,70)
  $VNetOctet4.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $VNetCIDR                        = New-Object system.Windows.Forms.TextBox
  $VNetCIDR.multiline              = $false
  $VNetCIDR.width                  = 53
  $VNetCIDR.height                 = 40
  $VNetCIDR.location               = New-Object System.Drawing.Point(350,70)
  $VNetCIDR.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $Label1                          = New-Object system.Windows.Forms.Label
  $Label1.text                     = "."
  $Label1.AutoSize                 = $true
  $Label1.width                    = 25
  $Label1.height                   = 10
  $Label1.location                 = New-Object System.Drawing.Point(109,80)
  $Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
  
  $Label2                          = New-Object system.Windows.Forms.Label
  $Label2.text                     = "."
  $Label2.AutoSize                 = $true
  $Label2.width                    = 25
  $Label2.height                   = 10
  $Label2.location                 = New-Object System.Drawing.Point(180,80)
  $Label2.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
  
  $Label3                          = New-Object system.Windows.Forms.Label
  $Label3.text                     = "."
  $Label3.AutoSize                 = $true
  $Label3.width                    = 25
  $Label3.height                   = 10
  $Label3.location                 = New-Object System.Drawing.Point(250,80)
  $Label3.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
  
  $Label5                          = New-Object system.Windows.Forms.Label
  $Label5.text                     = "/"
  $Label5.AutoSize                 = $true
  $Label5.width                    = 25
  $Label5.height                   = 10
  $Label5.location                 = New-Object System.Drawing.Point(330,77)
  $Label5.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
  
  $Label4                          = New-Object system.Windows.Forms.Label
  $Label4.text                     = "Azure VNet Address Space"
  $Label4.AutoSize                 = $true
  $Label4.width                    = 29
  $Label4.height                   = 22
  $Label4.location                 = New-Object System.Drawing.Point(63,40)
  $Label4.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $Label6                          = New-Object system.Windows.Forms.Label
  $Label6.text                     = "CIDR Mask for Subnet"
  $Label6.AutoSize                 = $true
  $Label6.width                    = 25
  $Label6.height                   = 20
  $Label6.location                 = New-Object System.Drawing.Point(65,129)
  $Label6.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $CIDRMask                        = New-Object system.Windows.Forms.TextBox
  $CIDRMask.multiline              = $false
  $CIDRMask.width                  = 54
  $CIDRMask.height                 = 20
  $CIDRMask.location               = New-Object System.Drawing.Point(258,123)
  $CIDRMask.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $SubnetList                      = New-Object system.Windows.Forms.ListBox
  $SubnetList.text                 = "listBox"
  $SubnetList.width                = 414
  $SubnetList.height               = 400
  $SubnetList.location             = New-Object System.Drawing.Point(48,177)
  $SubnetList.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  
  $Calc                            = New-Object system.Windows.Forms.Button
  $Calc.text                       = "Calculate"
  $Calc.width                      = 90
  $Calc.height                     = 30
  $Calc.location                   = New-Object System.Drawing.Point(393,119)
  $Calc.Font                       = New-Object System.Drawing.Font('Microsoft Sans Serif',13)
  $Calc.ForeColor                  = [System.Drawing.ColorTranslator]::FromHtml("#000000")
  $Calc.BackColor                  = [System.Drawing.ColorTranslator]::FromHtml("#b8e986")
  
  $Form.controls.AddRange(@($VNetOctet1,$VNetOctet2,$VNetOctet3,$VNetOctet4,$VNetCIDR,$Label1,$Label2,$Label3,$Label5,$Label4,$Label6,$CIDRMask,$SubnetList,$Calc))
  
  $Calc.Add_Click({ Calcfn })
  
  function Calcfn { 
    # test if IP is valid 
    # test if IP is valid with VNet snm
    # Create subnets based on subnet mask
    # Add subnets to list
    [ipaddress]$VnetIP = $VNetOctet1.Text + '.' + $VNetOctet2.Text + '.' + $VNetOctet3.Text + '.' + $VNetOctet4.Text 
    $SubnetList.Items.Add($VnetIP.IPAddressToString)
  } 
  
  [void]$Form.ShowDialog()
}