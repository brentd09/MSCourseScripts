function Test-DynParams {
  [CmdletBinding()]
  Param()
  DynamicParam { 
    $ADModule = Get-Module -ListAvailable | Where-Object {$_.Name -in @('ActiveDirectory','GroupPolicy')}
    if ($ADModule.Count -lt 2) {
      Write-Warning "You need to run this on a machine that has access to the ActiveDirectory and GroupPolicy modules"
      break
    }
    $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

    $ParamName_OU = 'OUDistinguishedName'
    $AttributeCollection_OU = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute_OU = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute_OU.Mandatory = $true
    $ParameterAttribute_OU.Position = 1
    $AttributeCollection_OU.Add($ParameterAttribute_OU) 
    $ArraySet_OU = (Get-ADOrganizationalUnit -Filter *).distinguishedname
    $ValidateSetAttribute_OU = New-Object System.Management.Automation.ValidateSetAttribute_OU($ArraySet_OU)    
    $AttributeCollection_OU.Add($ValidateSetAttribute_OU)
    $RuntimeParameter_OU = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_OU, [string], $AttributeCollection_OU)
    
    $ParamName_GPO = 'GPOName'
    $AttributeCollection_GPO = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute_GPO = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute_GPO.Mandatory = $true
    $ParameterAttribute_GPO.Position = 2
    $AttributeCollection_GPO.Add($ParameterAttribute_GPO)  
    $ArraySet_GPO = (Get-GPO -all).DisplayName
    $ValidateSetAttribute_GPO = New-Object System.Management.Automation.ValidateSetAttribute($ArraySet_GPO)
    $AttributeCollection_GPO.Add($ValidateSetAttribute_GPO)
    $RuntimeParameter_GPO = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_GPO, [string], $AttributeCollection)
    
    $ParamName_Group = 'TestingGroup'
    $AttributeCollection_Group = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute_Group = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute_Group.Mandatory = $true
    $ParameterAttribute_Group.Position = 3
    $AttributeCollection_Group.Add($ParameterAttribute_Group)  
    $ArraySet_Group = (Get-ADGroup -Filter *).Name
    $ValidateSetAttribute_Group = New-Object System.Management.Automation.ValidateSetAttribute($ArraySet_Group)
    $AttributeCollection_Group.Add($ValidateSetAttribute_Group)
    $RuntimeParameter_Group = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_Group, [string], $AttributeCollection_Group)


    $RuntimeParameterDictionary.Add($ParamName_OU, $RuntimeParameter_OU)
    $RuntimeParameterDictionary.Add($ParamName_GPO, $RuntimeParameter_GPO)
    $RuntimeParameterDictionary.Add($ParamName_Group, $RuntimeParameter_Group)
    return $RuntimeParameterDictionary
  } # End - DynamicParams

}