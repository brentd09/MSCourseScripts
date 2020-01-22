<#
  Functions in this module
    Add-CMNamesToCollection
    Find-CMObjectCollectionInfo
    Get-CMEndPointProtectionStatus
    Compare-AppsInstalled
#>
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

function Find-CMObjectCollectionInfo {
  <#
  .SYNOPSIS
     Locates collections and maintenance windows for a device
  .DESCRIPTION
     This command finds related collections and maintenance windows based on a device name.
  .PARAMETER DeviceName
     Type the name of a device that you want to check the SCCM site for, so it can search 
     which collections the device is a member of
  .PARAMETER SiteName
     This is the name of the SCCM site
  .EXAMPLE
     Find-CMObjectCollectionInfo -DeviceName 'LON-CL1' -SiteName Site_S01
     This will check which collections this device is in and will display the collections and
     their corespronding maintenance windows.
  .NOTES
     General Notes
     Created by: Brent Denny
     Created on: 22 Jan 2020
  #>  
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$DeviceName,
    [Parameter(Mandatory=$true)]
    [string]$SiteName
  )
  try {
    $CMCollections = Get-CimInstance -Namespace root/SMS/$SiteName -ClassName SMS_Collection -ErrorAction stop
  }
  Catch {
    Write-Warning "The site name: $SiteName, could be wrong or not able to be contacted"
    break
  }  
  $CMCollectionsRelatedToObject = Get-CimInstance -Namespace root/SMS/$SiteName -ClassName SMS_FullCollectionMembership |
    Where-Object {$_.Name -eq $DeviceName}
  if ([string]::IsNullOrEmpty($CMCollectionsRelatedToObject)) {
    Write-Warning "Device: $DeviceName, does not appear to be a member of any collections in Site:$SiteName"
    break
  }  
  foreach ($CollectionID in $CMCollectionsRelatedToObject.CollectionID) {
    $CollectionInfo = Get-CMCollection | Where-Object {$_.CollectionID -eq $CollectionID}
    $MaintWindows = ($CollectionInfo | Get-CMMaintenanceWindow).Name
    $Hash = [ordered]@{
      Device = $DeviceName
      CollectionID = $CollectionID
      CollectionName = ($CMCollections | Where-Object {$_.CollectionID -eq $CollectionID}).Name
      Maintenance = $MaintWindows
    }
    New-Object -TypeName psobject -Property $Hash
  }   
}

function Get-CMEndPointProtectionStatus {
  <#
  .SYNOPSIS
     Reports on the End Point Protection Status.
  .DESCRIPTION
     Reports on the End Point Protection Status.
  .PARAMETER SiteName
     This is the name of the SCCM site
  .EXAMPLE
     Get-CMEndPointProtectionStatus -SiteName Site_S01
     This will report on the End Point Protection stats
  .NOTES
     General Notes
     Created by: Brent Denny
     Created on: 22 Jan 2020
  #>  
  Param (
    [Parameter(Mandatory=$true)]
    [string]$SiteName
  )
  try {
    $CMEndPoint = Get-CimInstance -Namespace root/SMS/$SiteName -ClassName SMS_EndPointProtectionHealthStatus -ErrorAction stop
    $CMEndPoint 
  }
  Catch {
    Write-Warning "The site name: $SiteName, could be wrong or not able to be contacted"
    break
  }  
}

function Compare-AppsInstalled {
  <#
  .SYNOPSIS
     Compares installed applications on two computers
  .DESCRIPTION
     This will show the difference between two machines installed applications
  .PARAMETER ReferenceComputer
     The computer that we are comparing against
  .PARAMETER DifferenceComputer
     The computer that we are comparing
  .EXAMPLE
     Compare-AppsInstalled -ReferenceComputer lon-dc1 -DifferenceComputer lon-cl1
     This will compare the applications installed on both systems and create an output
     showing which application, its version and which computer it is missing from
  .NOTES
     General Notes
     Created by: Brent Denny
     Created on:  9 Jan 2019
     ChangeLog:
       25 Mar 2019 - Added Credentials parameter and try, catch to the script
                     Setup ping tests to both computers
  #>
  [cmdletbinding()]
  Param (
    [Parameter(Mandatory=$true)]    
    [string]$ReferenceComputer,
    [Parameter(Mandatory=$true)]
    [string]$DifferenceComputer,
    [pscredential]$Credentials = (Get-Credential -Message "Please enter the credentials to access both computers")
  )

  $RefAccess = Test-NetConnection -ComputerName $ReferenceComputer
  $DifAccess = Test-NetConnection -ComputerName $DifferenceComputer
  if ($RefAccess.PingSucceeded -eq  $false) {Write-Warning -Message "The computer $ReferenceComputer could not be contacted"}
  if ($DifAccess.PingSucceeded -eq  $false) {Write-Warning -Message "The computer $DifferenceComputer could not be contacted"}
  try{
    $RefComputerApps = Get-WmiObject -Class win32_Product -ComputerName $ReferenceComputer -Credential $Credentials -ErrorAction stop
    $DifComputerApps = Get-WmiObject -Class win32_Product -ComputerName $DifferenceComputer -Credential $Credentials -ErrorAction stop
  }
  Catch {
    Write-Warning -Message "There apears to be a problem accessing to either $ReferenceComputer or $DifferenceComputer"
  }
  $CompareApps = Compare-Object $RefComputerApps $DifComputerApps
  $CompareApps | Select-Object -Property @{n='Name';e={$_.InputObject.Name}},
                                         @{n='Version';e={$_.InputObject.Version}},
                                         @{n='NotInstslledOn';e={
                                           if ($_.sideindicator -eq '<=') {$DifferenceComputer}
                                           elseif ($_.sideindicator -eq '=>') {$ReferenceComputer}
                                         }}
}