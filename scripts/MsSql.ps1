<#
.DESCRIPTION
Display SQl services
#>
function ListSQLServices
{
    $Services = Get-Service | Where-Object DisplayName -Like "SQL*" -ErrorAction silentlyContinue

    "=== SQL Server Services ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    try {
        if (!$Services) {
            "No SQL server services found" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
            return
        }
        "$($Services)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    } catch {
        "Error in ListSQlServices: $($_.Exception.Message)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
List Admin Users
#>
function ListAdminUsers
{
    $serverInstance = Get-SQLInstance -ErrorAction silentlyContinue
    $query = @"
    SELECT name, type_desc, is_disabled
    FROM sys.server_principals
    WHERE IS_SRVROLEMEMBER('sysadmin', name) = 1
"@
    $adminUsers = Invoke-Sqlcmd -ServerInstance $serverInstance -Query $query -ErrorAction silentlyContinue

    "=== Admin Users ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    if (!$adminUsers) {
        "No admin users found" | Out-file -FilePath -Append -Encodding utf8
        return
    } else {
        foreach ($user in $adminUsers) {
            "$($user.name) - $($user.type_desc) - Disabled: $($user.is_disabled)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
        }
    }
}

<#
.DESCRIPTION
Display and list disabled admin Users
#>
function DisabledUsers
{
    $serverInstance = Get-Service | Where-Object { $_.Name -like 'MSSQL*' } | Select-Object DisplayName, Status -ErrorAction silentlyContinue
    $query = "SELECT name, is_disabled FROM sys.server_principals WHERE is_fixed_role = 1 AND name = 'sysadmin' AND is_disabled = 1"
    $disabledUsers = Invoke-Sqlcmd -ServerInstance $serverInstance -Query $query -ErrorAction silentlyContinue

    "=== Disabled Admin Users ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    if (!$disabledUsers) {
        "No disabled admin users found" | Out-file -Filepath -Append -Encoding utf8
        return
    }
    "$($disabledUsers)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
}
# function DisabledUsers
# {
#     try {
#         $instances = Get-SQLInstance
#         if (!$instances) {
#             return
#         }
#         "=== Disabled Admin Users ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#         foreach ($instance in $instances) {
#             if ($instance -eq "DEFAULT") {
#                 $serverInstance = "localhost"
#             } else {
#                 $serverInstance = "localhost\$instance"
#             }
#             $query = @"
# SELECT name, type_desc
# FROM sys.server_principals
# WHERE IS_SRVROLEMEMBER('sysadmin', name) = 1 AND is_disabled = 1
# "@
#             $disabledUsers = Invoke-Sqlcmd -ServerInstance $serverInstance -Query $query -ErrorAction Stop
#             if ($disabledUsers) {
#                 "Instance: $serverInstance" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
#                 foreach ($user in $disabledUsers) {
#                     "$($user.name) - $($user.type_desc)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
#                 }
#             } else {
#                     "No disabled admin users found in $serverInstance" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#             }
#         }
#     } catch {
#         "Error in DisabledUsers: $($_.Exception.Message)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
#     }
# }

<#
.DESCRIPTION
See last Users login
#>
# function LastUsersLog
# {
#     $serverInstance = Get-Service | Where-Object { $_.Name -like 'MSSQL*' } | Select-Object DisplayName, Status -ErrorAction silentlyContinue
#     $query = "SELECT p.name, p.type_desc, s.last_login
#         FROM sys.server_principals p
#         LEFT JOIN sys.syslogins s ON p.sid = s.sid
#         WHERE p.is_fixed_role = 1 AND p.name = 'sysadmin'"
#     $adminUserLog = Invoke-Sqlcmd -ServerInstance $serverInstance -Query $query -ErrorAction silentlyContinue

#     "=== Admin Last Login ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
#     if (!$adminUserLog) {
#         "No last login admin log found" | Out-file -Append -Encoding utf8
#         return
#     }
#     "$($adminUserLog)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
# }
function LastUsersLog
{
    "=== Admin Last Login ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    try {
        $instances = Get-SQLInstance
        if (!$instances) { return }
        foreach ($instance in $instances) {
            $serverInstance = if ($instance -eq "DEFAULT") { "localhost" } else { "localhost\$instance" }
            $query = @"
SELECT p.name, p.type_desc, MAX(s.last_successful_logon) as last_login
FROM sys.server_principals p
LEFT JOIN sys.dm_exec_sessions s ON p.sid = s.security_id
WHERE IS_SRVROLEMEMBER('sysadmin', p.name) = 1
GROUP BY p.name, p.type_desc
"@
            $adminUserLog = Invoke-Sqlcmd -ServerInstance $serverInstance -Query $query -ErrorAction Stop
            if ($adminUserLog) {
                "Instance: $serverInstance" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
                foreach ($log in $adminUserLog) {
                    "$($log.name) - Last Login: $($log.last_login)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
                }
            } else {
                "No login information found for $serverInstance" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
            }
        }
    } catch {
        "Error in LastUsersLog: $($_.Exception.Message)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
Display last password change
#>
# function LastPwdChange
# {
#     $serverInstance = Get-Service | Where-Object { $_.Name -like 'MSSQL*' } | Select-Object DisplayName, Status -ErrorAction silentlyContinue
#     $query = "SELECT p.name, p.type_desc, s.password_changed
#         FROM sys.server_principals p
#         LEFT JOIN sys.sql_logins s ON p.sid = s.sid
#         WHERE p.is_fixed_role = 1 AND p.name = 'sysadmin'"
#     $adminLastPwd = Invoke-Sqlcmd -ServerInstance $serverInstance -Query $query -ErrorAction silentlyContinue

#     "=== Admin Last Password change ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#     if (!$adminLastPwd) {
#         "No admin last password change log found" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#         return
#     }
#     "$($adminLastPwd)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
# }

<#
.DESCRIPTION
List Server Service
#>
function ListServerService
{
    $services = Get-Service | Where-Object { $_.DisplayName -like 'SQL Server*' } | Select-Object DisplayName, Status, Name -ErrorAction silentlyContinue

    "=== SQL Installed Service ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    if (!$services) {
        "No SQL installed service found" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
        return
    }
    "$($services)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
}

<#
.DESCRIPTION
List Disabled Spooler
#>
function IsSpoolerEnable
{
    try {
        $spoolers = Get-Service -Name Spooler -ErrorAction silentlyContinue
        "=== Disabled Spoolers ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
        if (!$spoolers) {
            "No disabled spoolers found" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
            return
        }
        foreach ($spooler in $spoolers) {
            if ($spooler.StartType -eq 'Disabled') {
                "$($spooler.StartType): $($spooler.Status)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
            }
        }
    } catch {
        "Error in IsSpoolerEnable: $($_.Exception.Message)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
Local User SQL
#>
# function LocalUserSql
# {
#     $serverInstance = Get-Service | Where-Object { $_.Name -like 'MSSQL*' } | Select-Object DisplayName, Status -ErrorAction silentlyContinue
#     $query = "SELECT name, type_desc FROM sys.database_principals WHERE type IN ('S', 'U') AND sid 0x0"
#     $localUsers = Invoke-Sqlcmd -ServerInstance $serverInstance -Database 'master' -Query $query -ErrorAction silentlyContinue

#     "=== Local Users SQL ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#     if (!$localUsers) {
#         "No SQL local users found" | Out-File -Filepath ".\info.txt" -Append -Encoding utf_
#         return
#     }
#     "$($localusers)" | Out-File -FilePath ".\info.txt" -Append -Enconding utf8
# }

<#
.DESCRIPTION
Check if WebDAV is disabled
#>
function checkWebDAV
{
    $data = Get-WindowsFeature -Name WebDAV* | Select-Object DisplayName, InstallState

    "=== WebDAV ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    if ($data.InstallState -eq "installed") {
        Remove-WindowsFeature -Name WebDAV-Redirector, WebDAV-Publishing
        checkWebDAV
    } else {
        "Disabled" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
    }
}

<#
.DESCRIPTION
Check Password Complexity of each admin user
#>
# function CheckPwdComplexity
# {
#     $admins = Get-LocalUser | Where-Object { $_.Name -eq "Administrator"} -ErrorAction silentlyContinue

#     "=== Admins Paswword Complexity ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#     if (!$admins) {
#         "No complexity log found" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
#         return
#     }
#     foreach ($admin in $admins) {
#         "$($admin.Name): $($admin.PasswordComplexity)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#     }
# }

<#
.DESCRIPTION
MSSql windows server main function#>
function SQLmain
{
    ListSQLServices
    ListAdminUsers
    DisabledUsers
    LastUsersLog
    #LastPwdChange
    ListServerService
    IsSpoolerEnable
    #LocalUserSql
    checkWebDAV
    #CheckPwdComplexity
}

SQLmain
