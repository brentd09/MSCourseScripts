<#
.SYNOPSIS
  Gets or reports on the SMBv1 availability within your domain
.DESCRIPTION
  Long description
.EXAMPLE
  Remove-SMBv1DomainWide
  This finds all computers in the domain and removes the SMBv1 dialect 
  from each of them..
.EXAMPLE
  Remove-SMBv1DomainWide -ReportOnly
  This finds all computers in the domain and reports on their SMBv1 
  dialect status
.NOTES
  General notes
  Created by: Brent Denny
  Created on: 26 Mar 2019
#>
[CmdletBinding()]
Param (
  [switch]$ReportOnly,
  [switch]$EnableSMBv1
)
try {
  $Computers = Get-AdComputer -filter * -ErrorAction Stop
  foreach ($Computer in $Computers) {
    try {
      Invoke-Command -ComputerName $Computer.Name -ErrorAction Stop -ScriptBlock {
        $SMBServerConfig = Get-SmbServerConfiguration
        if ($SMBServerConfig.EnableSMB1Protocol -eq (-not $Using:EnableSMBv1) -and $Using:ReportOnly -eq $false) {
          Set-SmbServerConfiguration -EnableSMB1Protocol $Using:EnableSMBv1 -Confirm:$false
        }
        Get-SmbServerConfiguration
      } | Select-Object -Property @{n='ComputerName';e={$_.PSComputerName}},@{n='SMB1Enabled';e={$_.EnableSMB1Protocol}}
    }
    catch {
      $props = @{
        ComputerName = $Computer.Name
        SMB1Enabled = "Unknown"
      }
      new-object -TypeName psobject -Property $props
    }
  }
} 
Catch {
  Write-Warning "This script needs to be run from a machine that has the ActiveDirectory Module installed"
}
