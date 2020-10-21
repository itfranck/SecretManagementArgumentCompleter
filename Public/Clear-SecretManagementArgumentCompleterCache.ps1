Function Clear-SecretManagementArgumentCompleterCache() {
    $Script:_SecretMgmtCompletion = [System.Collections.Generic.Dictionary[String, String[]]]::new()
    $Script:_AZkvCompletion = [System.Collections.Generic.Dictionary[String, psobject[]]]::new()
}