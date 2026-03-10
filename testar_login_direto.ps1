# Script para testar login diretamente no backend
# Mostra exatamente o que está sendo enviado e recebido

$baseUrl = "https://localhost:7068/api"

# Teste 1: SAndina com senha S12345
Write-Host "`n========== TESTE 1: SAndina ==========" -ForegroundColor Cyan
$body1 = @{
    nomeLogin = "SAndina"
    senha = "S12345"
} | ConvertTo-Json

Write-Host "Enviando:" -ForegroundColor Yellow
Write-Host $body1 -ForegroundColor Gray

try {
    $response1 = Invoke-WebRequest -Uri "$baseUrl/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body1 `
        -SkipCertificateCheck `
        -ErrorAction Stop

    Write-Host "`n✅ Status: $($response1.StatusCode)" -ForegroundColor Green
    Write-Host "Resposta:" -ForegroundColor Green
    $response1.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
}
catch {
    Write-Host "`n❌ ERRO Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Resposta do Backend:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor Gray
    }
}

# Teste 2: AAlbino 
Write-Host "`n========== TESTE 2: AAlbino ==========" -ForegroundColor Cyan
Write-Host "Digite a senha para AAlbino:" -ForegroundColor Yellow
$senhaAAlbino = Read-Host -AsSecureString
$senhaTexto = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($senhaAAlbino)
)

$body2 = @{
    nomeLogin = "AAlbino"
    senha = $senhaTexto
} | ConvertTo-Json

Write-Host "Enviando:" -ForegroundColor Yellow
Write-Host $body2 -ForegroundColor Gray

try {
    $response2 = Invoke-WebRequest -Uri "$baseUrl/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body2 `
        -SkipCertificateCheck `
        -ErrorAction Stop

    Write-Host "`n✅ Status: $($response2.StatusCode)" -ForegroundColor Green
    Write-Host "Resposta:" -ForegroundColor Green
    $response2.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
}
catch {
    Write-Host "`n❌ ERRO Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Resposta do Backend:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testes concluídos. Verifique os resultados acima." -ForegroundColor White
