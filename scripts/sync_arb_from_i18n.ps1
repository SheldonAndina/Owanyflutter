# Sync ARB files from legacy I18n map (lib/i18n/idioma.dart)
# Generates: lib/l10n/app_pt.arb and lib/l10n/app_en.arb
# Created: February 9, 2026

param(
    [string]$SourcePath = "lib/i18n/idioma.dart",
    [string]$OutputPt = "lib/l10n/app_pt.arb",
    [string]$OutputEn = "lib/l10n/app_en.arb"
)

if (-not (Test-Path $SourcePath)) {
    Write-Host "ERRO: Arquivo fonte nao encontrado: $SourcePath" -ForegroundColor Red
    exit 1
}

$content = Get-Content -Path $SourcePath -Raw

# Match pattern: 'key': { Idioma.pt: 'PT', Idioma.en: 'EN', }
$pattern = "'(?<key>[^']+)'\s*:\s*\{\s*Idioma\.pt:\s*'(?<pt>[^']*)'\s*,\s*Idioma\.en:\s*'(?<en>[^']*)'"
$regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$matches = $regex.Matches($content)

if ($matches.Count -eq 0) {
    Write-Host "ERRO: Nenhuma chave encontrada no arquivo fonte." -ForegroundColor Red
    exit 1
}

$pt = [ordered]@{ "@@locale" = "pt" }
$en = [ordered]@{ "@@locale" = "en" }

foreach ($m in $matches) {
    $key = $m.Groups['key'].Value.Trim()
    $ptValue = $m.Groups['pt'].Value
    $enValue = $m.Groups['en'].Value

    if (-not [string]::IsNullOrWhiteSpace($key)) {
        $pt[$key] = $ptValue
        $en[$key] = $enValue
    }
}

$ptJson = $pt | ConvertTo-Json -Depth 5
$enJson = $en | ConvertTo-Json -Depth 5

Set-Content -Path $OutputPt -Value $ptJson -Encoding UTF8
Set-Content -Path $OutputEn -Value $enJson -Encoding UTF8

Write-Host "Gerado: $OutputPt" -ForegroundColor Green
Write-Host "Gerado: $OutputEn" -ForegroundColor Green
Write-Host "Total de chaves: $($pt.Keys.Count - 1)" -ForegroundColor Cyan
