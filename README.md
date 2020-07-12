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

To load, use: `Import-SecretManagementArgumentCompleter`


Cache will be saved on disk at: `"$env:LOCALAPPDATA\Powershell\SecretManagement"`
Only the following informations are cached
- SubscriptionID (AzKeyvault only)
- Vault Name
- Secret Name (Actual secret is never cached)

**Optional parameter**
`[Switch] -InMemory`

Add the `In-Memory` switch to never create a file based secret cache. 


In all cases, secret cache is built in-memory. The initial call to obtain secret info is a bit longer since the provider is contacted to obtain the information. 

`In-Memory` means the cache is per-session so each time a new session is restarted, you do have the initial fetch to the provider when doing argument completion. 

Default is to save that information on disk and reload it in-memory when session is loaded.


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


