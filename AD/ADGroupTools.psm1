function Get-NestedGroup {
  <#
  .SYNOPSIS
    Lists all nested groups related to a user
  .DESCRIPTION
    Lists all of the groups that are related to a user and then tracks which
    groups these groups are members of and so forth until all groups are located.
    The results show which Active Directory objects are contained within a group
    and then tracks that groups membership, until there are no more memberships 
    to track, it then tracks the next group's nested membership.
  .EXAMPLE
    Get-NestedGroup -UserName 'Mark Wallan'
    Starting with the user, this checks which groups the user is a member of
    and then tracks all of the indirectly related groups 
  .PARAMETER UserName
    The Active Directory user that the groups will be traced from, if this is omitted 
    the system will list all users in a selection GUI (GridView) so that the 
    username can be selected from the list
  .NOTES
    General notes
      Created by:    Brent Denny
      Created on:    2 Sep 2021
      Last Modified: 2 Sep 2021
  #>
  [cmdletbinding()]
  Param (
    [string]$UserName = (
      Get-ADUser -Filter * -Properties Department |
      Select-Object -Property Name,Department |
      Sort-Object -property Department,Name |
      Out-GridView -OutputMode Single
    ).Name,
    [switch]$Minimal
  )

  function Get-DirectGroupMembership {
    Param ($ADObject)
    $DirectObjects = Get-ADPrincipalGroupMembership -Identity $ADObject
    foreach ($DirectObject in $DirectObjects) {
      if ($Minimal -eq $true) {
        $DirectObject | Select-Object -Property @{n='MemberOf';e={$_.Name}} | Sort-Object -Property MemberOf
      }
      else {
        $DirectObject | Select-Object -Property @{n='Member';e={$ADObject.Name}},@{n='MemberOf';e={$_.Name}},@{n='MemberOfDN';e={$ADObject.DistinguishedName}}
      }
      Get-DirectGroupMembership -ADObject $DirectObject
    }
  }

  $UserObject = Get-ADUser -Filter {Name -eq $UserName}
  Get-DirectGroupMembership -ADObject $UserObject
}