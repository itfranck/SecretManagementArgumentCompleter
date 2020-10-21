Param(
    [parameter(Mandatory = $false)]
    [Switch]$InMemory
)
$Script:InMemory = $InMemory



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

#region AZKeyvault



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
#endregion
Register-ArgumentCompleter -ParameterName Name -ScriptBlock $AZKVSecretNameArgumentCompletion -CommandName  Backup-AzKeyVaultSecret, Get-AzKeyVaultSecret, Remove-AzKeyVaultSecret, Set-AzKeyVaultSecret , Update-AzKeyVaultSecret 
Register-ArgumentCompleter -ParameterName VaultName -ScriptBlock $AZKVVaultNameArgumentCompletion -CommandName  Backup-AzKeyVaultSecret, Get-AzKeyVault, Get-AzKeyVaultSecret, Remove-AzKeyVault, Remove-AzKeyVaultSecret, Restore-AzKeyVaultSecret, Set-AzKeyVaultSecret, Update-AzKeyVaultSecret 


#region SecretManagement

$SecretVaultNameArgCompletion = {
    Get-SecretVault  | Select -ExpandProperty Name | foreach-object {
        [System.Management.Automation.CompletionResult]::new($_)
    }
}

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
    

Register-ArgumentCompleter -CommandName Register-SecretVault -ParameterName ModuleName -ScriptBlock $RegisterSecretVaultArgCompletion
Register-ArgumentCompleter -CommandName Register-SecretVault -ParameterName VaultParameters -ScriptBlock $RegisterSecretVaultArgCompletion

#endregion
Register-ArgumentCompleter -CommandName Get-Secret, Get-SecretInfo, Set-Secret, Test-SecretVault, Remove-Secret -ParameterName Vault -ScriptBlock $SecretVaultNameArgCompletion
Register-ArgumentCompleter -CommandName Unregister-SecretVault, Test-SecretVault, Get-SecretVault -ParameterName Name -ScriptBlock $SecretVaultNameArgCompletion
Register-ArgumentCompleter -CommandName Get-Secret, Get-SecretInfo, Remove-Secret, Set-Secret -ParameterName Name -ScriptBlock $SecretNameArgCompletion