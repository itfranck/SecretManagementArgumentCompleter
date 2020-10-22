
$AZKVVaultNameArgumentCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext    
    $Items = $Script:_AZkvCompletion.Keys.Where( { $_ -like "*|$($Context.Subscription.Id)" })
    if ($Items.count -eq 0) {
        $Vnames = (Get-AzKeyVault).VaultName
        if ($Vnames.count -gt 0 ) {
            $Vnames | % { $Script:_AZkvCompletion."$_|$($Context.Subscription.Id)" = $null }
        }
    }
    
    if ($Items.count -gt 0) {
        return $Items | % { [System.Management.Automation.CompletionResult]::new(($_.Split('|')[0])) }
    }
}

$AZKVSecretNameArgumentCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext    
    
    if ($fakeBoundParameter.ContainsKey('VaultName')) {
        if ($fakeBoundParameter.VaultName -is [hashtable]) { $fakeBoundParameter.VaultName = $fakeBoundParameter.VaultName.VaultName }
        $VaultName = $fakeBoundParameter.item('VaultName')
        $Key = "$VaultName|$($Context.Subscription.Id)"
        if (!$Script:_AZkvCompletion.ContainsKey($Key) -and 
            $_AZkvCompletion.Keys.Where( { $_ -like "*|$($Context.Subscription.Id)" }).Count -eq 0) {
            Set-AZKeyVaultNameCache 
        }
        
        if (!$Script:_AZkvCompletion.ContainsKey($Key)) { return $null }
        $MyVault = $Script:_AZkvCompletion.Item($Key)
        
        if ($MyVault -eq $null) {
            $Secrets = Get-AzKeyVaultSecret -VaultName ($VaultName)
            $Script:_AZkvCompletion.Item($Key) = $Secrets.Name
            Save-SecretCache -Az 
            return $Script:_AZkvCompletion.Item($Key)  | % { [System.Management.Automation.CompletionResult]::new("'$_'", $_ , [System.Management.Automation.CompletionResultType]::Text, $_) }
        }
        else {
            return $MyVault  | % { [System.Management.Automation.CompletionResult]::new("'$_'", $_, [System.Management.Automation.CompletionResultType]::Text, $_) }
        }   
   
    }
}