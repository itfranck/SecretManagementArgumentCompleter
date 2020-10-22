$SecretNameArgCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $DefaultVault = 'BuiltInLocalVault'

    $UseCache = $false
    $VaultNameFilter = @{}
    if ( $fakeBoundParameter.ContainsKey('Vault')) {
        if ($fakeBoundParameter.Vault -is [hashtable]) { $fakeBoundParameter.Vault = $fakeBoundParameter.Vault.Vault }

        if ($fakeBoundParameter.Vault -eq $DefaultVault) {
            return (Get-SecretInfo -Vault $DefaultVault).Name | % { [System.Management.Automation.CompletionResult]::new("'$_'", $_ , [System.Management.Automation.CompletionResultType]::Text, $_) }
        }
        $Vault = $fakeBoundParameter.Vault
        $VaultNameFilter = @{Vault = $Vault }
        $UseCache = $Script:_SecretMgmtCompletion.ContainsKey($Vault)

        if (-not $UseCache) {
            try {
                $Secrets = Get-SecretInfo @VaultNameFilter  -ErrorAction Stop
                $Script:_SecretMgmtCompletion.Add($Vault, $Secrets.Name)
                Save-SecretCache 
            }
            catch {}
        }
        return   $Script:_SecretMgmtCompletion.Item($Vault)  | % { [System.Management.Automation.CompletionResult]::new("'$_'", $_ , [System.Management.Automation.CompletionResultType]::Text, $_) }
    } 

    $Vaults = (Get-SecretVault).Name
    $NeedSave = $false
    $Output = [System.Collections.Generic.List[Object]]::new()
    Foreach ($V in $Vaults) {
        if ($V -eq $DefaultVault) { 
            $Secrets = (Get-SecretInfo -Vault $DefaultVault) | Select VaultName, Name
            $Output.AddRange($Secrets)
            Continue
        }
        
        if ($Script:_SecretMgmtCompletion.ContainsKey($V)) {
            $Secrets = $_SecretMgmtCompletion.Item($V) | % { [PSCustomObject]@{
                    VaultName = $V
                    Name      = $_
                } }
            $Output.AddRange($Secrets) 
        }
        else {
            try {
                $Secrets = Get-SecretInfo -Vault $V  -ErrorAction Stop
                $Script:_SecretMgmtCompletion.Add($V, $Secrets.Name)
                $Output.AddRange(($Secrets | Select VaultName, Name))
                $NeedSave = $true
            }
            catch {}
        }
    }
    if ($NeedSave) { Save-SecretCache }

    $Statement = ""
    $PName = $commandAst.CommandElements.parameterName
    if ($null -ne $PName -and $PName.Contains('Name')) {
        $Statement = "'{1}' -Vault '{0}'"
    }
    else {
        $Statement = "-Vault '{0}' -Name '{1}'"
    }

    return $Output  | % {
        $o = $Statement -f $_.VaultName, $_.Name
        [System.Management.Automation.CompletionResult]::new($o, $_.Name , [System.Management.Automation.CompletionResultType]::Text, $_.Name) }

}