function Set-GPOStagedChange {
  <#
  .SYNOPSIS
    Creates a staging GPO for change control
  .DESCRIPTION
    This command will help you stage settings for a GPO so that you can test those settings before making
    changes to the general production environment.
    From the command line you will specify a GPO that you wish to edit, an OU that you wish the test to be
    conducted from and a AD security group to which the "test GPO" will be security filtered. The "test GPO" is 
    automatically created by this command and linked to the OU your specify and will be security filtered 
    to the group mentioned earlier.
    If the GPO you specified is linked to the OU you specified, then the "test GPO" will be linked to that OU 
    and will be given a higher priority than the original GPO you specified. 
    If the GPO is not linked to the OU you specified then the "test GPO" will be linked to the OU and the 
    GPO priority will be set to the highest on that OU.
    This gives you the oppotunity to have the "test GPO" linked to either the original OU or to a test OU.
    After this is done you can then edit the "test GPO" and audit the results as those that were in the 
    security group login and experience the new GPO settings you are considering.
    The name of the "test GPO" will be the specified GPO name 2 underscores and the word Staged 
    for example: If the specified GPO was SalesGPO then the test GPO name = "SalesGPO__Staged"
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
    $GPOStagingName = $GPOName +'__Staged'

    write-verbose "GPO - $GPOName , OU - $OUDistinguishedName , Grp - $TestingGroup , StagedGPO - $GPOStagingName"

    $SelectedGPO = Get-GPO -all | Where-Object {$_.DisplayName -eq $GPOName}
    $SelectedOU  = Get-ADOrganizationalUnit -Identity $OUDistinguishedName -Properties *
    [array]$StagedGPO = Get-GPO -all | Where-Object {$_.DisplayName -eq $GPOStagingName}
    if ($StagedGPO.count -eq 0 ) {
      try {
        $SelectedGPO | Copy-GPO -TargetName $GPOStagingName -ErrorAction Stop
      }
      catch {
        Write-Warning "Problem creating the staged copy of the GPO. Check if $GPOStagingName already exists in Group Policy"
        break
      }
      # $OUWithGPOs = Get-ADObject -Filter * -Properties * | Where-Object {$_.GPLink}
      if ($SelectedOU.GPLink -match $SelectedGPO.Id.Guid) {  # OU chosen has the selected GPO linked
        $GpLinks = $SelectedOU.GPLink
        $RegEx   = '[a-fA-F0-9]{8}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{12}'
        $GpLinkGuids = [regex]::Matches($GpLinks,$RegEx).Value
        [array]::Reverse($GpLinkGuids)
        $GuidCount = 1
        $GpLinkGuids | ForEach-Object {
          if ($_ -eq  $SelectedGPO.Id.Guid) {
            $TestGpoOrder = $GuidCount
          }
          $GuidCount++
        }
      }
      else {  # OU Chosen doen not have the selected GPO linked
        $TestGpoOrder = 1
      }
      Write-Verbose "TestGpoOrder - $TestGpoOrder , GPLinkGuids - $GpLinkGuids"
       
      New-GPLink -Name $GPOStagingName -Target $OUDistinguishedName
      Set-GPLink -Name $GPOStagingName -Order $TestGpoOrder -Target $OUDistinguishedName
      Set-GPPermission -Name $GPOStagingName -TargetName $TestingGroup -PermissionLevel 'GpoApply' -TargetType 'Group' -Replace
      Set-GPPermission -Name $GPOStagingName -TargetName 'Authenticated Users' -PermissionLevel 'None' -TargetType 'Group' -Replace
    }
    else {
      Write-Warning "There is an existing GPO with the name of $GPOStagingName, you will need to remove this from the Group Policy Objects before running this command again"
    } # end - if-else
  } # end - process block
} # end - function
