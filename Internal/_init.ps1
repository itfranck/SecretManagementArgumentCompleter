Param(
    [parameter(Mandatory = $false)]
    [Switch]$InMemory
)
$Script:InMemory = $InMemory


$Script:_SecretMgmtCompletion = [System.Collections.Generic.Dictionary[String, String[]]]::new()
$Script:_AZkvCompletion = [System.Collections.Generic.Dictionary[String, psobject[]]]::new()
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