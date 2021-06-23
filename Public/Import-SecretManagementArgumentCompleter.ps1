function Import-SecretManagementArgumentCompleter {
    [cmdletBinding()]
    Param([Switch]$InMemory, [switch]$Force)
    $Script:InMemory = $InMemory
    Import-Module -Name SecretManagementArgumentCompleter -ArgumentList $InMemory -Force:$Force
}