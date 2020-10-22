
$SecretVaultNameArgCompletion = {
    Get-SecretVault  | Select -ExpandProperty Name | foreach-object {
        [System.Management.Automation.CompletionResult]::new($_)
    }
}