
function Save-SecretCache ([Switch]$Az) {
    if ($Script:InMemory) { return }
    if (! (Test-Path -Path $ConfigPaths.Directory)) { New-Item $ConfigPaths.Directory -ItemType Directory -Force }

    if ($az) {
        $_AZkvCompletion | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPaths.AzConfig
        try { (Get-Item -Path $ConfigPaths.AzConfig).Encrypt() }  catch {}
    }
    else {
        $_SecretMgmtCompletion  | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPaths.SecretConfig
        try { (Get-Item -Path $ConfigPaths.SecretConfig).Encrypt() }  catch {}
    }
}