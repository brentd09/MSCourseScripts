function Get-Prime {
  Param([int]$Maximum = 200)
  [int[]]$Primes = @(2)
  $Primes
  foreach ($PosPrime in (2..$Maximum)) {
    foreach ($Divider in (2..[int]($PosPrime/2))) {
      if (($PosPrime % $Divider) -eq 0) {break}
      else {
        if ($PosPrime -notin $Primes) {
          $Primes += $PosPrime
          $PosPrime
        }
      }
    }
  }
}

Get-Prime -Maximum 300