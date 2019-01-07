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
     General notes
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
  
  $SiteCode = ($SiteCode + ':') -replace "\:[2,]",':'
  Set-Location $SiteCode
  $CurrentCollections =  Get-CMCollection 
  if ($CurrentCollections.name -notcontains $CollectionName) {
    $Collection = New-CMDeviceCollection -Name $CollectionName -LimitingCollectionName $LimitingCollection
  }
  else {
    $Collection = Get-CMCollection | Where-Object {$_.Name -eq $CollectionName}
  }
  $PCs = Get-Content $Filename
  $DevicesToAdd = Get-CMResource -Fast | where {$_.Name -in $Pcs} 
  foreach ($Device in $DevicesToAdd) {
    Add-CMDeviceCollectionDirectMembershipRule -CollectionId $Collection.CollectionID -ResourceID $Device.ResourceID 
  }
}