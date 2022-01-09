$Services = Get-Service
$Services | ForEach-Object {
  $_.Name
  
}