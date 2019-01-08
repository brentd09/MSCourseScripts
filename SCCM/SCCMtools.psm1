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