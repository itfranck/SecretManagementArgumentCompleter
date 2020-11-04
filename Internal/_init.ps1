Param(
    [parameter(Mandatory = $false)]
    [Switch]$InMemory
)
$Script:InMemory = $InMemory

Clear-SecretManagementArgumentCompleterCache
$ConfigPaths = @{
    Directory = "$env:LOCALAPPDATA\Powershell\SecretManagement"
}
$ConfigPaths.AzConfig = "$($ConfigPaths.Directory)\AzConfig.json"
$ConfigPaths.SecretConfig = "$($ConfigPaths.Directory)\SecretConfig.json"

Clear-SecretManagementArgumentCompleterCache

if (! $InMemory) {
    if (Test-Path -Path $ConfigPaths.Directory) {
        if (Test-Path -Path $ConfigPaths.AzConfig) {
            $config = Get-Content -Path $ConfigPaths.AzConfig -Raw | ConvertFrom-Json
            ($Config | get-member -MemberType NoteProperty).Name | foreach {
                $_AZkvCompletion.Add($_, $Config."$_")
            }
        }
        if (Test-Path -Path $ConfigPaths.SecretConfig) {
            $Config = Get-Content -Path $ConfigPaths.SecretConfig -Raw | ConvertFrom-Json
            ($Config | get-member -MemberType NoteProperty).Name | foreach {
                $_SecretMgmtCompletion.Add($_, $Config."$_")
            }
    
        }
    }
}


Register-ArgumentCompleter -ParameterName Name -ScriptBlock $AZKVSecretNameArgumentCompletion -CommandName  Backup-AzKeyVaultSecret, Get-AzKeyVaultSecret, Remove-AzKeyVaultSecret, Set-AzKeyVaultSecret , Update-AzKeyVaultSecret 
Register-ArgumentCompleter -ParameterName VaultName -ScriptBlock $AZKVVaultNameArgumentCompletion -CommandName  Backup-AzKeyVaultSecret, Get-AzKeyVault, Get-AzKeyVaultSecret, Remove-AzKeyVault, Remove-AzKeyVaultSecret, Restore-AzKeyVaultSecret, Set-AzKeyVaultSecret, Update-AzKeyVaultSecret 
Register-ArgumentCompleter -CommandName Register-SecretVault -ParameterName ModuleName -ScriptBlock $RegisterSecretVaultArgCompletion
Register-ArgumentCompleter -CommandName Register-SecretVault -ParameterName VaultParameters -ScriptBlock $RegisterSecretVaultArgCompletion

#endregion
Register-ArgumentCompleter -CommandName Get-Secret, Get-SecretInfo, Set-Secret, Test-SecretVault, Remove-Secret -ParameterName Vault -ScriptBlock $SecretVaultNameArgCompletion
Register-ArgumentCompleter -CommandName Unregister-SecretVault, Test-SecretVault, Get-SecretVault -ParameterName Name -ScriptBlock $SecretVaultNameArgCompletion
Register-ArgumentCompleter -CommandName Get-Secret, Get-SecretInfo, Remove-Secret, Set-Secret -ParameterName Name -ScriptBlock $SecretNameArgCompletion