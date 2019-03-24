<#
.SYNOPSIS
  Creating GPOs via PowerShell
.DESCRIPTION
  Creating GPOs via PowerShell will involve you understanding which Registry
  settings you need to change, this is where it gets ugly!
.EXAMPLE
  Set-GPOSetting
  Sets the GPO that is configured in the script
.NOTES
  General notes
  Created By: Brent Denny
  Created On: 19 Mar 2019
#>
[CmdletBinding()]
Param()

New-GPO -Name "ScreenSaverTimeOut" -Comment "Sets the time to 900 seconds"
# This next step is the worst thing, there is no easy way to do this you
# will need the actual registry location that can get modified through
# the GPO and enter it here
Set-GPRegistryValue -Name "ScreenSaverTimeOut" -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" -ValueName ScreenSaveTimeOut -Type DWord -Value 900
# Link the new GPO to an OU
New-GPLink -Name "ScreenSaverTimeOut" -Target "ou=Sales,dc=Adatum,dc=Com"

Get-ADComputer -Filter * -SearchBase "ou=Domain Controllers,dc=Adatum,dc=Com" | 
  Foreach-Object {Invoke-GPUpdate -Computer $_.name -Force -RandomDelayInMinutes 0}

# Other settings you can set are below  
# Get-GPInheritance -Target "ou=Sales,dc=Adatum,dc=Com"
# Set-GPInheritance -Target "ou=Sales,dc=Adatum,dc=Com" -IsBlocked 1
# Set-GPLink -Name "Default Domain Policy" -Target "dc=pagr,dc=inet" -Enforced Yes
# Set-GPPermission -Name "ScreenSaverTimeOut" -TargetName "Authenticated Users" -TargetType User -PermissionLevel GPORead
# Set-GPPermission -Name "ScreenSaverTimeOut" -TargetName "Petra" -TargetType User -PermissionLevel GPOApply
# Set-GPPermission -Name "ScreenSaverTimeOut" -TargetName "Authenticated Users" -TargetType User -PermissionLevel None

# Get-GPO -Name "ScreenSaverTimeOut" | Get-GPOReport -ReportType HTML -Path $Home\report.html
# Invoke-Item $Home\report.html
