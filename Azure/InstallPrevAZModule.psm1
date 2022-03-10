function Install-PreviousAZModule {
  [cmdletBinding()]
  Param(
    $AZVersion = '7.0.0'
  )
  $az = Find-Module az -RequiredVersion $AZVersion 
  foreach ($Module in $az.Dependencies) {
    if ($Module.MinimumVersion) {$Version = $Module.MinimumVersion}
    else {$Version = $Module.RequiredVersion }
    Install-Module -Name $Module.Name -RequiredVersion $Version -Force
  }
}
