function Add-CMNamesToCollection {
  <#
  .SYNOPSIS
     Add Computers into a Device Collection
  .DESCRIPTION
     This adds a list of computers into a Device Collection from a text file
     the text file must contain only the names of each computer and each
     computername must be on a seperate line. If the Collection exists it just
     adds the computers to that collection if not it will create the collection
     first.
  .PARAMETER SiteCode
     This requires the thee character site code for SCCM
  .PARAMETER CollectionName
     This requires the name of the SCCM collection that will either be created or added to
  .PARAMETER FileName
     This requires the filename of the file containing the computernames that will
     be used to add to the collection
  .PARAMETER LimitingCollection
     This is an optional parameter that will specify the limiting collection used to
     initially create the collection
  .EXAMPLE
     Add-CMNamesToCollection -SiteCode S01 -CollectionName Coll001 -FileName c:\computers.txt
     This example shows the requred parameters for this command. The limiting collection will 
     be automatically set to All Systems by default.
  .EXAMPLE
     Add-CMNamesToCollection -SiteCode S01 -CollectionName Coll001 -FileName c:\computers.txt -LimitingCollection "All Systems"
     This example allows us to add a limiting collection to initialise the new collection
  .NOTES
     General Notes
     Created by: Brent Denny
     Created on: 7 Jan 2019
  #>
  [cmdletbinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$SiteCode,
    [Parameter(Mandatory=$true)]
    [string]$CollectionName,
    [Parameter(Mandatory=$true)]
    [string]$Filename,
    [string]$LimitingCollection = "All Systems"
  )
  $SiteCode = $SiteCode -replace "^(\w{3}).*",'$1'
  $SiteCodeDrive = $SiteCode + ':'
  $CurrentModulesLoaded = Get-Module
  $CurrentPSDrives = Get-PSDrive
  #Check if this script is running from a PS window on the SCCM site server
  if ($CurrentModulesLoaded.Name -contains 'ConfigurationManager' -and $CurrentPSDrives.Name -contains $SiteCode) {
    Set-Location $SiteCodeDrive
    $CurrentCollections =  Get-CMCollection
    if ($CurrentCollections.name -notcontains $CollectionName) {
      try {
        $Collection = New-CMDeviceCollection -Name $CollectionName -LimitingCollectionName $LimitingCollection -ErrorAction 'Stop'
      }
      catch {
        Write-Warning "There was a problem creating the Collection- $CollectionName, with the limiting collection- $LimitingCollection"
        break
      }
    }
    else {
      $Collection = Get-CMCollection | Where-Object {$_.Name -eq $CollectionName}
    }
    $PCsFromTexFile = Get-Content $Filename | where-Object {$_ -match '\w'}
    $DevicesToAddToCollection = Get-CMResource -Fast | Where-Object {$_.Name -in $PcsFromTexFile}
    if ($DevicesToAddToCollection.Count -gt 0) {
      foreach ($Device in $DevicesToAddToCollection) {
        Add-CMDeviceCollectionDirectMembershipRule -CollectionId $Collection.CollectionID -ResourceID $Device.ResourceID 
      }
    }
    elseif ($DevicesToAddToCollection.Count -eq 0) {
      Write-Warning 'There were no matching computer objects found to add to the collection'
      break
    }
    if ($DevicesToAddToCollection.Count -ne $PCsFromTexFile.Count) {
      Write-Warning 'Not all computers were found in Confiruation Manager'
    }
  }
  else {
    Write-Warning "This needs to be run from a Configuation Manager Powershell window!"
  }
}

function Start-CMClientAction {
  <#
    .SYNOPSIS
      This Triggers the SCCM Client actions
    .DESCRIPTION
      This script was written for those that want to trigger all of the client actions without having
      go to the control panel and run each task one by one
    .EXAMPLE
      Start-CMClientAction
    .EXAMPLE
      Start-CMClientAction -ComputerName LON-CL1,LON-CL2
    .NOTES
      General notes
      Created by: Brent Denny
      Created on: 25 Oct 2018
  #>
  [cmdletbinding()]
  Param(
    [string[]]$ComputerName = $env:COMPUTERNAME
  )

$ClientActions = @'
GUID,Name
{00000000-0000-0000-0000-000000000001},Hardware Inventory
{00000000-0000-0000-0000-000000000002},Software Inventory 
{00000000-0000-0000-0000-000000000003},Discovery Inventory 
{00000000-0000-0000-0000-000000000010},File Collection 
{00000000-0000-0000-0000-000000000011},IDMIF Collection 
{00000000-0000-0000-0000-000000000012},Client Machine Authentication 
{00000000-0000-0000-0000-000000000021},Request Machine Assignments 
{00000000-0000-0000-0000-000000000022},Evaluate Machine Policies 
{00000000-0000-0000-0000-000000000023},Refresh Default MP Task 
{00000000-0000-0000-0000-000000000024},LS (Location Service) Refresh Locations Task 
{00000000-0000-0000-0000-000000000025},LS (Location Service) Timeout Refresh Task 
{00000000-0000-0000-0000-000000000026},Policy Agent Request Assignment (User) 
{00000000-0000-0000-0000-000000000027},Policy Agent Evaluate Assignment (User) 
{00000000-0000-0000-0000-000000000031},Software Metering Generating Usage Report 
{00000000-0000-0000-0000-000000000032},Source Update Message
{00000000-0000-0000-0000-000000000037},Clearing proxy settings cache 
{00000000-0000-0000-0000-000000000040},Machine Policy Agent Cleanup 
{00000000-0000-0000-0000-000000000041},User Policy Agent Cleanup
{00000000-0000-0000-0000-000000000042},Policy Agent Validate Machine Policy / Assignment 
{00000000-0000-0000-0000-000000000043},Policy Agent Validate User Policy / Assignment 
{00000000-0000-0000-0000-000000000051},Retrying/Refreshing certificates in AD on MP 
{00000000-0000-0000-0000-000000000061},Peer DP Status reporting 
{00000000-0000-0000-0000-000000000062},Peer DP Pending package check schedule 
{00000000-0000-0000-0000-000000000063},SUM Updates install schedule 
{00000000-0000-0000-0000-000000000071},NAP action 
{00000000-0000-0000-0000-000000000101},Hardware Inventory Collection Cycle 
{00000000-0000-0000-0000-000000000102},Software Inventory Collection Cycle 
{00000000-0000-0000-0000-000000000103},Discovery Data Collection Cycle 
{00000000-0000-0000-0000-000000000104},File Collection Cycle 
{00000000-0000-0000-0000-000000000105},IDMIF Collection Cycle 
{00000000-0000-0000-0000-000000000106},Software Metering Usage Report Cycle 
{00000000-0000-0000-0000-000000000107},Windows Installer Source List Update Cycle 
{00000000-0000-0000-0000-000000000108},Software Updates Assignments Evaluation Cycle 
{00000000-0000-0000-0000-000000000109},Branch Distribution Point Maintenance Task 
{00000000-0000-0000-0000-000000000110},DCM policy 
{00000000-0000-0000-0000-000000000111},Send Unsent State Message 
{00000000-0000-0000-0000-000000000112},State System policy cache cleanout 
{00000000-0000-0000-0000-000000000113},Scan by Update Source 
{00000000-0000-0000-0000-000000000114},Update Store Policy 
{00000000-0000-0000-0000-000000000115},State system policy bulk send high
{00000000-0000-0000-0000-000000000116},State system policy bulk send low 
{00000000-0000-0000-0000-000000000120},AMT Status Check Policy 
{00000000-0000-0000-0000-000000000121},Application manager policy action 
{00000000-0000-0000-0000-000000000122},Application manager user policy action
{00000000-0000-0000-0000-000000000123},Application manager global evaluation action 
{00000000-0000-0000-0000-000000000131},Power management start summarizer
{00000000-0000-0000-0000-000000000221},Endpoint deployment reevaluate 
{00000000-0000-0000-0000-000000000222},Endpoint AM policy reevaluate 
{00000000-0000-0000-0000-000000000223},External event detection
'@
  foreach ($Computer in $ComputerName) {
    Write-Host -ForegroundColor Yellow "Attempting to run the SCCM Client actions for $Computer"
    $ActionsObj = ConvertFrom-Csv $ClientActions
    foreach ($Action in $ActionsObj) {
      try {
        Invoke-WmiMethod -Namespace Root/CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList $Action.GUID -ComputerName $Computer -ErrorAction Stop *>$null
        Write-Host -ForegroundColor green ("$($Action.Name) appeared to run successfully" -replace '\s{2,}',' ' )
      }
      catch {
        # I do not like these warnings appearing so commented it out
        #Write-Warning -ForegroundColor Red ("$($Action.Name) failed to run" -replace '\s{2,}',' ' )
      }
    }
    write-host
  }  
}