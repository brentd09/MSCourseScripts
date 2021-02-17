[Cmdletbinding()]
Param (
  [Parameter(Mandatory=$true)]
  [string]$user
)
Clear-Host
$PDC = (Get-ADDomainController -Discover -Service PrimaryDC).Name
$DCs = (Get-ADDomainController -Filter *).Name
foreach ($DC in $DCs) {
  Write-Host -ForegroundColor Green "Checking Account lockout events on $DC for $user"
  if ($DC -eq $PDC) {
    Write-Host -ForegroundColor Green "$DC is the PDC"
  }
  Get-EventLog -LogName Security -ComputerName $DC | 
   Where-Object {$_.EventID -in @(4740,4767,4770,4771) -and $_.Message -like "*$user*" }
}