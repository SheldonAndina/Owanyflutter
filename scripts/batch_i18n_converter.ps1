# Batch I18n Converter for Owany App
# Purpose: Automatically convert Portuguese strings to i18n keys across multiple Dart files
# Usage: .\batch_i18n_converter.ps1 -Path "lib/screens/utility" -Preview

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [switch]$Preview = $false,
    [switch]$Backup = $true,
    [string]$BackupSuffix = ".bak"
)

# Color output
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[✓] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[⚠] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[✗] $args" -ForegroundColor Red }

Write-Info "Starting I18n Batch Converter"
Write-Info "Target path: $Path"
Write-Info "Preview mode: $Preview"

# Common i18n replacements dictionary
$replacements = @{
    # Actions
    "'Salvar'" = "'action_save'"
    "'Excluir'" = "'action_delete'"
    "'Editar'" = "'action_edit'"
    "'Criar'" = "'action_create'"
    "'Voltar'" = "'action_back'"
    "'Sim'" = "'action_yes'"
    "'Não'" = "'action_no'"
    
    # Generic
    '"Salvar"' = 'I18n.t.text(''action_save'')'
    '"Excluir"' = 'I18n.t.text(''action_delete'')'
    '"Editar"' = 'I18n.t.text(''action_edit'')'
    '"Criar"' = 'I18n.t.text(''action_create'')'
    '"Voltar"' = 'I18n.t.text(''action_back'')'
    
    # Common UI
    '"Meu Perfil"' = 'I18n.t.text(''profile_title'')'
    '"Editar Perfil"' = 'I18n.t.text(''profile_edit'')'
    '"Configurações"' = 'I18n.t.text(''settings_title'')'
    '"Notificações"' = 'I18n.t.text(''notifications_title'')'
    '"Nenhuma notificação"' = 'I18n.t.text(''notifications_empty'')'
    '"Relatórios"' = 'I18n.t.text(''reports_title'')'
    
    # Status messages
    '"Salvo com sucesso"' = 'I18n.t.text(''success_saved'')'
    '"Excluído com sucesso"' = 'I18n.t.text(''success_deleted'')'
    '"Ocorreu um erro"' = 'I18n.t.text(''error_generic'')'
    '"Erro de conexão"' = 'I18n.t.text(''error_connection'')'
    
    # Common labels
    '"Nome"' = 'I18n.t.text(''profile_name'')'
    '"Email"' = 'I18n.t.text(''profile_email'')'
    '"Telefone"' = 'I18n.t.text(''register_phone'')'
    '"Senha"' = 'I18n.t.text(''register_password'')'
    '"Descrição"' = 'I18n.t.text(''maintenance_detail_description'')'
    '"Status"' = 'I18n.t.text(''maintenance_detail_status'')'
}

# Get all Dart files
$dartFiles = Get-ChildItem -Path $Path -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue

if ($dartFiles.Count -eq 0) {
    Write-Warning "No Dart files found in $Path"
    exit 1
}

Write-Info "Found $($dartFiles.Count) Dart files"

$filesModified = 0
$replacementsCount = 0

foreach ($file in $dartFiles) {
    Write-Info "Processing: $($file.Name)"
    
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    $fileModified = $false
    
    # Check if i18n import exists
    if ($content -notmatch "import.*i18n/idioma") {
        Write-Warning "$($file.Name) missing i18n import - would need manual import addition"
    }
    
    # Apply replacements
    foreach ($pattern in $replacements.Keys) {
        $replacement = $replacements[$pattern]
        
        if ($content -match [regex]::Escape($pattern)) {
            $matches = [regex]::Matches($content, [regex]::Escape($pattern))
            Write-Info "  Found $($matches.Count) match(es) for: $pattern"
            
            if (-not $Preview) {
                $content = $content -replace [regex]::Escape($pattern), $replacement
                $replacementsCount += $matches.Count
                $fileModified = $true
            }
        }
    }
    
    # Write back if changed
    if ($fileModified -and -not $Preview) {
        # Create backup if requested
        if ($Backup) {
            $backupPath = $file.FullName + $BackupSuffix
            Copy-Item -Path $file.FullName -Destination $backupPath -Force
            Write-Success "Backup created: $($file.Name)$BackupSuffix"
        }
        
        # Write updated content
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Success "Updated: $($file.Name)"
        $filesModified++
    }
}

Write-Info ""
Write-Info "========== SUMMARY =========="
Write-Success "Files processed: $($dartFiles.Count)"
Write-Success "Files modified: $filesModified"
Write-Success "Total replacements: $replacementsCount"

if ($Preview) {
    Write-Warning "This was a PREVIEW. No changes were made."
    Write-Info "Run without -Preview flag to apply changes."
}

Write-Info "Conversion complete!"
