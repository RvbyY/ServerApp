[CmdletBinding()]

param (
    [string]$InputFile = ".\info.txt",
    [string]$OutputFile = ".\server-report.html"
)

function ParseStorageData {
    param($content)
    $storageData = @()
    $lines = $content -split "`n"

    foreach ($line in $lines) {
        if ($line -match "([A-Z]): free space \(GB\): (\d+\.?\d*)") {
            $totalGB = (Get-PSDrive -PSProvider FileSystem).MaximumSize / 1GB
            $freeGB = $Matches[2]
            $usedGB =  (Get-PSDrive -PSProvider FileSystem).MaximumSize / 1GB - $freeGB
            $storageData += @{
                Drive = "$($Matches[1]):"
                Total = $totalGB
                Used = $usedGB
                Free = $freeGB
                UsedPercent = [math]::Round(($usedGB / $totalGB) * 100, 2)
            }
        }
    return $storageData
    }
}

function GenerateChartJS {
    param($storageData)
    if ($storageData.Count -eq 0) {
        return ""
    }
    $driveLabels = ($storageData | ForEach-Object { "'$($_.Drive)'"}) -join ","
    $usedData = ($storageData | ForEach-Object { $_.UsedPercent }) -join ","
    $freeData = ($storageData | ForEach-Object { 100 - $_.UsedPercent}) -join ","
    $totalSizes = ($storageData | ForEach-Object { if ( $_.Total ) { $_.Total } else { 0 } }) -join ","
    $chartScript = @"
    <script>
        const ctx1 = document.getElementById('storageChart').getContext('2d');
        const storageChart = new Chart(ctx1, {
            type: 'bar',
            data: {
                labels: [$driveLabels],
                datasets: [{
                    label: 'Used %',
                    data: [$usedData],
                    backgroundColor: 'rgba(231, 76, 60, 0.8)',
                    borderColor: 'rgba(231, 76, 60, 1)',
                    borderWidth: 1
                }, {
                    label: 'Free %',
                    data: [$freeData],
                    backgroundColor: 'rgba(46, 204, 113, 0.8)',
                    borderColor: 'rgba(46, 204, 113, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                            callback: function(value) {
                                return value + '%';
                            }
                        }
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Storage Usage by Drive'
                    }
                }
            }
        });
        const ctx2 = document.getElementById('storageDonut').getContext('2d');
        const storageDonut = new Chart(ctx2, {
            type: 'doughnut',
            data: {
                labels: [$driveLabels],
                datasets: [{
                    data: [$usedData],
                    backgroundColor: [
                        'rgba(231, 76, 60, 0.8)',
                        'rgba(52, 152, 219, 0.8)',
                        'rgba(155, 89, 182, 0.8)',
                        'rgba(241, 196, 15, 0.8)',
                        'rgba(46, 204, 113, 0.8)'
                    ],
                    borderColor: [
                        'rgba(231, 76, 60, 1)',
                        'rgba(52, 152, 219, 1)',
                        'rgba(155, 89, 182, 1)',
                        'rgba(241, 196, 15, 1)',
                        'rgba(46, 204, 113, 1)'
                    ],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Storage Usage Distribution'
                    },
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    </script>
"@

    return $chartScript
}

function txtToHTML {
    param($InputFile, $OutputFile)
    if (-not (Test-Path $InputFile)) {
        Write-Host "Input file not found: $InputFile"
        return
    }
    $content = Get-Content $InputFile -Raw
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $storageData = ParseStorageData -content $content
    $chartScript = GenerateChartJS -storageData $storageData
    $chartContainers = ""
    if ($storageData.Count -gt 0) {
        $chartContainers = @"
        <div class="section">
            <h3>Storage Visualization</h3>
            <div style="display: flex; justify-content: space-around; flex-wrap: wrap; gap: 20px;">
                <div style="width: 45%; min-width: 400px;">
                    <canvas id="storageChart"></canvas>
                </div>
                <div style="width: 45%; min-width: 400px;">
                    <canvas id="storageDonut"></canvas>
                </div>
            </div>
        </div>
"@
    }
    $html = @"
    <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Detection Report</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid rgb(177, 53, 123);
            padding-bottom: 10px;
        }
        .metadata {
            background: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .section {
            margin: 20px 0;
            padding: 15px;
            border-left: 4px solid rgb(163, 37, 159);
            background: #f8f9fa;
        }
        .section h3 {
            color:rgb(168, 34, 119);
            margin-top: 0;
        }
        pre {
            background: #2c3e50;
            color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-family: 'Courier New', monospace;
        }
        .status-ok { color: #27ae60; font-weight: bold; }
        .status-warning { color: #f39c12; font-weight: bold; }
        .status-error { color: #e74c3c; font-weight: bold; }
        .highlight { background-color: #fff3cd; padding: 2px 4px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Server Detection Report</h1>
        <div class="metadata">
            <strong>Generated:</strong> $timestamp<br>
            <strong>Server:</strong> $env:COMPUTERNAME<br>
            <strong>User:</strong> $env:USERNAME
        </div>
        $chartContainers
        <div class="section">
            <h3>Detection Results</h3>
            <pre>$content</pre>
        </div>
    </div>
    $chartScript
</body>
</html>
"@
    if ($storageData.Count -gt 0) {
        $chartContainers = @"
        # ... your existing chart HTML ...
"@
        .\scripts\txtToHTML.ps1
    } else {
        $systemStorage = Get-StorageInfo
        $content += "`n=== Drives ===`n$systemStorage"
        $storageData = ParseStorageData -content $content
        $chartScript = GenerateChartJS -storageData $storageData
        if ($storageData.Count -gt 0) {
            $chartContainers = @"
            # ... your existing chart HTML ...
"@
        }
    }

    $html | Out-File -FilePath $OutputFile -Encoding utf8
    Write-Host "txt info: $InputFile and HTML report generated: $OutputFile" -ForegroundColor Magenta
}

function Get-StorageInfo {
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $storageInfo = @()
    
    foreach ($drive in $drives) {
        $totalGB = [math]::Round($drive.Size / 1GB, 2)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 2)
        $storageInfo += "Drive $($drive.DeviceID) - Total: $totalGB GB, Used: $usedGB GB ($usedPercent%), Free: $freeGB GB"
    }
    return $storageInfo -join "`n"
}

txtToHTML -InputFile $InputFile -OutputFile $OutputFile
