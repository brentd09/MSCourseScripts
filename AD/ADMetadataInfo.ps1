 function Get-ADObjectMeta {
  Param (
    $UserName = 'Administrator'
  )
  Get-ADUser -Filter {Name -eq $UserName} | 
    Get-ADReplicationAttributeMetadata -server lon-dc1 | 
      Select-Object  @{n='Attribute';e={$_.AttributeName}},
                     @{n='Server';e={$_.Server}},
                     @{n='LocalUSN';e={$_.LocalchangeUSN}},
                     @{n='OrigServer';e={$_.LastOriginatingChangeDirectoryServerInvocationId}},
                     @{n='OrigUSN';e={$_.LastOriginatingChangeUSN}},
                     @{n='ChangeTime';e={$_.LastOriginatingChangeTime}},
                     @{n='Version';e={$_.Version}}
} 
