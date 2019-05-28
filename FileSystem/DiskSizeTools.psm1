function Get-DiskUsage {
  <#
  .SYNOPSIS
    Shows disk usage by directory
  .DESCRIPTION
    From a given path this script will list the immediate sub-directories in the path
    and show disk usage under each of them. The usage may be inacurate when sub-paths
    are not able to be calculated due to a lack of permissions. The output of this 
    command will show if there have been any issues with permissions and show up as
    false in the Acurate property.
  .EXAMPLE
    Get-DiskUsage -Path 'C:\Windows' -Units 'KB'
    This will look for directories directly under the C:\Windows directory and then add
    up all of the file sizes each directory as a grand total of bytes used. 
    You have an option to display the size in different units KB, MB, GB.
  .PARAMETER Path
    This needs to be a directory path and this path also need to have subdirectories in
    it for this command to operate correctly
  .PARAMETER Units
    This will instruct the command to output the sizes in the units specified, there are
    three options KB, MB, GB.
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 28-May-2019
  #>
  [cmdletbinding()]
  Param (
    [string]$Path = (Get-Location).Path,
    [ValidateSet('KB','MB','GB')]
    [string]$Units = 'MB'
  )

  try {
    if (Test-Path -Path $Path -PathType Container) {
      $Directories = (Get-ChildItem -Path $Path -Directory -ErrorAction stop).FullName
    }
    else {
      Write-Warning "$Path - is not a directory"
      break
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
        $SizeName = 'Size('+$Units+')'
        $DivideBy = '1'+$Units
        $Hash = [ordered]@{
          ParentPath = $Dir -replace '^(.*)\\.*$','$1'
          Directory = $Dir  -replace '^.*\\(.*)$','$1'
          Size = $SizeBytes
          $SizeName  = [math]::Round($SizeBytes / $DivideBy,1)
          Acurate  = $Allfiles
        }
        $Obj = New-Object -TypeName psobject -Property $Hash
        $Obj
      } # foreach-end
    } # if-end
    else {
      Write-Warning "$Path - does not have sub-directories below it to measure"
      break
    }
  } # try-end
  catch {}
} # function-end