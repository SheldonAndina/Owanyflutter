# Script para criar usuário de teste via API

$baseUrl = "https://localhost:7068/api"

# Dados do novo usuário
$usuario = @{
    nome = "Teste Admin"
    nomeLogin = "admin"
    telefone = "258840000000"
    senha = "Admin@123"
    tipo = 0  # 0 = Administrador
} | ConvertTo-Json

Write-Host "Criando usuário de teste..." -ForegroundColor Yellow
Write-Host "NomeLogin: admin" -ForegroundColor Cyan
Write-Host "Senha: Admin@123" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/registrar" `
        -Method Post `
        -ContentType "application/json" `
        -Body $usuario `
        -SkipCertificateCheck

    Write-Host "`n✅ Usuário criado com sucesso!" -ForegroundColor Green
    Write-Host "`nAgora faça login com:" -ForegroundColor White
    Write-Host "  NomeLogin: admin" -ForegroundColor Green
    Write-Host "  Senha: Admin@123" -ForegroundColor Green
}
catch {
    Write-Host "`n❌ Erro ao criar usuário:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "`nDetalhes: $responseBody" -ForegroundColor Yellow
    }
}
