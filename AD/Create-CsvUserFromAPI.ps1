function New-RandomPassword {    [cmdletbinding()]  Param (    [int]$NumberCount = 2,    [int]$UpperCount = 2,    [int]$LowerCount = 5,    [int]$SpecialCount = 1  )  do {    $Num = 2..9 | get-random -Count $NumberCount    $Upr = 65..90 | ForEach-Object {[char]$_} | get-random -count $UpperCount    $Lwr = 97..122 | ForEach-Object {[char]$_} | get-random -count $LowerCount    $Spl = 33,35,36,37,38,63,64  | ForEach-Object {[char]$_} | get-random -count $SpecialCount    $RawPswd = $Num + $Upr + $Lwr + $Spl    $RandPswd = $RawPswd | Sort-Object {Get-Random}    $ComplexPswd = -join ($RandPswd)  } until ($RandPswd[0] -match '[a-z]')  return $ComplexPswd }


try {Remove-Item -Force e:\userPsw.rpt -ErrorAction stop}
catch {}
$NewUserCsvs = ((Invoke-RestMethod -Method Get -Uri https://my.api.mockaroo.com/random_ad_users.json?key=fe812050) -split "`n").trim()
$NewUserObjs = $NewUserCsvs | ConvertFrom-Csv
foreach ($NewUserObj in $NewUserObjs) {
  $Departments = Get-ADOrganizationalUnit -Filter *
  $ClearPasssword = New-RandomPassword
  $SecPasssword = $ClearPasssword  | ConvertTo-SecureString -AsPlainText -Force 
  if ($Departments.name -contains $NewUserObj.department) {
    $NewUserDept = $Departments | Where-Object {$_.name -eq $NewUserObj.department}
    $NewUserObj | New-ADUser -Path $NewUserDept.DistinguishedName -AccountPassword $SecPasssword
  }
  else {
    $RootDN = $Departments[0].DistinguishedName -replace '^.*?,(DC=.*)$','$1'
    New-ADOrganizationalUnit -Name $NewUserObj.department -Path $RootDN -ErrorAction SilentlyContinue
    $NewPath = "OU="+$NewUserObj.department+","+$RootDN
    $NewUserObj | new-ADUser -AccountPassword $SecPasssword -Path $NewPath 
  }
  "User: {0,-20}  Password:{1,-15}" -f $NewUserObj.name,$ClearPasssword #| Out-File -Append -FilePath e:\userPsw.rpt
}