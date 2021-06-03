function New-RandomPassword {  
  [cmdletbinding()]
  Param (
    [int]$NumberCount = 2,
    [int]$UpperCount = 2,
    [int]$LowerCount = 5,
    [int]$SpecialCount = 1
  )
  do {
    $Num = 2..9 | get-random -Count $NumberCount
    $Upr = 65..90 | ForEach-Object {[char]$_} | get-random -count $UpperCount
    $Lwr = 97..122 | ForEach-Object {[char]$_} | get-random -count $LowerCount
    $Spl = 33,35,36,37,38,63,64  | ForEach-Object {[char]$_} | get-random -count $SpecialCount
    $RawPswd = $Num + $Upr + $Lwr + $Spl
    $RandPswd = $RawPswd | Sort-Object {Get-Random}
    $ComplexPswd = -join ($RandPswd)
  } until ($RandPswd[0] -match '[a-z]')
  return $ComplexPswd 
}

