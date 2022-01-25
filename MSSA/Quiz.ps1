    function ReverseCase {
      Param ([string]$InitialString)
      [string]$RevCaseString = ''
      0..($InitialString.length - 1) | ForEach-Object {
        if ($InitialString[$_].ToString().ToUpper() -ceq $InitialString[$_].ToString()) {$RevCaseString += $InitialString[$_].ToString().ToLower()}
        else {$RevCaseString += $InitialString[$_].ToString().ToUpper()}
      }
      return $RevCaseString
    }

ReverseCase -InitialString "tHISiSAsTRING"

function CompareFirstLast {
  param ([string[]]$TwoWords)
  if ($TwoWords[0][0] -eq $TwoWords[1][-1]) {$Result = $true}
  else {$Result = $false}
  return $Result
}

CompareFirstLast -TwoWords bill,lob

    function ConsonantsVowels {
      Param ([string]$Word)
      $Consonants = 0
      $Vowels = 0
      $ConList = 'b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','y','z'
      $VowList = 'a','e','i','o','u'
      $Word.ToCharArray() | ForEach-Object {
        if ($_ -in $VowList) {$Vowels++}
        elseif ($_ -in $ConList) {$Consonants++} 
      }
      return "Consonants = $Consonants, Vowels = $Vowels"
    }

    ConsonantsVowels -Word "Thisisaword"

    function AgeInDays {
      Param ([datetime]$DateOfBirth)
      $Now = Get-Date
      $Age = $Now - $DateOfBirth
      return $Age.Days
    }

    AgeInDays -DateOfBirth "5 sep 1990"