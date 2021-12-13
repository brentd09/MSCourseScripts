function Find-Executable {
  <#
  .Synopsis
     Searches the $Path variable for a selected file
  .DESCRIPTION
     Searches through the $Path variable for matching files
  .EXAMPLE
     Find-Executable -Name Write
     This will look for a file called 'Write' somewhere in the $Path directories
  .EXAMPLE
     Find-Executable -Name Write.exe
     This will look for a file called 'Write.exe' somewhere in the $Path directories
  .PARAMETER Name
     This is the name of the executable file you can include the extension or not
  .NOTES
     Created By: Brent Denny
     Created On: 5 Oct 2012
  #>
  [CmdletBinding()]
  Param (
    [string]$Name = ''
  )
  if ($Name -ne '' ) {
    if ($Name -notmatch '\..{3,}$') {$Name = ($Name -split '\.')[0] +'.*'}
    foreach ($PathElement in ($env:Path -split ';')) {
      $FullPathToExe = $PathElement.trimend('\')+'\'+$Name
      try {
        if (Test-Path -Path $FullPathToExe -ErrorAction Stop) {
          Get-ChildItem $FullPathToExe -File | Select-Object Mode,LastWriteTime,FullName
        }
      }
      catch {}
    }
  }
  else {
    write-warning "You must search for an executable`nUsage: Where-Executable -Executable write"
  }
}

function Watch-Command {
  [CmdletBinding()]
  param (
    [string]$CommandLineToExecute,
    [int]$ResultCount = 10
  )
  $Counter = 0
  $Result = Invoke-Expression $CommandLineToExecute | Out-String
  Clear-Host
  Write-Output $Result
  do {
    $PrevResult = $Result
    do {
      Start-Sleep -Seconds 10
      $Result = Invoke-Expression $CommandLineToExecute | Out-String
    } until ($PrevResult -ne $Result)
    Clear-Host
    $Result
    $Counter++
  } while ($Counter -le $ResultCount)
}