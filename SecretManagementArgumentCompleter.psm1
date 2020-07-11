function Get-SecretInfo {
    [CmdletBinding()]
    param (
        [String]$Vault,
        [String]$Name,
        [Switch]$Cache 
    )
    
    $CacheParamstr = 'Cache'
    $VaultPath = "$env:USERPROFILE\Powershell\SecretsManagement\Vaults"
    $UseCache = $False 

    if ($PSBoundParameters.ContainsKey($CacheParamstr)) {
        $UseCache = $PSBoundParameters.Item($CacheParamstr)
        [void]$PSBoundParameters.Remove($CacheParamstr)
    }
    
   
    if (! (Test-Path $VaultPath)) { New-Item $VaultPath -ItemType Directory }

    $VaultNames = [System.Collections.Generic.List[String]]::new()
    $CachedOutput = [System.Collections.Generic.List[PSObject]]::new()



    if ($UseCache) {
        if ($PSBoundParameters.ContainsKey('Vault')) {
            $VaultNames.Add($PSBoundParameters.Item('Vault'))
        }
        else {
            $VaultNames = @(Get-SecretVault | Select -ExpandProperty Name)
        }

        foreach ($Vault in $VaultNames) {
            if ($Vault -eq 'BuiltInLocalVault') {
                Get-SecretInfo -Vault 'BuiltInLocalVault' | ForEach-Object { [Void]($CachedOutput.Add($_)) }
                continue
            }
            
                
            
            $CurrVaultPath = "$VaultPath\$Vault.json"
            if (Test-Path -Path $CurrVaultPath) {
                $value = (Get-Content -Path $CurrVaultPath -Raw | ConvertFrom-Json) | Select -Property Name, @{n = 'Type'; e = { [Microsoft.PowerShell.SecretManagement.SecretType]$_.Type } }, VaultName
                $Value | ForEach-Object { [void]($CachedOutput.Add($_)) }
            }
            else {
                try {
                    $CurrentVault = @(Microsoft.PowerShell.SecretManagement\Get-SecretInfo -Vault $Vault)
                    $CurrentVault |  ConvertTo-Json | Out-File $CurrVaultPath
                    $CurrentVault | ForEach-Object { [void]($CachedOutput.Add($_)) }
                }
                catch {
                    
                }
            }
        }
        return $CachedOutput
    }
    
    
    if (! $PSBoundParameters.ContainsKey('Vault')) { Get-ChildItem -Path $VaultPath | Remove-Item }
    $Output = Microsoft.PowerShell.SecretManagement\Get-SecretInfo @PSBoundParameters
    $GrpVault = $Output | Group-Object -Property VaultName
    
    foreach ($grp in $GrpVault) {
        if ($grp.Name -eq 'BuiltInLocalVault') { Continue }
        $CurrVaultPath = "$VaultPath\$($grp.Name).json"
        $grp.Group | ConvertTo-Json | Out-File $CurrVaultPath
    }

    return $Output
}

Function Clear-AzKeyVaultCache() {
    $Script:___AZkvCompletion = [System.Collections.Generic.Dictionary[String, psobject[]]]::new()
    

    $Script:___AZkvCompletion = [System.Collections.Generic.Dictionary[String, psobject[]]]::new()
    Add-Member -InputObject $Script:___AZkvCompletion -Name 'AddKey' -MemberType ScriptMethod {
        Param($Parameters)
        $Context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext    
        $Key = "$($Context.Account.Id)$($Context.Subscription.Id)"
        $KeyExist = $Script:___AZkvCompletion.ContainsKey($key)
    
        if (!$KeyExist) {
            $Script:___AZkvCompletion.Add($key, $null)
            $Vaults = Foreach ($Vault in (Get-AzKeyVault).VaultName) {
                [PSCustomObject]@{
                    VaultName = $Vault 
                    Secrets   = $null
                }
            
            
            }
            $Script:___AZkvCompletion.Item($key) = $Vaults
        }
    }
}

Register-ArgumentCompleter -CommandName Get-Secret, Get-SecretInfo, Set-Secret, Test-SecretVault, Remove-Secret -ParameterName Vault -ScriptBlock {
    Get-SecretVault  | Select -ExpandProperty Name | foreach-object {
        [System.Management.Automation.CompletionResult]::new($_)
    }
}

Register-ArgumentCompleter -CommandName Unregister-SecretVault, Test-SecretVault, Get-SecretVault -ParameterName Name -ScriptBlock {
    Get-SecretVault  | Select -ExpandProperty Name | foreach-object {
        [System.Management.Automation.CompletionResult]::new($_)
    }
}
 
Register-ArgumentCompleter -CommandName Get-Secret, Get-SecretInfo, Remove-Secret, Set-Secret -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $VaultNameFilter = @{}
    if ( $fakeBoundParameter.ContainsKey('Vault')) {
        $VaultNameFilter = @{Vault = $fakeBoundParameter.Vault }
    }
    (Get-SecretInfo @VaultNameFilter -cache)  | Select -ExpandProperty Name  | foreach-object {
        [System.Management.Automation.CompletionResult]::new($_)
    }
}

## AZ Keyvault argument completion (in-memory)
$VaultNameArgumentCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext    
    $Script:___AZkvCompletion.AddKey($fakeBoundParameter)
    $Script:___AZkvCompletion.Item($key) | % { [System.Management.Automation.CompletionResult]::new($_) }
}

$SecretNameArgumentCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
   
    $Script:___AZkvCompletion.AddKey($fakeBoundParameter)
    $Context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext    
    if ($fakeBoundParameter.ContainsKey('VaultName')) {
        $Key = "$($Context.Account.Id)$($Context.Subscription.Id)"

        $MyVault = ($Script:___AZkvCompletion.Item($Key) | 
                Where VaultName -eq $fakeBoundParameter.item('VaultName') | Select -First 1)

        if ($MyVault.Secrets -eq $null) {
            $Secrets = Get-AzKeyVaultSecret -VaultName ($fakeBoundParameter.Item('VaultName'))
            $MyVault.Secrets = $Secrets.Name
            
            $MyVault.Secrets  | % { [System.Management.Automation.CompletionResult]::new("'$_'", $_ , [System.Management.Automation.CompletionResultType]::Text, $_) }
        }
        else {
            $MyVault.Secrets  | % { [System.Management.Automation.CompletionResult]::new("'$_'", $_, [System.Management.Automation.CompletionResultType]::Text, $_) }
        }   
   
    }

    # 
}
Register-ArgumentCompleter -ParameterName Name -ScriptBlock $SecretNameArgumentCompletion -CommandName Add-AzKeyVaultCertificate, Add-AzKeyVaultKey, Backup-AzKeyVaultCertificate, Backup-AzKeyVaultKey, Backup-AzKeyVaultManagedStorageAccount, Backup-AzKeyVaultSecret, Get-AzKeyVaultCertificate, Get-AzKeyVaultCertificateIssuer, Get-AzKeyVaultCertificateOperation, Get-AzKeyVaultCertificatePolicy, Get-AzKeyVaultKey, Get-AzKeyVaultManagedStorageSasDefinition, Get-AzKeyVaultSecret, Import-AzKeyVaultCertificate, Remove-AzKeyVaultCertificate, Remove-AzKeyVaultCertificateIssuer, Remove-AzKeyVaultCertificateOperation, Remove-AzKeyVaultKey, Remove-AzKeyVaultManagedStorageSasDefinition, Remove-AzKeyVaultSecret, Set-AzKeyVaultCertificateIssuer, Set-AzKeyVaultCertificatePolicy, Set-AzKeyVaultManagedStorageSasDefinition, Set-AzKeyVaultSecret, Stop-AzKeyVaultCertificateOperation, Undo-AzKeyVaultCertificateRemoval, Undo-AzKeyVaultKeyRemoval, Undo-AzKeyVaultManagedStorageAccountRemoval, Undo-AzKeyVaultManagedStorageSasDefinitionRemoval, Undo-AzKeyVaultSecretRemoval, Update-AzKeyVaultCertificate, Update-AzKeyVaultKey, Update-AzKeyVaultSecret 
Register-ArgumentCompleter -ParameterName VaultName -ScriptBlock $VaultNameArgumentCompletion -CommandName Add-AzKeyVaultCertificate, Add-AzKeyVaultCertificateContact, Add-AzKeyVaultKey, Add-AzKeyVaultManagedStorageAccount, Add-AzKeyVaultNetworkRule, Backup-AzKeyVaultCertificate, Backup-AzKeyVaultKey, Backup-AzKeyVaultManagedStorageAccount, Backup-AzKeyVaultSecret, Get-AzKeyVault, Get-AzKeyVaultCertificate, Get-AzKeyVaultCertificateContact, Get-AzKeyVaultCertificateIssuer, Get-AzKeyVaultCertificateOperation, Get-AzKeyVaultCertificatePolicy, Get-AzKeyVaultKey, Get-AzKeyVaultManagedStorageAccount, Get-AzKeyVaultManagedStorageSasDefinition, Get-AzKeyVaultSecret, Import-AzKeyVaultCertificate, Remove-AzKeyVault, Remove-AzKeyVaultAccessPolicy, Remove-AzKeyVaultCertificate, Remove-AzKeyVaultCertificateContact, Remove-AzKeyVaultCertificateIssuer, Remove-AzKeyVaultCertificateOperation, Remove-AzKeyVaultKey, Remove-AzKeyVaultManagedStorageAccount, Remove-AzKeyVaultManagedStorageSasDefinition, Remove-AzKeyVaultNetworkRule, Remove-AzKeyVaultSecret, Restore-AzKeyVaultCertificate, Restore-AzKeyVaultKey, Restore-AzKeyVaultManagedStorageAccount, Restore-AzKeyVaultSecret, Set-AzKeyVaultAccessPolicy, Set-AzKeyVaultCertificateIssuer, Set-AzKeyVaultCertificatePolicy, Set-AzKeyVaultManagedStorageSasDefinition, Set-AzKeyVaultSecret, Stop-AzKeyVaultCertificateOperation, Undo-AzKeyVaultCertificateRemoval, Undo-AzKeyVaultKeyRemoval, Undo-AzKeyVaultManagedStorageAccountRemoval, Undo-AzKeyVaultManagedStorageSasDefinitionRemoval, Undo-AzKeyVaultRemoval, Undo-AzKeyVaultSecretRemoval, Update-AzKeyVault, Update-AzKeyVaultCertificate, Update-AzKeyVaultKey, Update-AzKeyVaultManagedStorageAccount, Update-AzKeyVaultManagedStorageAccountKey, Update-AzKeyVaultNetworkRuleSet, Update-AzKeyVaultSecret 
Clear-AzKeyVaultCache



