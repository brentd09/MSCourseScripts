function Get-AZAverageCPU {
  [cmdletbinding()]
  Param (
    [string]$VMName = 'win1'
  )
  $WarningPreference='SilentlyContinue'
  $vm = get-azvm
  $ResourceID = $vm.Id
  $Metric = Get-AzMetric -ResourceId $ResourceID -timeGrain "00:01:00" -MetricName "Percentage CPU" -StartTime (Get-Date).AddDays(-1) -EndTime (Get-Date)
  $metric.data | where {$_.Average} | Select-Object TimeStamp,Average 
}
