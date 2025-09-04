[CmdletBinding()]

param (
    [string]$InputFile = ".\info.txt",
    [string]$OutputFile = ".\server-report.html"
)

function txtToHTML {
    param($InputFile, $OutputFile)
    if (-not (Test-Path $InputFile)) {
        Write-Host "Input file not found: $InputFile"
        return
    }
    $content = Get-Content $InputFile -Raw
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $html = @"
    <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Detection Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;ls
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
            border-bottom: 3px solidrgb(177, 53, 123);
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
            border-left: 4px solidrgb(163, 37, 159);
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
        <div class="section">
            <h3>Detection Results</h3>
            <pre>$content</pre>
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputFile -Encoding utf8
    Write-Host "txt info: $InputFile and HTML report generated: $OutputFile" -ForegroundColor Magenta
}

txtToHTML -InputFile $InputFile -OutputFile $OutputFile