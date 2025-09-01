<#
.DESCRIPTION
List admin users of the domain
#>
function AdminList
{
    $admins = Get-ADGroupMember "Domain Admins" -Recursive | ForEach-Object {
        if ($_.objectClass -eq 'user') {
            $user = Get-ADUser $_.SamAccountName -Properties Enabled
            if (-not $user.Enabled) { $user }
        }
    }

    "=== Admin Users ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    foreach ($admin in $admins) {
        "$($admin)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
List admin disabled
#>
function AdminDisabled {
    $admins = Get-ADGroupMember "Domain Admins" -Recursive | ForEach-Object {
        if ($_.objectClass -eq 'user') {
            $user = Get-ADUser $_.SamAccountName -Properties Enabled
            if (-not $user.Enabled) { $user }
        }
    }

    "=== Disabled Domain Admin Users ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    if (!$admins) {
        "No disabled domain admin users found" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
        return
    }
    foreach ($admin in $admins) {
        $admin.SamAccountName | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
List server services
#>
function ServicesList
{
    $services = Get-Service | Where-Object { $_.DisplayName -like '*Server*' -or $_.DisplayName -like '*File*' } | Select-Object Name -ErrorAction silentlyContinue

    "=== Installed Services List ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    if (!$services) {
        "No services installed found" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
        return
    }
    foreach ($service in $services) {
        "$($service)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
List liner printers status and check if there're enable
#>
function PrintersStatus
{
    $ports = Get-Printer | Select-Object PortName
    $value = "false"

    foreach ($port in $ports) {
        if ($port.PortName -like '*LPR*') {
            "LPR is active" | Out-File -FilePath "info.txt" -Append -Encoding utf8
            $value = "true"
        } elseif ($port.PortName -like '*LPD*') {
            "LPD is active" | Out-File -FilePath "info.txt" -Append -Encoding utf8
            $value = "true"
        }
    }
    if ($value -eq "false") {
        "LPR and LPD aren't used" | Out-File -FilePath "info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
RDS script main function
#>
function RDSMain
{
    AdminList
    AdminDisabled
    ServicesList
    PrintersStatus
}

RDSMain
