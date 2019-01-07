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
  $SiteCode = $SiteCode -replace "(\w{3}).*",'$1'
  $SiteCodeFull = $SiteCode + ':'
  $ModulesLoaded = Get-Module
  $PSDrives = Get-PSDrive
  if ($ModulesLoaded.Name -contains 'ConfigurationManager' -and $PSDrives -contains $SiteCode) {
    Set-Location $SiteCodeFull
    $CurrentCollections =  Get-CMCollection
    if ($CurrentCollections.name -notcontains $CollectionName) {
      $Collection = New-CMDeviceCollection -Name $CollectionName -LimitingCollectionName $LimitingCollection
    }
    else {
      $Collection = Get-CMCollection | Where-Object {$_.Name -eq $CollectionName}
    }
    $PCs = Get-Content $Filename | where-Object {$_ -match '\w'}
    $DevicesToAdd = Get-CMResource -Fast | Where-Object {$_.Name -in $Pcs}
    if ($DevicesToAdd.Count -ne 0) {
      foreach ($Device in $DevicesToAdd) {
        Add-CMDeviceCollectionDirectMembershipRule -CollectionId $Collection.CollectionID -ResourceID $Device.ResourceID 
      }
    }
    else {
      Write-Warning 'There were no matching computer objects found to add'
    }
    if ($DevicesToAdd.Count -ne $PCs.Count) {
      Write-Warning 'Not all computers were found in Confiruation Manager'
    }
  }
  else {
    Write-Warning "This needs to be run from a Configuation Manager Powershell window!"
  }
}