﻿<#
  Functions in this module
    Get-CurrentUserSID
    Compare-Password
#>
function Get-CurrentUserSID {
[Cmdletbinding()]
Param()
$Template = @'
User Name      SID
============== ==============================================
{UserName*:Domain1\usera} {SID:S-1-5-21-1955989083-2427161618-3948596988-1000}
{UserName*:domainb\username1} {SID:S-1-5-21-1955989083-2427161618-3948596988-1001}
{UserName*:flintstone\fred} {SID:S-1-5-21-1955989083-2427161618-3948596988-1002}
'@

whoami /user | ConvertFrom-String -TemplateContent $Template
}

function Compare-Password {
  $First = Read-Host -AsSecureString -Prompt 'Please enter a new password'
  $Second  = Read-Host -AsSecureString -Prompt 'Please re-enter new password to confirm'
  $FirstClear = (New-Object System.Management.Automation.PSCredential ('DummyName',$First)).GetNetworkCredential().Password
  $SecondClear = (New-Object System.Management.Automation.PSCredential ('DummyName',$Second)).GetNetworkCredential().Password

  if ($FirstClear -cne $SecondClear) {Write-Host -ForegroundColor Red "The passwords are not the same"}
  else {Write-Host -ForegroundColor Green "Passwords are identical"}
}

function Get-CurrentUser {
  Param (
    [string[]]$ComputerName = $env:COMPUTERNAME
  )
  foreach ($Computer in $ComputerName) {
    $CS = Get-WmiObject -Class win32_ComputerSystem -ComputerName $Computer
    $AllUsers = Get-WmiObject -Class Win32_UserAccount -ComputerName $CimSession
    $LoggedOnUser = $AllUsers | Where-Object {$_.Caption -eq $CS.UserName}
    $LoggedOnUser
  }
}
