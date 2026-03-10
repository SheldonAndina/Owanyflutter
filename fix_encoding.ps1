$basePath = "c:\Users\c0644449\Documents\Projetos\owany_app"

# Get all affected files
$allFiles = Get-ChildItem -Path "$basePath\lib" -Recurse -Filter "*.dart" | 
    Select-String -Pattern "Ã¡|Ã£|Ã§|Ãµ|Ã©|Ã­|Ã³|Ãº" | 
    ForEach-Object { $_.Path } | 
    Sort-Object -Unique

Write-Host "Found $($allFiles.Count) files with encoding issues"

# Fix each file
$fixedCount = 0
foreach ($fullPath in $allFiles) {
    $content = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
    $original = $content
    
    # Apply all replacements for mojibake
    $content = $content -replace 'Ã¡', 'á'
    $content = $content -replace 'Ã£', 'ã'
    $content = $content -replace 'Ã§', 'ç'
    $content = $content -replace 'Ãµ', 'õ'
    $content = $content -replace 'Ã©', 'é'
    $content = $content -replace 'Ã­', 'í'
    $content = $content -replace 'Ã³', 'ó'
    $content = $content -replace 'Ãº', 'ú'
    $content = $content -replace 'Ã ', 'à'
    $content = $content -replace 'Ã¢', 'â'
    $content = $content -replace 'Ãª', 'ê'
    $content = $content -replace 'Ã´', 'ô'
    $content = $content -replace 'Ã¼', 'ü'
    $content = $content -replace 'ÃŠ', 'Ê'
    $content = $content -replace 'Ã"', 'Ó'
    $content = $content -replace 'Ãš', 'Ú'
    $content = $content -replace 'Ã‡', 'Ç'
    $content = $content -replace 'Ãƒ', 'Ã'
    $content = $content -replace 'Ã•', 'Õ'
    
    # Fix emoji mojibake
    $content = $content -replace 'ðŸ"µ', '🔵'
    $content = $content -replace 'ðŸ''', '👋'
    $content = $content -replace 'âœ…', '✅'
    $content = $content -replace 'âŒ', '❌'
    
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($fullPath, $content, (New-Object System.Text.UTF8Encoding $false))
        $fixedCount++
        $fileName = Split-Path $fullPath -Leaf
        Write-Host "Fixed: $fileName"
    }
}
Write-Host "`nTotal files fixed: $fixedCount"
