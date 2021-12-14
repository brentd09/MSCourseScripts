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
  <#
  .SYNOPSIS
    Runs a command pipeline multiple time looking for changes in output
  .DESCRIPTION
    This command runs a pipeline multiple times watching the output for 
    changes in the output, when it detects changes in the output it will 
    then update the screen output 
  .EXAMPLE
    Watch-Command -ScriptBlock {Get-Process | Sort-Object -Descending -Property CPU | Select-Object -First 10}
    This will output the top ten processes by CPU and not update the 
    information until it detects these is a change in the output. 
  .PARAMETER ScriptBlock
    This contains a command pipeline that will be run to compare the results 
    and display only changes to the screen.
  .PARAMETER ResultCount
    This is how many different results to show before exiting the command, the default is 10.  
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 13 Dec 2021
      Last EDited : 15 Dec 2021
  #>
  [CmdletBinding()]
  param (
    [ScriptBlock]$ScriptBlock,
    [int]$ResultCount = 10
  )
  $Counter = 0
  $Result = $ScriptBlock.Invoke() | Out-String
  Clear-Host
  Write-Output $Result
  do {
    $PrevResult = $Result
    do {
      Start-Sleep -Seconds 1
      $Result = $ScriptBlock.Invoke() | Out-String
    } until ($PrevResult -ne $Result)
    Clear-Host
    $Result
    $Counter++
  } while ($Counter -le $ResultCount)
}