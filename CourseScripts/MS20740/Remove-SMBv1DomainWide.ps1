<#
.SYNOPSIS
  Sets or reports the SMBv1 availability within your domain.
.DESCRIPTION
  This script can disable or enable and report on the SMBv1 usage on the
  computers within your domain. This command can only be run where the 
  ActiveDirectory module can be loaded as it searches the domain controllers
  for knowledge of the computers within that domain. Once it enables or 
  diasbles the SMBv1 dialect it will then report on each computer's status,
  if it can not find a computer that is listed in the domain a report of 
  UNKNOWN status will be shown.
.PARAMETER ReportOnly
  Reports on the status of the SMBv1 dialect on every machine in the domain.
.PARAMETER EnableSMBv1
  Enables the SMBv1 dialect on every computer in the domain that currently
  has it disabled. Without this parameter the command will remove the SMBv1
  dialect from all the domain computers that have it enabled.
.EXAMPLE
  Remove-SMBv1DomainWide
  This finds all computers in the domain and disables the SMBv1 dialect 
  from each of them.
.EXAMPLE
  Remove-SMBv1DomainWide -ReportOnly
  This finds all computers in the domain and reports on their SMBv1 
  dialect status.
.EXAMPLE
  Remove-SMBv1DomainWide -EnableSMBv1
  This finds all computers in the domain, enables SMBv1 and reports 
  on all computers SMBv1 dialect status.
.NOTES
  General notes
  Created by: Brent Denny
  Created on: 26 Mar 2019
  Modified  : 27 Mar 2019 Allowed for enableing and disabling, also added fuller help content
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
