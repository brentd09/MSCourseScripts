 Function Get-PasswordLastSet {
     <#
  .SYNOPSIS
  Returns PasswordLastSet information
  .DESCRIPTION
  Queries the PasswordLastSet information for a user across domain controllers and returns the highest (latest) value
  .EXAMPLE
  Get-PasswordLastSet User
  .EXAMPLE
  Get-PasswordLastSet -Identity User
  .EXAMPLE
  Get-ADUser User | Get-PasswordLastSet
  .EXAMPLE
  Get-PasswordLastSet User1, User2
  .PARAMETER users
  List of users - pipeline can be used
  #>
     
  [CmdletBinding()]
  param (
    [Parameter(
      Position= 0,
      Mandatory=$True,
      ValueFromPipeline=$True,
      HelpMessage='For what user would you like to find the PasswordLastSet attribute?'
    )]
    $identity
  )
     
  Begin {}
  Process {
    Foreach ($account in $identity) {
      $dateStamp = $null
      $domainController = $null
       # filter used to remove Azure domain controllers
      Get-ADDomainController -Filter * | ForEach-Object {
        $dc = $_.HostName
        $PasswordLastSet = (Get-ADUser $account -Properties PasswordLastSet -server $dc).PasswordLastSet
        if ($dateStamp -le $PasswordLastSet) {
          $dateStamp = $PasswordLastSet
          $domainController = $dc
        }
      } # End of ForEach
        
      $properties = @{
        Name=$account;
        PasswordLastSet = $dateStamp;
        DomainController = $domainController
      }
      New-Object -TypeName PSObject -Prop $properties
    } # End of ForEach
  } # End of Process
  End {}          
} # End of Function