function Get-DiskUsage {
  <#
  .SYNOPSIS
    Shows disk usage by directory
  .DESCRIPTION
    From a given path this script will list the immediate sub-directories in the path
    and show disk usage under each of them. The usage may be inacurate when sub-paths
    are not able to be calculated due to permissions. A warning will show in the output
    if the usage may not be acurate.
  .EXAMPLE
    Get-DiskUsage -Path 'C:\Windows'
    This will look for directories directly under the C:\Windows directory and then add
    up all of the file sizes each directory as a grand total of bytes used.
  .PARAMETER Path
    This needs to be a directory path and this path also need to have subdirectories in
    it for this command to operate correctly
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 28-May-2019
  #>
  [cmdletbinding()]
  Param (
    [string]$Path = (Get-Location).Path
  )

  try {
    if (Test-Path -Path $Path -PathType Container) {
      $Directories = (Get-ChildItem -Path $Path -Directory -ErrorAction stop).FullName
    }
    if ($Directories.Count -gt 0) {
      foreach ($Dir in $Directories) {
        try {
        $SizeBytes = (Get-ChildItem $Dir -file -Recurse -ErrorAction stop | 
         Measure-Object -Property Length -Sum).Sum
        $Allfiles = $true 
        }
        catch {
          $SizeBytes = (Get-ChildItem $Dir -file -Recurse -ErrorAction SilentlyContinue | 
           Measure-Object -Property Length -Sum).Sum
          $Allfiles = $false
        } 
        if (-not $SizeBytes) {$SizeBytes = 0}
        $Hash = [ordered]@{
          Size      = $SizeBytes
          Directory = $Dir
          AllFiles  = $Allfiles
        }
        New-Object -TypeName psobject -Property $Hash
      } # foreach-end
    } # if-end
  } # try-end
  catch {}
} # function-end