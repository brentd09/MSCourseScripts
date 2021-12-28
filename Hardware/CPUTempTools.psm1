function Get-CPUTemperature {
  #REQUIRES -RunAsAdministrator
  <#
  .SYNOPSIS
    Shows the cpu temperature probe results
  .DESCRIPTION
    This uses a obscure WMI class to determine if there are one or more temperature 
    probes in the manchine and then reports on each zone in Kelvin, Celsius and
    Fahrenheit temperatures.
    While this looks like it works, the real truth is that this has not been implemented
    yet and it will return the same values every time the command is run. I found this out
    after seeing the same result every time even after putting the CPU under load, I did
    a bit of research and it appears that MSDN shows that this is not actually taking
    a temperature probe reading at all.
  .EXAMPLE
    Get-CPUTemperature 
    This will show all of the temperture zones and the detected temperatures that
    were measured there.
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 26 Dec 2021
      Versions:
        0.1 Basic temp information for each probe (after some research this does not atually work)
  #>
  [CmdletBinding()]
  Param()
  $TemperatureProbes = Get-CimInstance -ClassName MSAcpi_ThermalZoneTemperature -Namespace root/wmi 
  foreach ($TemperatureProbe in $TemperatureProbes) {
    $ObjProperties = [ordered]@{
      ThermalZone = $TemperatureProbe.InstanceName
      Kelvin = $TemperatureProbe.CurrentTemperature / 10
      Celsius = ($TemperatureProbe.CurrentTemperature / 10) - 273.15
      Faharenheit = (($TemperatureProbe.CurrentTemperature / 10  - 273.15) * 9 / 5) + 32
    }
    New-object -TypeName psobject -Property $ObjProperties   
  }
}



