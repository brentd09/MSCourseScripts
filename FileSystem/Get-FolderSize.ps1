<#
.SYNOPSIS
   This Script finds the size of subdirectories in a parent folder
.DESCRIPTION
   This script takes two parameters the first is a parent folder 
   parameter the second is the units that the disk usage will be 
   displayed using. This script is perfect for getting a report
   regarding space used in home folders as it shows the space 
   used by each of the sub-folders of the parent folder.
.PARAMETER ParentPath
   This Parameter is required, The script looks into the ParentPath
   to find sub-folders to report disk usage for.
.PARAMETER Units
   This Parameter will change the way the report is generated, there are 
   only three optional values for this parameter (KB, MB, GB)
.EXAMPLE
   Get-FolderSize -ParentPath D:\Home 
   This wil show the disk space used by each subfolder of D:\Home in MBs
.EXAMPLE
   Get-FolderSize -ParentPath D:\Home -Units GB
   This wil show the disk space used by each subfolder of D:\Home in GBs
.NOTES
   General notes
     Created By: Brent Denny
     Created on: 12 Apr 2019
#>
[CmdletBinding()]
Param (
  [Parameter(Mandatory=$true)]
  [string]$ParentPath,
  [ValidateSet('KB','MB','GB')]
  [string]$Units = 'MB'
)

function Get-FileData {
  Param ($Parent)
  $SubDirectories = Get-ChildItem -Path $Parent -Directory
  foreach ($SubDir in $SubDirectories) {
    $Path = $ParentPath + '\' + $SubDir.name
    $Files = Get-ChildItem -Path $Path -Recurse -file
    $TotalSize = ($Files | Measure-Object -Property Length -Sum).Sum
    $Properties = [ordered]@{ParentPath=$Parent;FolderName=$SubDir.Name;TotalSize=$TotalSize}
    New-Object -TypeName psobject -Property $Properties
  }
}

$Div = '1'+ $Units
Get-FileData -Parent $ParentPath| 
  Sort-Object -Property Totalsize -Descending | 
  Select-Object ParentPath,FolderName,@{n="TotalSize($Units)";e={[math]::Round($_.TotalSize / $Div,2)}}
