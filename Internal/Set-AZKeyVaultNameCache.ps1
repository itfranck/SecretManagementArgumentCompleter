function Set-AZKeyVaultNameCache {
    $Context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext    
    $Vaults = Get-AzKeyVault 
    Foreach ($v in $Vaults) {
        $Key = "$($v.VaultName)|$($Context.Subscription.Id)"
        
        if (!$_AZkvCompletion.ContainsKey($Key)) {
            $_AZkvCompletion.Add($Key, $null)
        }
    }
    Save-SecretCache -Az 
}