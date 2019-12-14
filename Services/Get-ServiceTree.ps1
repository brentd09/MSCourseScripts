[cmdletbinding()]
Param ([string]$ServiceName = 'SamSS')

function Find-ServiceTree {
  Param (
    [System.ServiceProcess.ServiceController]$Service
  )    
  $DependentServices = $Service.DependentServices
  $ObjHash = [ordered]@{
    Service = $Service.ServiceName
    DependentServiceNames = $DependentServices.ServiceName
  }
  New-Object -TypeName psobject -Property $ObjHash
  foreach ($DependentService in $DependentServices) {
    $DepSvc = Get-Service -Name $DependentService.ServiceName
    Find-ServiceTree -Service $DepSvc
  }
}

$AllServices = Get-Service 
if ($AllServices.ServiceName -contains $ServiceName) {
  $ServiceObj = Get-Service -Name $ServiceName
  Find-ServiceTree -Service $ServiceObj 
}
else {Write-Warning "Service $($ServiceName) does not exist"}



