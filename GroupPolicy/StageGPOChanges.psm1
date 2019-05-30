function Set-GPOStagedChange {
  <#
  .SYNOPSIS
    Creates a staging GPO for change control
  .DESCRIPTION
    This command will create a new (staged) GPO from a copy of one that you specify and will
    link it to the OU you specify, it will change its priority to be the highest priority 
    and it will remove all other Apply permissions and add the Apply permission only to a 
    group that you specify.
    You can specify the original OU where the current GPO is linked or you can specify a testing OU 
    where you have less chance of creating havoc with the production users and computers.
    This command also employs dynamic paramters so that intellisense will locate and list off of the 
    objects related to the parameter you type.
  .EXAMPLE
    Set-GPOStagedChange -GPOName ITGpo -OUDistinguishedName 'ou=IT,dc=adatum,dc=com' -TestingGroup GPOTesters
    This will create a new GPO called ITGpoStaged and link it to the IT OU specified it will then change the 
    permissions on the link so that only the GPOTesters group will be applied the settings and it will set the 
    priority of this new GPO to be the highest priority on this OU
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 30-May-2019
    This script was the response to a question asked in a Microsoft Identity course regarding change control and
    staged testing of new GPO settings before releasing those new settings to production.  
  #>
  [CmdletBinding()]
  Param ()

  DynamicParam {
  
     # Set the dynamic parameters' name
     $ParamName_OU = 'OUDistinguishedName'
     # Create the collection of attributes
     $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
     # Create and set the parameters' attributes
     $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
     $ParameterAttribute.Mandatory = $true
     $ParameterAttribute.Position = 1
     # Add the attributes to the attributes collection
     $AttributeCollection.Add($ParameterAttribute) 
     # Create the dictionary 
     $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
     # Generate and set the ValidateSet 
     $arrSet = (Get-ADOrganizationalUnit -Filter *).distinguishedname
     $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
     # Add the ValidateSet to the attributes collection
     $AttributeCollection.Add($ValidateSetAttribute)
     # Create and return the dynamic parameter
     $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_OU, [string], $AttributeCollection)
     $RuntimeParameterDictionary.Add($ParamName_OU, $RuntimeParameter)
  
     
     # Set the dynamic parameters' name
     $ParamName_GPO = 'GPOName'
     # Create the collection of attributes
     $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
     # Create and set the parameters' attributes
     $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
     $ParameterAttribute.Mandatory = $true
     $ParameterAttribute.Position = 2
     # Add the attributes to the attributes collection
     $AttributeCollection.Add($ParameterAttribute)  
     # Generate and set the ValidateSet 
     $arrSet = (Get-GPO -all).DisplayName
     $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
     # Add the ValidateSet to the attributes collection
     $AttributeCollection.Add($ValidateSetAttribute)
     # Create and return the dynamic parameter
     $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_GPO, [string], $AttributeCollection)
     $RuntimeParameterDictionary.Add($ParamName_GPO, $RuntimeParameter)

     # Set the dynamic parameters' name
     $ParamName_Group = 'TestingGroup'
     # Create the collection of attributes
     $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
     # Create and set the parameters' attributes
     $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
     $ParameterAttribute.Mandatory = $true
     $ParameterAttribute.Position = 3
     # Add the attributes to the attributes collection
     $AttributeCollection.Add($ParameterAttribute)  
     # Generate and set the ValidateSet 
     $arrSet = (Get-ADGroup -Filter *).Name
     $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
     # Add the ValidateSet to the attributes collection
     $AttributeCollection.Add($ValidateSetAttribute)
     # Create and return the dynamic parameter
     $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_Group, [string], $AttributeCollection)
     $RuntimeParameterDictionary.Add($ParamName_Group, $RuntimeParameter)

     return $RuntimeParameterDictionary
  } # End - DynamicParams

  
  process {
    $GPOName             = $PSBoundParameters[$ParamName_GPO]
    $OUDistinguishedName = $PSBoundParameters[$ParamName_OU]
    $TestingGroup        = $PSBoundParameters[$ParamName_Group]
    $GPOStagingName = $GPOName +'Staged'

    write-verbose "GPO - $GPOName , OU - $OUDistinguishedName , Grp - $TestingGroup , StagedGPO - $GPOStagingName"

    $CurrentGPO = Get-GPO -all | Where-Object {$_.DisplayName -eq $GPOName}
    [array]$StagedGPO = Get-GPO -all | Where-Object {$_.DisplayName -eq $GPOStagingName}
    if ($StagedGPO.count -eq 0 ) {
      $CurrentGPO | Copy-GPO -TargetName $GPOStagingName 
      New-GPLink -Name $GPOStagingName -Target $OUDistinguishedName
      Set-GPLink -Name $GPOStagingName -Order 1 -Target $OUDistinguishedName
      Set-GPPermission -Name $GPOStagingName -TargetName $TestingGroup -PermissionLevel 'GpoApply' -TargetType 'Group' -Replace
      Set-GPPermission -Name $GPOStagingName -TargetName 'Authenticated Users' -PermissionLevel 'None' -TargetType 'Group' -Replace
    }
    else {
      Write-Warning "There is an existing GPO with the name of $GPOStagingName, you will need to remove this from the Group Policy Objects before running this command again"
    } # end - if-else
  } # end - process block
} # end - function

#  $GPOString = Get-ADObject -Filter * -Properties gplink | Where-Object {$_.GpLink}
#  $regex = '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'
#  $Guids = ([RegEx]::Matches($GPOString,$regex)).Value
