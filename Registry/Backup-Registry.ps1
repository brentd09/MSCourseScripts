function Backup-RegistryPath {
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