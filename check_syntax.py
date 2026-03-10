#!/usr/bin/env python
# -*- coding: utf-8 -*-

import ast

files = [
    r'c:\Users\c0644449\Documents\Projetos\owany_app\lib\providers\agendamentos_provider.dart',
    r'c:\Users\c0644449\Documents\Projetos\owany_app\lib\screens\agendamentos\criar_agendamento_screen.dart',
    r'c:\Users\c0644449\Documents\Projetos\owany_app\lib\screens\agendamentos\criar_agendamento_manutencao_simples_screen.dart',
    r'c:\Users\c0644449\Documents\Projetos\owany_app\lib\models\dtos_complementares.dart',
    r'c:\Users\c0644449\Documents\Projetos\owany_app\lib\screens\maintenance\manutencao_preventiva_form_screen.dart',
]

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Basic Dart syntax check - check for balanced braces
        open_braces = content.count('{')
        close_braces = content.count('}')
        open_parens = content.count('(')
        close_parens = content.count(')')
        open_brackets = content.count('[')
        close_brackets = content.count(']')
        
        issues = []
        if open_braces != close_braces:
            issues.append(f"Brace mismatch: {{ {open_braces} vs}} {close_braces}")
        if open_parens != close_parens:
            issues.append(f"Paren mismatch: ( {open_parens} vs) {close_parens}")
        if open_brackets != close_brackets:
            issues.append(f"Bracket mismatch: [ {open_brackets} vs] {close_brackets}")
        
        if issues:
            print(f"❌ {file_path}")
            for issue in issues:
                print(f"   {issue}")
        else:
            print(f"✅ {file_path} - syntax OK")

print("\nBasic syntax check complete!")
