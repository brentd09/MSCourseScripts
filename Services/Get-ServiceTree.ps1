Param ([string]$ServiceName = 'XblAuthManager')
if ($Services.name -contains $ServiceName) {
  Find-ServicesThatAreDependent -ServiceName $ServiceName -Index 0
}
else {Write-Warning "Service $($ServiceName) does not exist"}


function Find-ServicesThatAreDependent {
  Param (
    [string]$ServiceName,
    [int]$Index
  )    
  $AllServicesWithDependencies = Get-Service | Where-Object  {$_.DependentServices.Count -gt 0}
  foreach ($ServiceThatIsDependent in $AllServicesWithDependencies) {
    if ($ServiceThatIsDependent.dependentservices.name -contains $ServiceName) {
#      Write-Host -ForegroundColor Yellow $ServiceName
      $Hash = @{ServiceName = $ServiceName; DependentService = $ServiceThatIsDependent.name;Index = $Index}
      $Obj1 = New-Object -TypeName psobject -Property $Hash
      $Obj1
      Find-ServicesThatAreDependent -ServiceName $ServiceThatIsDependent.name -Level $Index
      $SameServiceName = $ServiceName
      $Index = $Index + 1
    } 
  }
}



