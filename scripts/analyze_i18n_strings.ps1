#!/usr/bin/env pwsh
# I18n String Analyzer for Owany App
# Purpose: Find and report all Portuguese strings that need i18n conversion
# Usage: .\analyze_i18n_strings.ps1 -Path "lib/screens" -OutputFile "strings_to_convert.txt"

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [string]$OutputFile = "strings_to_convert.txt",
    [string]$MinLength = 3
)

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[✓] $args" -ForegroundColor Green }

Write-Info "Analyzing Portuguese strings in $Path..."

$stringPattern = '"([^"]{' + $MinLength + ',})"'
$allStrings = @{}
$fileSummary = @()

$dartFiles = Get-ChildItem -Path $Path -Filter "*.dart" -Recurse

foreach ($file in $dartFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $matches = [regex]::Matches($content, $stringPattern)
    
    $portuegueseStrings = @()
    
    foreach ($match in $matches) {
        $str = $match.Groups[1].Value
        
        # Basic heuristic: check if string contains Portuguese words
        if ($str -match '[àáâãäåèéêëìíîïòóôõöùúûüçñ]' -or 
            $str -match '\b(o|a|de|do|da|um|uma|é|são|está|estão|para|por|com|sem|em|na|no|nas|nos|que|qual|quais|como|quando|onde|porquê|porque|se|não|sim|já|ainda|muito|pouco|mais|menos|bem|mal|melhor|pior|novo|velho|bom|mau|grande|pequeno|certo|errado|verdadeiro|falso|ativo|inativo|criar|editar|salvar|excluir|atualizar|carregar|enviar|receber|abrir|fechar|voltar|avançar|anterior|próximo|primeira|última|primeira|segunda|terceira|quarta|quinta|sexta|sétima|oitava|nona|décima)\b' -and
            $str -notmatch '(http|https|email|url|id|uuid|token|key|value|debug|temp|tmp)') {
            
            $portuegueseStrings += $str
            
            if (-not $allStrings.ContainsKey($str)) {
                $allStrings[$str] = 0
            }
            $allStrings[$str]++
        }
    }
    
    if ($portuegueseStrings.Count -gt 0) {
        $fileSummary += [PSCustomObject]@{
            File = $file.FullName.Replace((Get-Location).Path + '\', '')
            Count = $portuegueseStrings.Count
            Strings = $portuegueseStrings
        }
    }
}

# Output report
$report = @()
$report += "═" * 80
$report += "I18N STRING ANALYSIS REPORT"
$report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "═" * 80
$report += ""

# Summary by file
$report += "SUMMARY BY FILE:"
$report += "-" * 80
foreach ($item in $fileSummary | Sort-Object -Property Count -Descending) {
    $report += "$($item.File): $($item.Count) strings"
}
$report += ""

# Unique strings with frequency
$report += "UNIQUE STRINGS (with frequency):"
$report += "-" * 80
$sorted = $allStrings.GetEnumerator() | Sort-Object -Property Value -Descending
foreach ($item in $sorted | Select-Object -First 50) {
    $report += "  [$($item.Value)x] `"$($item.Name)`""
}
$report += ""
$report += "Total unique strings: $($allStrings.Count)"
$report += "═" * 80

# Write to file
$report | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Success "Report saved to: $OutputFile"
Write-Success "Total unique Portuguese strings: $($allStrings.Count)"

# Also show summary
$report[0..20] | ForEach-Object { Write-Host $_ }
