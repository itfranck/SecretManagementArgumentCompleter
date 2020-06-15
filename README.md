# SecretManagementArgumentCompleter
 Argument completer for SecretManagement module

This module provide argument completers for the **Microsoft.Powershell.SecretManagement** module. 

## Installation
```
# Require Microsoft.Powershell.SecretManagement to be installed.
Install-Module -Name SecretManagementArgumentCompleter -AllowClobber
```

## How to use
Recommended use is to add this module to your `$Profile` file so it loads on a new session).

Cmdlet in the **SecretManagement** module will now have argument completion.

In order to provide a fast & efficient completion, this modules overrides `Get-SecretInfo` to add an additional `-Cache` parameter. This module is not required on any machines where your scripts / modules are intended to be deployed, unless you make use of the `-Cache` parameter (SecretManagement module do not support that parameter natively.)

Therefore, its use should be limited to console / local environment only to avoid the extra module dependency.



### About Get-SecretInfo overrides

The new `Get-SecretInfo` overrides does automatically export secret info (Name, Type,VaultName) to `"$env:USERPROFILE\Powershell\SecretsManagement\Vaults"` when called.

If called with the `-Cache` parameter, a local copy of the secret infos will be provided instead.

If there was no cache, the cache will be created at that time. 

This ensure that secret name completion is fast and do not need to connect to any external vaults while designing your code.

**Note that no secrets are ever stored on the local environment by the use of this module. Only infos (Name,Type,VaultName) are kept locally.**

To refresh the argument completion cache at anytime, just call `Get-SecretInfo` without the `-Cache` parameter. 



### Profile information
You can find your profile location by checking the `$Profile`  variable

VSCode shorthand 

```Powershell
$psEditor.Workspace.OpenFile($profile)
```
(Note that file will fail to open if it does not exist, in which case you'll have to create it manually.)

Just add `Import-Module -Name SecretManagementArgumentCompleter` to it so you get argument completion configured on profile load.