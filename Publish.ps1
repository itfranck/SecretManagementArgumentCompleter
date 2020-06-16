Import-Module -Name 'C:\Users\Mercier\Documents\PowerShell\Modules\SecretManagementAgrumentCompleter\1.0.0\SecretManagementArgumentCompleter.psd1' -force
Import-Module -Name Microsoft.Powershell.SecretManagement

Get-SecretInfo 

     
Import-Module Microsoft.PowerShell.SecretManagement
Publish-Module -Name SecretManagementArgumentCompleter  -NuGetApiKey (Get-Secret -Vault BuiltInLocalVault -Name NugetKey -AsPlainText) -Repository PSGallery -Verbose 

Import-Module -Name 'C:\Program Files\WindowsPowerShell\Modules\SecretManagementArgumentCompleter\1.0.1'
get-module SecretManagementArgumentCompleter
Get-SecretInfo -Cache
Import-Module SecretManagementArgumentCompleter
Install-Module -Name NuGet

get-module PowerShellGet
Install-Module -Name KeybaseSecretManagementExtension

get-module PackageManagement
