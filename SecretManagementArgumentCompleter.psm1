Using module Microsoft.PowerShell.SecretManagement
Import-Module Microsoft.PowerShell.SecretManagement
#New-Alias -Name 'Get-SecretInfo' -Value Microsoft.Powershell.SecretManagement\Get-SecretInfo -Scope Global

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
