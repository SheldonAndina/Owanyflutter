-- Script para resetar senha de usuário no banco de dados
-- Nova senha será: Admin@123
-- Hash BCrypt gerado: $2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGjad68LJZdL17lhWy

-- Resetar senha do usuário Sheldon Andina
UPDATE Usuarios
SET SenhaHash = '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGjad68LJZdL17lhWy',
    AtualizadoEm = GETDATE()
WHERE NomeLogin = 'SAndina';

-- Verificar atualização
SELECT Id, Nome, NomeLogin, Telefone, Tipo, Ativo
FROM Usuarios
WHERE NomeLogin = 'SAndina';

-- ================================================
-- INSTRUÇÕES:
-- 1. Execute este script no SQL Server Management Studio
-- 2. Conecte-se ao banco de dados do Owany
-- 3. Após executar, faça login com:
--    NomeLogin: SAndina
--    Senha: Admin@123
-- ================================================

-- Para resetar TODOS os usuários para a mesma senha (Admin@123):
/*
UPDATE Usuarios
SET SenhaHash = '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGjad68LJZdL17lhWy',
    AtualizadoEm = GETDATE()
WHERE Ativo = 1;
*/
