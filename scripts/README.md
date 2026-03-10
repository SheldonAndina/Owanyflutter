# I18n Batch Conversion Scripts - Quick Start Guide

## Overview

This directory contains PowerShell scripts to automate the bilingual (Portuguese/English) conversion of the Owany App across all screens.

## Scripts

### 1. **master_i18n_batch.ps1** (Main Controller)
Orchestrates the entire conversion process with reporting.

**Usage:**
```powershell
# Preview all changes (dry-run)
.\scripts\master_i18n_batch.ps1 -DryRun $true -AnalyzeOnly $true

# Run actual conversion
.\scripts\master_i18n_batch.ps1 -DryRun $false -Backup $true
```

**Options:**
- `-DryRun $true` - Preview changes without modifying files (default)
- `-DryRun $false` - Apply changes to actual files
- `-Backup $true` - Create `.bak` backups before modifying (default)
- `-AnalyzeOnly $true` - Only analyze, don't convert
- `-ReportDir "path"` - Where to save analysis reports

**Output:**
- Reports saved to `./i18n_reports/`
- Conversion logs for each screen category

---

### 2. **smart_i18n_converter.ps1** (Intelligent Converter)
Handles individual screen folder conversion with automatic import management.

**Features:**
- Automatically adds `import '../../i18n/idioma.dart';` if missing
- Applies 50+ common Portuguese→i18n replacements
- Creates backups before modifications
- Detailed logging

**Usage:**
```powershell
# Convert utility screens (dry-run)
.\scripts\smart_i18n_converter.ps1 `
  -ScreensPath "lib/screens/utility" `
  -DryRun $true `
  -Backup $true

# Actually apply conversions
.\scripts\smart_i18n_converter.ps1 `
  -ScreensPath "lib/screens/utility" `
  -DryRun $false
```

---

### 3. **batch_i18n_converter.ps1** (Basic Pattern Replacer)
Simple pattern-based converter for straightforward replacements.

**Usage:**
```powershell
.\scripts\batch_i18n_converter.ps1 `
  -Path "lib/screens/maintenance" `
  -Preview $true
```

---

### 4. **analyze_i18n_strings.ps1** (String Analyzer)
Scans all Dart files and identifies Portuguese strings that need conversion.

**Usage:**
```powershell
# Analyze utility screens
.\scripts\analyze_i18n_strings.ps1 `
  -Path "lib/screens/utility" `
  -OutputFile "analysis_utility.txt"

# Analyze all screens
.\scripts\analyze_i18n_strings.ps1 `
  -Path "lib/screens" `
  -OutputFile "all_strings.txt"
```

**Output:**
- Text file with summary of Portuguese strings by file
- Unique string list with frequency counts
- Helps identify which keys need to be added to `idioma.dart`

---

## Typical Workflow

### Step 1: Analyze (No Risk)
```powershell
# Run analysis on all screens
.\scripts\master_i18n_batch.ps1 -AnalyzeOnly $true

# Review reports in i18n_reports/
# Identify any patterns that need additional i18n keys
```

### Step 2: Dry-Run (Simulate)
```powershell
# Simulate conversion without actual changes
.\scripts\master_i18n_batch.ps1 -DryRun $true

# Review logs and verify the replacements look correct
```

### Step 3: Convert (Apply Changes)
```powershell
# Apply actual conversions with backups
.\scripts\master_i18n_batch.ps1 -DryRun $false -Backup $true

# Verify no compilation errors
flutter analyze

# Test the app
flutter run -d windows
```

### Step 4: Test & Validate
```powershell
# 1. Test language switching (Settings → Language)
# 2. Check all screens load without errors
# 3. Verify Portuguese and English display correctly
# 4. Check for any hardcoded strings still remaining
```

---

## Adding Custom Replacements

Edit the `$commonReplacements` hashtable in `smart_i18n_converter.ps1`:

```powershell
$commonReplacements = @{
    'Your Portuguese String' = 'I18n.t.text(''your_key_name'''
    # Add more patterns...
}
```

Key format: Always use the exact string that appears in the code:
- `'label: ''Text'''` for label assignments
- `'Text(''String'''` for Text widget content
- `'snackBar(''Message'''` for snackbar content

---

## Supported Replacements

The scripts currently handle:

**Categories:**
- ✅ Profile screen strings
- ✅ Settings screen strings
- ✅ Notification strings
- ✅ Apartment/maintenance strings
- ✅ Action buttons (Save, Delete, Edit, etc.)
- ✅ Status messages (success/error)
- ✅ Common labels

**What Still Needs Manual Work:**
- ⚠️ Complex nested strings in builders
- ⚠️ Dynamic strings with variables
- ⚠️ Form validation error messages
- ⚠️ Strings in comments

---

## Troubleshooting

### "Command not found" error
Ensure PowerShell execution policy allows scripts:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Script fails to find files
Verify paths are relative to project root:
```powershell
# From project root, not scripts/ folder
cd C:\Users\c0644449\Documents\Projetos\owany_app
.\scripts\master_i18n_batch.ps1
```

### Too many replacements, app breaks
Use dry-run mode first:
```powershell
.\scripts\master_i18n_batch.ps1 -DryRun $true
# Review output carefully before running with -DryRun $false
```

### Need to rollback?
All `.bak` files contain original content:
```powershell
# Restore from backup
$file = "lib/screens/utility/profile_screen.dart"
Copy-Item "$file.bak" $file -Force
```

---

## Key Points

1. **Always backup** - Automatic `.bak` creation is recommended
2. **Test dry-run first** - Preview changes before applying
3. **Check i18n keys exist** - If a replacement uses a key, ensure it's in `lib/i18n/idioma.dart`
4. **Run `flutter analyze` after** - Verify no compilation errors
5. **Manual review** - Some complex patterns may need manual fixing

---

## Script Status

| Script | Status | Recommended Use |
|--------|--------|-----------------|
| master_i18n_batch.ps1 | ✅ Ready | Main entry point - run this first |
| smart_i18n_converter.ps1 | ✅ Ready | Individual category conversion |
| batch_i18n_converter.ps1 | ✅ Ready | Simple pattern replacement |
| analyze_i18n_strings.ps1 | ✅ Ready | Pre-conversion analysis |

---

## Questions?

See `lib/i18n/idioma.dart` for all available i18n keys.

See `COPILOT_INSTRUCTIONS.md` for app architecture details.
