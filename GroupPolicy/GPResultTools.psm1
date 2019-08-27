function Get-GPOProcess {
  <#
  .SYNOPSIS
    Shows all policies that applied to a set of computers
  .DESCRIPTION
    Lists user and computer policies that apply to one or more computers
  .EXAMPLE
    Get-GPOProcess -ComputerName LON-CL1,LON-CL2,LON-CL3 | Format-List
    This command gets the RSOP information from GPResult and stores it in 
    XML files in the $Env:TEMP directory and then extracts the policy info
    from these XML result files to produce an object that shows the full 
    policy process that was applied to the computer and user. 
    The Format-List format is best to see the contents of the properties

    The results look like this:
    ---------------------------
    Starting user logon Policy processing for INSTRUCTOR\Administrator. 
    Activity id: {435F6B9B-F242-4321-A80F-73AB713FB7B6}
    The Group Policy processing mode is Foreground synchronous.
    The loopback policy processing mode is "No loopback mode".
    Group Policy receiving applicable GPOs from the domain controller.
    Successfully completed downloading policies.
    Group Policy successfully got applicable GPOs from the domain controller.
    List of applicable Group Policy objects: 
    
    None
    The following Group Policy objects were not applicable because they were filtered out :
    
    Local Group Policy
    	Not Applied (Empty)
    
    Checking for Group Policy client extensions that are not part of the system.
    Service configuration update to standalone is not required and will be skipped.
    Finished checking for non-system extensions.
    Completed user logon policy processing for INSTRUCTOR\Administrator in 0 seconds.
    Group policy session completed successfully.
  .PARAMETER ComputerName
    One or more computernames can be added to compare the policys applied for each  
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 26 Aug 2019
  #>
  [cmdletbinding()]
  Param (
    [string[]]$ComputerName = @('localhost'),
    [string]$UserName = 'ddls22\administrator'
  )
  foreach ($Computer in $ComputerName){
    $XMLFilePath = $env:TEMP + '\' + $computer + '-GPOResults.xml'
    $ErrorActionPreference = 'Stop'
    try{
      if (Test-Path $XMLFilePath) {
        Write-Warning "The XML file $XMLFilePAth exists, skipping $Computer, delete file manually and retry"
        throw
      } #END if
      GPResult -scope 'computer' -S $Computer -x $XMLFilePath -user $UserName
      [xml]$GPOResultXML = get-content $XMLFilePath 
      if (Test-Path $XMLFilePath) {Remove-Item $XMLFilePath -force}
      $ComputerRSOP = $GPOResultXML.Rsop.computerresults.GPO.Name -join "`n"
      $UserRSOP     = $GPOResultXML.Rsop.userresults.GPO.Name -join "`n"
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