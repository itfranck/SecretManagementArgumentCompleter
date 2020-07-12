# SecretManagementArgumentCompleter
 Argument completer for SecretManagement module

This module provide argument completers for the **Microsoft.Powershell.SecretManagement** module and partially for **AzKeyvault** (only on secret related cmdlet).

## Installation
```Powershell
# Require Microsoft.Powershell.SecretManagement to be installed.
Install-Module -Name SecretManagementArgumentCompleter 
```

## Loading the module
Recommended use is to add this module to your `$Profile` file so it loads on a new session automatically).

To load, use

`Import-SecretManagementArgumentCompleter`

**Optional parameter**
`[Switch] -InMemory`

If Specified, Secret cache will never be stored on disk. 

If omitted, secret cache will be saved at the following location:
`"$env:LOCALAPPDATA\Powershell\SecretManagement"`

In both case, initial argument completion for vault names and secrets name is collected upon the first time argument completion is triggered.

`In-memory` means the initial collection will be done each session when triggered for the first time. 

Cached on disk means the informations is saved / reloaded between sessions. 


In any cases, you can delete existing cache (if you need to refresh the values) by calling `Clear-SecretManagementArgumentCompleterCache`




### Profile information
You can find your profile location by checking the `$Profile`  variable

VSCode shorthand 

```Powershell
if (! (Test-Path($profile)) {New-Item -Path $profile -ItemType File}
$psEditor.Workspace.OpenFile($profile)
```

Just add `Import-SecretManagementArgumentCompleter` to it so you get argument completion configured on profile load.


### AZ Keyvault

Here's an example of how to register an az keyvault.
This is nothing specific to the argument completer and is just here as reference.

(This is also the reason that pushed me to implement secret info caching, as retrieving the informations of the az keyvaults can take a 2-3 seconds, which is not so bad yet unpractical for argument completion purposes)


```Powershell
$VaultParams = @{
    Name            = 'ProdAzael-Azkeyvault' 
    ModuleName      = 'Az.KeyVault' 
    VaultParameters = @{ AZKVaultName = 'Prod-Azael-key01'; SubscriptionId = 'e7739e0b-1a01-4361-8fe4-087e14463a4c' }
}

$Vault = @{Vault = $VaultParams.Name }


if ((Get-SecretVault -Name $VaultParams.Name) -eq $null) {
    Register-SecretVault @VaultParams 
}


#Set-Secret @vault -Name 'MySecret' -Secret 'SomethingSecret'
```


