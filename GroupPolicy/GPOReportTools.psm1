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
  .EXAMPLE
    Invoke-GPOSettingReport -ReportDirectory 'e:\reports' -DomainName 'adatum.com' -ReportType 'html' -SelectGPOs
    This will get the GPOs from the adatum.com domain and present a gui tool to select which 
    GPOs to create reports for, this will then create a file per GPO in the E:\Reports folder.    
  .EXAMPLE
    Invoke-GPOSettingReport -ReportDirectory 'e:\reports' -DomainName 'adatum.com' -ReportType 'html' -BackupGpo
    This will get the GPOs from the adatum.com domain and create reports for
    all of them in the E:\Reports folder, it will also do a backup of the GPOs 
    that can be restored later the backup will be stored in the same E:\Reports folder.    
  .PARAMETER ReportDirectory
    This is the directory that the reports will be created in, the 
    default value for this parameter is the users TMP directory found
    by using [System.IO.Path]::GetTempPath() path
  .PARAMETER DomainName
    This is the DNS FQDN of the Active Directory domain name that the 
    GPOs will be reported on.
  .PARAMETER ReportType
    There is only two choices; either HTML or XML
  .PARAMETER SelectGPOs
    This parameter flags this command to prompt via a Out-GridView GUI
    to choose which of the GPOs will have reports created
  .PARAMETER BackupGPO
    This parameter flags this command create a backup of the GPO and store
    it in the same directory as the report
  .NOTES
    General notes
      Created by : Brent Denny
      Created on : 23-Apr-2021
      Modified on: 24-Apr-2021
  #>
  [CmdletBinding()]
  Param (
    [string]$ReportDirectory = ([System.IO.Path]::GetTempPath()),
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    [ValidateSet('html','xml')]
    [string]$ReportType = 'html',
    [switch]$SelectGPOs,
    [switch]$BackupGPO
  )
  try {$AllGPOs = Get-Gpo -Domain $DomainName -All -ErrorAction Stop}
  catch {Write-Warning "The GPOs could not be obtained from the system";break}  
  if ($SelectGPOs -eq $true) {
    $GPOs = $AllGPOs | 
    Select-Object -Property DisplayName,ID | 
    Out-GridView -OutputMode Multiple -Title "Choose Which GPOs you wish to create reports for" 
  }
  else {$GPOs = $AllGPOs}
  if ($GPOs.Count -eq 0) {Write-Warning "You must select at least one GPO";break}
  if (-not (Test-Path -Path $ReportDirectory -PathType Container)) {
    $Parent = $ReportDirectory | Split-Path -Parent 
    $Leaf = $ReportDirectory | Split-Path -leaf
    try {New-Item -Path $Parent -Name $Leaf -ItemType Directory -ErrorAction Stop | Out-Null}
    catch {Write-Warning -Message "$ReportDirectory cound not be created";break}
  }
  foreach ($GPO in $GPOs) {
    $ReportFilePath =  $ReportDirectory.TrimEnd('\') + '\' + $GPO.Displayname + ".$ReportType"
    Get-GpoReport -Guid $GPO.Id -ReportType $ReportType | Out-File -FilePath $ReportFilePath
    if ($BackupGPO -eq $true) {Backup-Gpo -Guid $GPO.Id -Path $ReportDirectory -Domain $DomainName -Comment "Backup of $($GPO.Displayname)" | Out-Null}
  }
}

function Get-GPOLinkReport {
<#
  .Synopsis
     This command reports on all GPOs and where they are linked
  .DESCRIPTION
     This command will report on the GPOs that are found in a 
     given domain and server and will report GPO Name, GUID, and Links
  .PARAMETER Domain
     This parameter will search in the Active Directory domain 
     specified to find the GPOs to create the report
  .PARAMETER ComputerName
     This parameter targets a specific Domain Controller in the 
     domain to create the report
  .EXAMPLE
     Get-GPOLinkReport -Domain adatum.com -Server LON-DC1
     This will inspect the GPOs that exist in the adatum domain
     and create a report that shows where they are linked
  .NOTES
     General notes
     Created By: Brent Denny
     Created On: 19-Jun-2024
  #>
  [CmdletBinding()]
  Param (
    [string]$Domain = '',
    [string]$ComputerName = '' 
  )
  [System.Collections.ArrayList]$GPRept = @()
  if ($Domain -eq '') {
    if ($ComputerName -eq '') {$AllGpo = Get-GPO -All}
    else {$AllGpo = Get-GPO -All -Server $ComputerName}
  elseif ($ComputerName -eq '') {$AllGpo = Get-GPO -All -Domain $Domain }
  else {$AllGpo = Get-GPO -All -Domain $Domain -Server $ComputerName}
  }
  $AllGpo = Get-GPO -All -Domain $Domain -Server $ComputerName
  foreach ($Gpo in $AllGpo) {
    $GPOInfo = $Gpo | Get-GPO  -Domain $Domain -Server $ComputerName
    [XML]$GroupPolicy = $Gpo | Get-GPOReport -ReportType XML
    $GPLinkInfo = [PSCustomObject]@{
      GpoName = $GroupPolicy.GPO.Name
      GpoGUID = $GPOInfo.ID
      Links   = $GroupPolicy.GPO.LinksTo.SOMPath
    }
    $GPRept.Add($GPLinkInfo)
  }
  $GPRept | Sort-Object -Property GpoName
}
