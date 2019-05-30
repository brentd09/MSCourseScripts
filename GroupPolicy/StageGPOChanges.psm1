function Set-GPOStagedChange {
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
  }
}

