function Get-GPOProcess {
  <#
  .SYNOPSIS
    Shows all policies that applied to a set of computers
  .DESCRIPTION
    Lists user and computer policies that apply to one or more computers
  .EXAMPLE
    Get-GPOProcess -ComputerName LON-CL1,LON-CL2,LON-CL3
    This command gets the RSOP information from GPResult and stores it in 
    XML files in the $Env:TEMP directory and then extracts the policy info
    from these XML result files to produce an object that shows the policies
    that were applied
  .PARAMETER ComputerName
    One or more computernames can be added to compare the policys applied for each  
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 26 Aug 2019
  #>
  [cmdletbinding()]
  Param (
    [string[]]$ComputerName = @('localhost')
  )
  foreach ($Computer in $ComputerName){
    $XMLFilePath = $env:TEMP + '\' + $computer + '-GPOResults.xml'
    $ErrorActionPreference = 'Stop'
    try{
      if (Test-Path $XMLFilePath) {
        Write-Warning "The XML file $XMLFilePAth exists, skipping $Computer, delete file manually and retry"
        throw
      } #END if
      GPResult -S $Computer -x $XMLFilePath *> $null
      [xml]$GPOResultXML = get-content $XMLFilePath 
      if (Test-Path $XMLFilePath) {Remove-Item $XMLFilePath -force}
      $ComputerRSOP = $GPOResultXML.Rsop.computerresults.EventsDetails.SinglePassEventsDetails.EventRecord.eventdescription -join "`n"
      $UserRSOP     = $GPOResultXML.Rsop.userresults.EventsDetails.SinglePassEventsDetails.EventRecord.eventdescription -join "`n"
      $ObjectProperties = [ordered]@{
        ComputerName     = $Computer
        UserGPOProcess     = $UserRSOP
        ComputerGPOProcess = $ComputerRSOP
      } #END Hashtable
      New-Object -TypeName psobject -Property $ObjectProperties
    } #END try
    catch {}
    finally {$ErrorActionPreference='Continue'}
  } #END foreach
} #END function