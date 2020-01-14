function Test-RegistryPath {
  <#
  .SYNOPSIS
    This command tests to see if a Registry key or leaf/property exist
  .DESCRIPTION
    The command was created because of the limitations of the Test-Path command.
    The Test-Path is limited and will only test the registry keys, it cannot help if
    you are looking to test the existence of leaf/properties. The Test-RegistryPath 
    command was the result of a question regarding how to test for both keys and 
    leaf/properties in the registry.
  .EXAMPLE
    Test-RegistryPath -Path HKCU:\Software
    This will test the existence of the HKCU:\Software key.
  .EXAMPLE
    Test-RegistryPath -Path HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\FirstLogon -Leaf
    This will test the existence of the HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\FirstLogon 
    leaf/property, the -Leaf parameter informs the test that it needs to check for Registry leaf/properties 
    and not keys. If you search for keys using the Leaf parameter it will return a negative result.    
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 10-Jan-2020
  #>
  [cmdletbinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [switch]$Leaf
  )
  if ($Leaf -eq $true) {
    Try {$KeyInfo = Get-ItemProperty -Path (Split-Path -Path $Path) -Name (Split-Path -Leaf -Path $Path) -ErrorAction Stop}
    Catch {}
    if ($KeyInfo) {
      $PathTestResult = $true
      $ProperyValue = Get-ItemPropertyValue -Path (Split-Path -Path $Path) -Name (Split-Path -Leaf -Path $Path)
    }
    else {$PathTestResult = $false}
  }
  else {
    $PathTestResult = Test-Path $Path
  }
  if ($Leaf -eq $true) {
    $Hash = [ordered]@{
      Path   = $Path
      Value  = $ProperyValue      
      Exists = $PathTestResult
      Leaf   = $Leaf
    }
  }
  else {
    $Hash = [ordered]@{
      Path   = $Path
      Exists = $PathTestResult
      Leaf   = $Leaf
    }
  }
  $Obj = New-Object -TypeName psobject -Property $Hash
  return $Obj
}