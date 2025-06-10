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

function Show-AZAverageCPU {
    # # # Untested as yet
    [cmdletbinding()]
    param (
        [string]$VMName = 'win1'
    )
    $WarningPreference='SilentlyContinue'
    $vm = Get-AzVM -Name $VMName
    $ResourceID = $vm.Id
    $Metrics = Get-AzMetric -ResourceId $ResourceID -TimeGrain "00:01:00" -MetricName "Percentage CPU" -StartTime (Get-Date).AddDays(-1) -EndTime (Get-Date)
    $dataPoints = $Metrics.Data | Select-Object TimeStamp, Average
    
    # Convert data to JavaScript arrays
    $labels = $dataPoints | ForEach-Object { '"' + $_.TimeStamp.ToString("HH:mm") + '"' } -join ', '
    $values = $dataPoints | ForEach-Object { $_.Average } -join ', '
    
    # Generate HTML with Chart.js
    $html = @"
<html>
<head>
    <title>Azure VM CPU Usage</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h2>CPU Usage for VM: $VMName</h2>
    <canvas id="cpuChart" width="800" height="400"></canvas>
    <script>
        const ctx = document.getElementById('cpuChart').getContext('2d');
        const cpuChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [$labels],
                datasets: [{
                    label: 'CPU %',
                    data: [$values],
                    fill: false,
                    borderColor: 'rgb(75, 192, 192)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

    # Save and open the HTML report
    $outputPath = "$env:TEMP\AzureVM_CPU_$VMName.html"
    $html | Out-File -FilePath $outputPath -Encoding utf8
    Start-Process $outputPath
}

