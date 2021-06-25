
Register-ArgumentCompleter -ParameterName Name -ScriptBlock $AZKVSecretNameArgumentCompletion -CommandName  Backup-AzKeyVaultSecret, Get-AzKeyVaultSecret, Remove-AzKeyVaultSecret, Set-AzKeyVaultSecret , Update-AzKeyVaultSecret 
Register-ArgumentCompleter -ParameterName VaultName -ScriptBlock $AZKVVaultNameArgumentCompletion -CommandName  Backup-AzKeyVaultSecret, Get-AzKeyVault, Get-AzKeyVaultSecret, Remove-AzKeyVault, Remove-AzKeyVaultSecret, Restore-AzKeyVaultSecret, Set-AzKeyVaultSecret, Update-AzKeyVaultSecret 
Register-ArgumentCompleter -CommandName Register-SecretVault -ParameterName ModuleName -ScriptBlock $RegisterSecretVaultArgCompletion
Register-ArgumentCompleter -CommandName Register-SecretVault -ParameterName VaultParameters -ScriptBlock $RegisterSecretVaultArgCompletion

#endregion
Register-ArgumentCompleter -CommandName Get-Secret, Get-SecretInfo, Set-Secret, Test-SecretVault, Remove-Secret -ParameterName Vault -ScriptBlock $SecretVaultNameArgCompletion
Register-ArgumentCompleter -CommandName Unregister-SecretVault, Test-SecretVault, Get-SecretVault -ParameterName Name -ScriptBlock $SecretVaultNameArgCompletion
Register-ArgumentCompleter -CommandName Get-Secret, Get-SecretInfo, Remove-Secret, Set-Secret -ParameterName Name -ScriptBlock $SecretNameArgCompletion