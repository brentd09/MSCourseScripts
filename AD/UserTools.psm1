<#
  Functions in this module
    Get-CurrentUserSID
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