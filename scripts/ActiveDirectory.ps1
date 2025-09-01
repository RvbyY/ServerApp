<#
.DESCRIPTION
List admin users of the domain
#>
function ListAdmin
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
function ListAdminDisabled {
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
function ListServices
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
Test Local User Account Credentials
#>
# function TestUserCredentials
# {
#     $computers = @($env:COMPUTERNAME)
#     Write-Host "Prompting for password"
#     $username = Read-Host "Enter username to test"
#     $pswd = Read-Host "Type password" -AsSecureString
#     $decodedpswd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pswd))

#     "=== Credential Test Results ===" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#     foreach ($computer in $computers) {
#         try {
#             Add-Type -AssemblyName System.DirectoryServices.AccountManagement
#             $obj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine', $computer)
#             if ($obj.ValidateCredentials($username, $decodedpswd) -eq $True) {
#                 $result = "SUCCESS: Password for $username on $computer is correct"
#                 Write-Host $result -BackgroundColor Green
#             } else {
#                 $result = "FAILED: Password for $username on $computer is incorrect"
#                 Write-Host $result -BackgroundColor Red
#             }
#             $result | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#         } catch {
#             "ERROR testing $username on $computer : $($_.Exception.Message)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
#         }
#     }
# }

<#
.DESCRIPTION
Check Spooler
#>
function CheckSpooler
{
    $PrintNames = Get-ADComputer -Filter { ServicePrincipalName -like "PRINT/*" }

    "=== Disabled Spoolers ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    foreach ($PrintName in $PrintNames) {
        $Spooler = Get-Service -Name Spooler -ComputerName $PrintName.Name -ErrorAction silentlyContinue
        if ($Spooler.StartType -eq 'Disabled') {
            "$($PrintName.Name): $($Spooler.Status)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
        }
    }
}

<#
.DESCRIPTION
Check LSA
#>
function CheckLSA
{
    $infos = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Lsa"

    "=== LSA ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    "$($infos.EnabledLsa)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
}

<#
.DESCRIPTION
Check if Kerberos is disbled
#>
function CheckKerberos
{
    $users = Get-LocalUser

    "=== Kerberos ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    if ($users) {
        foreach ($user in $users) {
            $kerberos = Get-ADUser -Identity $user -Properties AuthenticationPolicies
            "$($user): $($kerberos)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
        }
    }
}

<#
.DESCRIPTION
List installed service
#>
function listInstalledService
{
    $Services = Get-Service

    "=== Installed Service ===" | out-File -FilePath ".\info.txt" -Append -Encoding utf8
    "$($Services)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
}

<#
.DESCRIPTION
Check if LAPS is enabled
#>
function CheckLAPS
{
    "=== LAPS Status ===" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8

    try {
        $computerName = $env:COMPUTERNAME
        $laps = Get-ADComputer -Identity $computerName -Properties ms-MCS-AdmPwd, ms-MCS-AdmPwdExpirationTime -ErrorAction Stop
        if ($laps.'ms-MCS-AdmPwd') {
            "LAPS is enabled for $computerName" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
            "Password expiration: $([datetime]::FromFileTime($laps.'ms-MCS-AdmPwdExpirationTime'))" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
        } else {
            "LAPS is not enabled for $computerName" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
        }
    }
    catch {
        "Error checking LAPS: $($_.Exception.Message)" | Out-File -FilePath ".\info.txt" -Append -Encoding utf8
    }
}


<#
.DESCRIPTION
Hide the username of the session
#>
function HideUsername
{
    $currentUser = Get-LocalUser | Where-Object {$_.Name -eq $env:USERNAME}

    if ($currentUser) {
        Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name $currentUser.Name -Value 1
    }
}

<#
.DESCRIPTION
Display SMB authentication time out/rate limiter#>
function SMBAuthTimeOut
{
    $rateLimiter = Get-smbServerConfiguration | Format-List -Property invalidAuthenticationDelayTimeInMs

    "=== SMB authentication rate limiter ===" | Out-file -Filepath ".\info.txt" -Append -Encoding utf8
    "$($rateLimiter)" | Out-File -Filepath ".\info.txt" -Append -Encoding utf8
}

<#
.DESCRIPTION
Main function of active directory script
#>
function ADMain
{
    ListAdmin
    ListAdminDisabled
    ListServices
    TestUserCredentials
    CheckSpooler
    CheckLSA
    CheckKerberos
    listInstalledService
    CheckLAPS
    HideUsername
     SMBAuthTimeOut
}

ADMain
