function Copy-XCItem {
  [CmdletBinding(
    DefaultParameterSetName='Default',
    ConfirmImpact = 'Medium',
    SupportsShouldProcess = $true
  )]
  param (
    [Parameter(Mandatory=$true,Position=0)]
    [string[]]$Source,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$Destination,
    
    [Alias('a')]
    [Parameter(ParameterSetName='Archive')]
    [switch]$ArchiveOnly,
    
    [Alias('m')]
    [Parameter(ParameterSetName='ArchiveClear')]
    [switch]$ArchiveOnlyAndClear,

    [Alias('b')]
    [switch]$SymbolicLink,
    
    [Alias('d')]
    [datetime]$ModifiedAfter,
       
    [Alias('s')]
    [switch]$SubDirectories,
    
    [Alias('e')]
    [switch]$SubDirectoriesIncludingEmpty,
    
    [Alias('w')]
    [switch]$StartAfterKeyPress,
    
    [Alias('c')]
    [switch]$ContinueDespiteErrors,
    
    [Alias('i')]
    [switch]$AssumeDestinationIsDirectory,

    [Alias('q')]
    [Parameter(ParameterSetName='Quiet')]
    [switch]$Quiet,
    
    [Alias('f')]
    [Parameter(ParameterSetName='NotQuiet')]
    [switch]$FullDestinationDisplayed,

    [Alias('l')]
    [switch]$ListItemsToBeCopied,
    
    [Alias('h')]
    [switch]$HiddenAndSystemIncluded,
    
    [Alias('r')]
    [switch]$ReadOnlyFilesOverwritten,

    [Alias('t')]
    [switch]$CopyTreeStructureOnly,
    
    [Alias('u')]
    [switch]$OnlyUpdateExisting,
    
    [Alias('k')]
    [switch]$KeepFileAttributes,
    
    [Alias('y')]
    [switch]$OverwriteFilesWithoutConfirmation,
  
    [Alias('-y')]
    [switch]$PromptBeforeOverwitingExisting,
    
    [Alias('n')]
    [switch]$ShortNameDestination,

    [Alias('o')]
    [switch]$CopyOwnerAndACL
  )
  
}

Copy-XCItem -Source C:\test -Destination e:\ -ArchiveOnly -Quiet -y 