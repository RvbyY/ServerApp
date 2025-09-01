<#
.DESCRIPTION
List domain admin user
#>
function ListUsers
{
    $admins = Get-ADGroupMember "Domain Admins" -Recursive | ForEach-Object {
        if ($_.objectClass -eq 'user') {
            $user = Get-ADUser $_.SamAccountName -Properties Enabled
            if (-not $user.Enabled) { $user }
        }
    }

    "=== Admins Users ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    if (!$admins) {
        "No admin user found" | Out-file -FilePath ".\info.txt" -Append -Encoding utf8
        return
    }
    foreach ($admin in $admins) {
        "$($admin)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
List disabled admin user
#>
function DisabledAdminUser
{
    $admins = Get-ADGroupMember "Domain Admins" -Recursive | ForEach-Object {
        if ($_.objectClass -eq 'user') {
            $user = Get-ADUser $_.SamAccountName -Properties Enabled
            if (-not $user.Enabled) { $user }
        }
    }

    "=== Disabled Admin Users ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    if (!$admins) {
        "No disabled admin user found" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
        return
    }
    "$($admins)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
}

<#
.DESCRIPTION
List server installed service
#>
function InstalledServicesList
{
    $services = Get-Service | Sort-Object DisplayName -ErrorAction silentlyContinue

    "=== Installed Service ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    if (!$services) {
        "No service installed" | Out-file -FilePath ".\nfo.txt" -Append -Encoding utf8
        return
    }
    "$($services)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
}

<#
Check if line printers are enable and their status
#>
function CheckLinePrintersStatus
{
    $ports = Get-Printer | Select-Object Name, PortName
    $value = "false"

    foreach ($port in $ports) {
        if ($port.PortName -eq '*LPR*') {
            "LPR is active" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
            $value = "true"
        } elseif ($port.PortName -eq '*LPD*') {
            "LPD is active" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
            $value = "true"
        }
    }
    if ($value -eq "false") {
        "LPR and LPD aren't used" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
Print server script main function
#>
function PrintMain
{
    ListUsers
    DisabledAdminUser
    InstalledServicesList
    CheckLinePrintersStatus
}

PrintMain
