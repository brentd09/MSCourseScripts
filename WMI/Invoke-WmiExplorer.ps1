<#
.SYNOPSIS
  Finds current settings for WMI classes
.DESCRIPTION
  This is a GUI that mimics the WMI scriptomatic tools but shows the information 
  directly in the GUI 
.NOTES
  General notes
  Created By: Brent Denny
  Created on: 10-Jan-2019
#>
[CmdletBinding()]
Param()

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$FormWMIExplorer                 = New-Object system.Windows.Forms.Form
$FormWMIExplorer.ClientSize      = '713,560'
$FormWMIExplorer.text            = "Brents WMI Explorer"
$FormWMIExplorer.TopMost         = $false

$ComboBoxNameSpace                = New-Object system.Windows.Forms.ComboBox
$ComboBoxNameSpace.text           = "listBox"
$ComboBoxNameSpace.width          = 277
$ComboBoxNameSpace.height         = 30
$ComboBoxNameSpace.location       = New-Object System.Drawing.Point(14,44)

$ComboBoxClass                    = New-Object system.Windows.Forms.ComboBox
$ComboBoxClass.text               = "listBox"
$ComboBoxClass.width              = 378
$ComboBoxClass.height             = 30
$ComboBoxClass.location           = New-Object System.Drawing.Point(312,44)

$labelNameSpace                  = New-Object system.Windows.Forms.Label
$labelNameSpace.text             = "Namespace"
$labelNameSpace.AutoSize         = $true
$labelNameSpace.width            = 25
$labelNameSpace.height           = 10
$labelNameSpace.location         = New-Object System.Drawing.Point(19,26)
$labelNameSpace.Font             = 'Microsoft Sans Serif,10'

$labelClass                      = New-Object system.Windows.Forms.Label
$labelClass.text                 = "Class"
$labelClass.AutoSize             = $true
$labelClass.width                = 25
$labelClass.height               = 10
$labelClass.location             = New-Object System.Drawing.Point(317,26)
$labelClass.Font                 = 'Microsoft Sans Serif,10'

$labelClassRefresh               = New-Object system.Windows.Forms.Label
$labelClassRefresh.text          = 'test'
$labelClassRefresh.AutoSize      = $true
$labelClassRefresh.width         = 25
$labelClassRefresh.height        = 10
$labelClassRefresh.location      = New-Object System.Drawing.Point(317,70)
$labelClassRefresh.Font          = 'Microsoft Sans Serif,10'



$ListViewOutput                  = New-Object system.Windows.Forms.ListView
$ListViewOutput.text             = "listView"
$ListViewOutput.width            = 675
$ListViewOutput.height           = 411
$ListViewOutput.location         = New-Object System.Drawing.Point(14,115)

$labelClassContents              = New-Object system.Windows.Forms.Label
$labelClassContents.text         = "Class Details"
$labelClassContents.AutoSize     = $true
$labelClassContents.width        = 25
$labelClassContents.height       = 10
$labelClassContents.location     = New-Object System.Drawing.Point(19,93)
$labelClassContents.Font         = 'Microsoft Sans Serif,10'

$FormWMIExplorer.controls.AddRange(@($ComboBoxNameSpace,$ComboBoxClass,$labelNameSpace,$labelClass,$labelClassRefresh,$ListViewOutput,$labelClassContents))

$ComboBoxNameSpace.Add_SelectedValueChanged({
  $ComboBoxClass.DataSource = @('')
  $labelClassRefresh.ForeColor = '#d0021b'  
  $labelClassRefresh.Text = "Please Wait while class list refreshes" 
  $CurrentNameSpace = "root\"+$ComboBoxNameSpace.SelectedValue
  $ComboBoxClass.DataSource = (Get-WmiObject -namespace $CurrentNameSpace -list | Where-Object {$_.name -notlike "__*"}).name 
  $labelClassRefresh.Text = ""
})

$ComboBoxClass.Add_SelectedValueChanged({
  $SelectedValue = $ComboBoxClass.SelectedValue
  if ($SelectedValue) {
    $ClassDetails = Get-WmiObject -Namespace $CurrentNameSpace -Class $SelectedValue | Select-Object -Property *
    $ListViewOutput.text = $ClassDetails | Out-String
  }
})

$FormWMIExplorer.Add_Shown({
  $NameSpaces = Get-WMIObject -namespace "root" -class "__Namespace" | Sort-Object -Property name
  $ComboBoxNameSpace.DataSource = $NameSpaces.name
  $ComboBoxNameSpace.SelectedItem = "CIMV2"
})

$FormWMIExplorer.ShowDialog()