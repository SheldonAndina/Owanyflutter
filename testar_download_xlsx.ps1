# Teste de Download XLSX - PowerShell Script
# Propósito: Testar se o backend está retornando o arquivo Excel corretamente

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     TESTE DE DOWNLOAD XLSX - Owany App                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# PASSO 1: Obter token de login
# ============================================================================

Write-Host "📌 PASSO 1: Fazer login e obter token" -ForegroundColor Yellow
Write-Host ""

$baseUrl = "https://localhost:7068/api"
$username = "admin"  # ⚠️ TROCAR: seu usuário de teste
$password = "123456"  # ⚠️ TROCAR: sua senha

Write-Host "➤ Tentando login com: $username"
Write-Host ""

$loginPayload = @{
    identificador = $username
    senha         = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-WebRequest -Uri "$baseUrl/auth/login" `
                                       -Method POST `
                                       -ContentType "application/json" `
                                       -Body $loginPayload `
                                       -SkipCertificateCheck `
                                       -ErrorAction Stop

    Write-Host "✅ Login bem-sucedido!" -ForegroundColor Green
    Write-Host "Status: $($loginResponse.StatusCode)" -ForegroundColor Green

    # Parse resposta
    $loginData = $loginResponse.Content | ConvertFrom-Json
    
    if ($loginData.sucesso) {
        $token = $loginData.dados.token
        Write-Host "Token obtido: $($token.Substring(0, 20))..." -ForegroundColor Green
    } else {
        Write-Host "❌ Login retornou sucesso=false" -ForegroundColor Red
        Write-Host "Mensagem: $($loginData.mensagem)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Erro ao fazer login:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# PASSO 2: Testar Download de Excel
# ============================================================================

Write-Host "📌 PASSO 2: Requisitar download de Excel" -ForegroundColor Yellow
Write-Host ""

$downloadUrl = "$baseUrl/Exportacao/solicitacoes/excel"
$downloadPath = "C:\Downloads\test_solicitacoes_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"

Write-Host "➤ URL: $downloadUrl"
Write-Host "➤ Salvando em: $downloadPath"
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept"        = "*/*"
}

try {
    $downloadResponse = Invoke-WebRequest -Uri $downloadUrl `
                                         -Method GET `
                                         -Headers $headers `
                                         -SkipCertificateCheck `
                                         -OutFile $downloadPath `
                                         -ErrorAction Stop

    Write-Host "✅ Download bem-sucedido!" -ForegroundColor Green
    Write-Host "Status: $($downloadResponse.StatusCode)" -ForegroundColor Green
    
    # Verificar tamanho do arquivo
    if (Test-Path $downloadPath) {
        $fileSize = (Get-Item $downloadPath).Length
        Write-Host "Tamanho: $fileSize bytes" -ForegroundColor Green
        
        if ($fileSize -lt 100) {
            Write-Host "⚠️ AVISO: Arquivo muito pequeno! Pode estar vazio" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Arquivo parece válido!" -ForegroundColor Green
        }
    }

} catch {
    Write-Host "❌ Erro ao fazer download:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Informações adicionais:" -ForegroundColor Yellow
    
    # Extrair status se disponível
    if ($_.Exception.Response) {
        Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    }
    
    exit 1
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# PASSO 3: Testar Download de PDF
# ============================================================================

Write-Host "📌 PASSO 3: Requisitar download de PDF (opcional)" -ForegroundColor Yellow
Write-Host ""

$downloadUrlPdf = "$baseUrl/Exportacao/solicitacoes/pdf"
$downloadPathPdf = "C:\Downloads\test_solicitacoes_$(Get-Date -Format 'yyyyMMdd_HHmmss').pdf"

Write-Host "➤ URL: $downloadUrlPdf"
Write-Host "➤ Salvando em: $downloadPathPdf"
Write-Host ""

try {
    $downloadResponsePdf = Invoke-WebRequest -Uri $downloadUrlPdf `
                                            -Method GET `
                                            -Headers $headers `
                                            -SkipCertificateCheck `
                                            -OutFile $downloadPathPdf `
                                            -ErrorAction Stop

    Write-Host "✅ Download PDF bem-sucedido!" -ForegroundColor Green
    Write-Host "Status: $($downloadResponsePdf.StatusCode)" -ForegroundColor Green
    
    if (Test-Path $downloadPathPdf) {
        $fileSizePdf = (Get-Item $downloadPathPdf).Length
        Write-Host "Tamanho: $fileSizePdf bytes" -ForegroundColor Green
    }

} catch {
    Write-Host "⚠️ Aviso ao fazer download PDF:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# RESUMO
# ============================================================================

Write-Host "✅ TESTE COMPLETO!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Resumo:" -ForegroundColor Cyan
Write-Host "  • Login: ✅ Bem-sucedido"
Write-Host "  • Download Excel: ✅ Bem-sucedido"
Write-Host "  • Arquivo: $downloadPath"
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Abra o arquivo Excel no $downloadPath"
Write-Host "  2. Verifique se os dados estão corretos"
Write-Host "  3. Se tudo ok, o problema estava no frontend (CORRIGIDO)"
Write-Host ""
Write-Host "Se recebeu erro HTTP 401/403:" -ForegroundColor Yellow
Write-Host "  • Token expirado ou inválido"
Write-Host "  • Verifique credenciais ($username / $password)"
Write-Host ""
Write-Host "Se recebeu erro HTTP 500:" -ForegroundColor Yellow
Write-Host "  • Verifique logs do backend (Program.cs)"
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
