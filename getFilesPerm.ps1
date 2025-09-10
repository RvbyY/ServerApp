function getFilePerm
{
    $files = Get-ChildItem -Recurse

    if (!$files) {
        Write-Host "No files found" -ForegroundColor Red
    }
    foreach ($file in $files) {
        Write-Host "$($file.Mode)   $($file.LastWriteTime)    $($file.Length)   $($file.Name)"
        $rights = Get-Acl $file
        $rights = $rights.Access | Select-Object IdentityReference
        foreach ($right in $rights) {
            Write-Host "$($right)" -ForegroundColor Blue
        }
    }
}

function main
{
    getFilePerm
    return
}

main
