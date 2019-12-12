[cmdletbinding()]
Param ([string]$ServiceName = 'SamSS')

function Find-ServiceTree {
  Param (
    [System.ServiceProcess.ServiceController]$Service,
    [int]$Index
  )    
  $DependentServices = $Service.DependentServices
  foreach ($DependentService in $DependentServices) {
    Find-ServiceTree -Service $DependentService -Index 0
    $ObjHash = [ordered]@{
      Service = $Service.Name
      DependentService = $DependentService.Name
    }
    New-Object -TypeName psobject -Property $ObjHash
  }
}

$AllServices = Get-Service 
if ($AllServices.name -contains $ServiceName) {
  $ServiceObj = Get-Service -Name $ServiceName
  Find-ServiceTree -Service $ServiceObj -Index 0
}
else {Write-Warning "Service $($ServiceName) does not exist"}



