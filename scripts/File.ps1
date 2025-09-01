<#
.DESCRIPTION
List domain admin users
#>
function listAdminUsers
{
    $admins = Get-ADGroupMember "Domain Admins" -Recursive | Where-Object { $_.ObjectClass -eq 'user' } -ErrorAction silentlyContinue

    "=== Admin Users (Domain) ===" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
    if (!$admins) {
        "No domain admin user found" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
        return
    }
    foreach ($admin in $admins) {
        $admin.SamAccountName | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
List disabled admin users
#>
function listDisabledUsers
{
    $admins = Get-ADGroupMember "Domain Admins" -Recursive | Where-Object { $_.ObjectClass -eq 'user' } |
        ForEach-Object { Get-ADUser $_.SamAccountName -Properties Enabled } |
        Where-Object { -not $_.Enabled }

    "=== Disabled Users ===" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
    if (!$admins) {
        "No disabled user found" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
        return
    }
    foreach ($admin in $admins) {
        $admin.SamAccountName | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
List server installed service
#>
function ServiceServer
{
    $services = Get-Service | Where-Object { $_.DisplayName -like '*Server*' -or $_.DisplayName -like '*File*' } | Select-Object -ExpandProperty Name -ErrorAction silentlyContinue

    "=== Server Services ===" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
    if ($services) {
        "No server services found" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
        return
    }
    foreach ($service in $services) {
        "$($service)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
Check if line printers are enable and their status
#>
function CheckPrintersStatus
{
    $ports = Get-Printer | Select-Object PortName
    $value = "false"

    foreach ($port in $ports) {
        if ($port.PortName -like '*LPR*') {
            "LPR is active" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
            $value = "true"
        } elseif ($port.PortName -like '*LPD*') {
            "LPD is active" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
            $value = "true"
        }
    }
    if ($value -eq "false") {
        "LPR and LPD aren't used" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
Check SMB authentication rate limiter
#>
function SMBAuthRateLimiter
{
    $rateLimiter = Get-SmbServerConfiguration | Select-Object -ExpandProperty InvalidAuthenticationDelayTimeInMs -ErrorAction silentlyContinue

    "=== SMB authentication rate limiter ===" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
    if (!$rateLimiter) {
        "No SMB authentication rate limiter found" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
        return
    }
        "InvalidAuthenticationDelayTimeInMs: $($rateLimiter)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    }

    <#
    File server script main function
    #>
function FileMain
{
    listAdminUsers
    listDisabledUsers
    ServiceServer
    CheckPrintersStatus
    SMBAuthRateLimiter
}

FileMain
