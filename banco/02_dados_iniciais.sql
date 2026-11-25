-- MoveTech - primeiro usuario administrador e dados de exemplo
--
-- Execute DEPOIS do 01_criar_banco.sql.
--
-- A API so cria usuarios para quem ja esta logado, entao o primeiro
-- precisa ser inserido direto no banco.
--
--   E-mail: admin@movetech.com
--   Senha:  Admin@123
--
-- O campo SenhaHash e o BCrypt da senha acima (a API confere com
-- BCrypt.Net). Troque a senha depois, criando outro usuario pela API.

USE smartmoveis;

INSERT INTO usuarios (Nome, Email, SenhaHash, Perfil, Ativo, CriadoEm)
SELECT 'Administrador', 'admin@movetech.com',
       '$2b$11$ow4vyoezeH7P05YDf.3ZDePQOy6Q1kSn5AEgfv48/GRd0nCwY181G',
       'Administrador', 1, UTC_TIMESTAMP()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE Email = 'admin@movetech.com');

-- Dados de exemplo para testar o app (opcional)
INSERT INTO Clientes (Nome, CPF, Telefone, Email, Endereco, Ativo, CriadoEm)
SELECT 'Ana Souza', '529.982.247-25', '(11) 98765-4321', 'ana@exemplo.com',
       'Rua das Flores, 100', 1, UTC_TIMESTAMP()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM Clientes WHERE CPF = '529.982.247-25');

INSERT INTO Produtos (Nome, Descricao, Categoria, Preco, QuantidadeEstoque, EstoqueMinimo, Ativo, CriadoEm)
SELECT 'Sofa 3 lugares', 'Sofa retratil em tecido suede', 'Sala', 2499.90, 8, 2, 1, UTC_TIMESTAMP()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM Produtos WHERE Nome = 'Sofa 3 lugares');

INSERT INTO Produtos (Nome, Descricao, Categoria, Preco, QuantidadeEstoque, EstoqueMinimo, Ativo, CriadoEm)
SELECT 'Mesa de jantar 6 cadeiras', 'Tampo de vidro, estrutura em madeira', 'Cozinha', 1899.00, 2, 3, 1, UTC_TIMESTAMP()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM Produtos WHERE Nome = 'Mesa de jantar 6 cadeiras');
