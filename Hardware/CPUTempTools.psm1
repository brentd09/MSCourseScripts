function Get-CPUTemperature {
  <#
  .SYNOPSIS
    Shows the cpu temperature probe results
  .DESCRIPTION
    This uses a obscure WMI class to determine if there are one or more temperature 
    probes in the manchine and then reports on each zone in Kelvin, Celsius and
    Fahrenheit temperatures.
  .EXAMPLE
    Get-CPUTemperature 
    This will show all of the temperture zones and the detected temperatures that
    were measured there.
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 26 Dec 2021
      Versions:
        0.1 Basic temp information for each probe
  #>
  [CmdletBinding()]
  Param()
  $TemperatureProbes = Get-WmiObject -class  MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
  foreach ($TemperatureProbe in $TemperatureProbes) {
    $ObjProperties = [ordered]@{
      ThermalZone = $TemperatureProbe.InstanceName
      Kelvin = $TemperatureProbe.CurrentTemperature / 10
      Celsius = ($TemperatureProbe.CurrentTemperature / 10) - 273.15
      Faharenheit = (($TemperatureProbe.CurrentTemperature / 10) * 9 / 5) + 32
    }
    New-object -TypeName psobject -Property $ObjProperties   
  }
}



