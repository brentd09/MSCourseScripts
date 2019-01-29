Function Get-Enum {
  Param (
    [Parameter(Mandatory=$true)]
    $TypeClass
  )
  $EnumNum = [enum]::GetValues($TypeClass).Value__
  $EnumStr = [enum]::GetNames($TypeClass)
  foreach ($Index in (0..($EnumNum.count - 1))) {
    $NewObjProps = [ordered]@{
      Number = $EnumNum[$Index]
      Name   = $EnumStr[$Index]
    }
    New-Object -TypeName psobject -Property $NewObjProps
  }
}