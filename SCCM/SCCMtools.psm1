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
     This requires the thee character site code
  .PARAMETER CollectionName
     This requires the name of the collection that will eith be created or added to
  .PARAMETER FileName
     This requires the filename of the file containing the computernames that will
     be used to add to the collection
  .PARAMETER LimitingCollection
     This is an optional parameter that will specify the limiting collection used to
     initially create the collection
  .EXAMPLE
     Add-CMNamesToCollection -SiteCode S01 -CollectionName Coll001 -FileName c:\computers.txt
  .EXAMPLE
     Add-CMNamesToCollection -SiteCode S01 -CollectionName Coll001 -FileName c:\computers.txt -LimitingCollection "All Systems"
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
  #Make sure the Site Code only has 3 Characters
  $SiteCode = $SiteCode -replace "(\w{3}).*",'$1'
  #Create the drive name used to connect to the PSDrive of CM
  $SiteCodeDrive = $SiteCode + ':'
  $ModulesLoaded = Get-Module
  $PSDrives = Get-PSDrive
  #Check if this script is running from a PS window from the SCCM site server
  if ($ModulesLoaded.Name -contains 'ConfigurationManager' -and $PSDrives.Name -contains $SiteCode) {
    #Move the the PSDrive of the SCCM server
    Set-Location $SiteCodeDrive
    $CurrentCollections =  Get-CMCollection
    #Check to see if the Collection requested already exists
    if ($CurrentCollections.name -notcontains $CollectionName) {
      #Create Collection
      $ErrorActionPreference = 'stop'
      try {$Collection = New-CMDeviceCollection -Name $CollectionName -LimitingCollectionName $LimitingCollection }
      catch {
        Write-Warning "There was a problem creating the collection with the limiting collection - $LimitingCollection "
        $ErrorActionPreference = 'continue'
        break
      }
    }
    else {
      #Find Collection
      $Collection = Get-CMCollection | Where-Object {$_.Name -eq $CollectionName}
    }
    #Get Computer names from text file
    $PCs = Get-Content $Filename | where-Object {$_ -match '\w'}
    #Find which names match objects in SCCM and disregard others
    $DevicesToAdd = Get-CMResource -Fast | Where-Object {$_.Name -in $Pcs}
    #Check to see if the number of devices is greater than 0
    if ($DevicesToAdd.Count -gt 0) {
      foreach ($Device in $DevicesToAdd) {
        #For each device create a rule that will add that device to the collection
        Add-CMDeviceCollectionDirectMembershipRule -CollectionId $Collection.CollectionID -ResourceID $Device.ResourceID 
      }
    }
    else {
      Write-Warning 'There were no matching computer objects found to add'
    }
    #Check to see if there were some computer names from the text file that did not match objects in SCCM
    if ($DevicesToAdd.Count -ne $PCs.Count) {
      Write-Warning 'Not all computers were found in Confiruation Manager'
    }
  }
  else {
    Write-Warning "This needs to be run from a Configuation Manager Powershell window!"
  }
}