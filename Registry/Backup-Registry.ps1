function Backup-RegistryPath {
  <#
  .SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
  .DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
  .NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
  .LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
  .EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
  #>
  
  [CmdletBinding()]
  Param ([string]$RegPath = 'HKCU:\Software\Brent')
  $RegKeys = Invoke-Command {
    Get-Item -Path $RegPath 
    Get-ChildItem  $RegPath -Recurse 
  }
  foreach ($RegKey in $RegKeys) {
    $RegPath = ($RegKey | Select-Object -Property @{n= 'DrivePath';e={$_.Name -replace '^.+?\\',"$($_.PSDrive):\"}}).DrivePath
    $RegKeyACL = Get-Acl -Path $RegPath 
    $RegAclXml = [System.Management.Automation.PSSerializer]::Serialize($RegKeyACL)
    foreach ($RegProperty in $RegKey.Property) {
      

    }
  }
}

Backup-RegistryPath