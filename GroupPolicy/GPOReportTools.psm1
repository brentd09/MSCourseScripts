function Invoke-GPOSettingsReport {
  <#
  .SYNOPSIS
    This creates GPO reports for all of the GPOs in your domain
  .DESCRIPTION
    This creates either HTML or XML Group Policy reports from your
    domain and will create a file per GPO that we are making the 
    report for. If you do not specify a report folder as a parameter
    it will drop the files in the temp folder on your system 
    using the .net [System.IO.Path]::GetTempPath() path.
    Each file will be labelled as the GPO's Display Name and will
    have an extension of either html or xml, the default is html. 
  .EXAMPLE
    Invoke-GPOSettingsReport -ReportDirectory 'e:\reports' -DomainName 'adatum.com' -ReportType 'html'
    This will get the GPOs from the adatum.com domain and create a file per GPO 
    in the E:\Reports folder.
  .NOTES
    General notes
      Created by : Brent Denny
      Created on : 23-Apr-2021
      Modified on: 23-Apr-2021
  #>
  [CmdletBinding()]
  Param (
    [string]$ReportDirectory = ([System.IO.Path]::GetTempPath()),
    [string]$DomainName,
    [ValidateSet('html','xml')]
    [string]$ReportType = 'html'
  )
  try {$AllGPOs = Get-Gpo -Domain $DomainName -All -ErrorAction Stop}
  catch {Write-Warning "The GPOs could not be obtained from the system";break} 
  if (-not (Test-Path -Path $ReportDirectory -PathType Container)) {
    $Parent = $ReportDirectory | Split-Path -Parent 
    $Leaf = $ReportDirectory | Split-Path -leaf
    try {New-Item -Path $Parent -Name $Leaf -ItemType Directory -ErrorAction Stop}
    catch {Write-Warning -Message "$ReportDirectory cound not be created";break}
  }
  foreach ($GPO in $AllGPOs) {
    $ReportFilePath =  $ReportDirectory.TrimEnd('\') + '\' + $GPO.Displayname + ".$ReportType"
    Get-GpoReport -Guid $GPO.Id -ReportType $ReportType | Out-File -FilePath $ReportFilePath
  }
}
