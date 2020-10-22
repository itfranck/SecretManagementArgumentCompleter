$RegisterSecretVaultArgCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $GetVaultParamStatement = {
        try {
            $Context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext    
            $SubscriptionId = $Context.Subscription.Id
        }
        catch {
                    
        }
        $Hashtable = '@{ AZKVaultName = ''''; SubscriptionId = ''{0}'' }'.Replace('{0}', $SubscriptionId)
        return $Hashtable
    }
    switch ($parameterName) {
        'ModuleName' { 
        
       
            $Output = [System.Collections.Generic.List[PSObject]]::new()
            $Items = (Get-ChildItem -Path $env:PSModulePath.Split(';') -DIrectory).FullName

            Foreach ($i in $Items) {
                $Leaf = Split-Path $i -Leaf
                $Versions = Get-ChildItem -Path "$i/*" -Directory
                
                if ($Versions.count -gt 0 ) {
                    $ExtensionPath = (Join-Path -Path $Versions[-1].FullName -ChildPath "$Leaf.Extension")    
                    if (Test-Path -Path $ExtensionPath ) {
                        $Leaf
                    }
                }

            }

        }
        'VaultParameters' {
            if ($fakeBoundParameter.ContainsKey('ModuleName') -and $fakeBoundParameter.Item('ModuleName') -eq 'Az.Keyvault') {
                return [System.Management.Automation.CompletionResult]::new(($GetVaultParamStatement.Invoke())) 
            }
            
        }
    }
}