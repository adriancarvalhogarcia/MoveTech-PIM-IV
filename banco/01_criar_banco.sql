-- ==================================================================
-- MoveTech / Smart Moveis - criacao do banco de dados (MySQL 8)
--
-- Gera exatamente a mesma estrutura das migrations do PIM III
-- (backend/SmartMoveis.API/Migrations). Pode ser executado mais de
-- uma vez: nada e apagado e o que ja existe e mantido.
--
-- Como usar:
--   a) pelo script:   .\preparar_banco.ps1      (faz tudo sozinho)
--   b) no Workbench:  File > Open SQL Script > este arquivo > raio (Execute)
--
-- O aplicativo mobile NAO acessa o banco diretamente. Quem usa estas
-- tabelas e a API ASP.NET Core; a web e o mobile falam com a API.
-- ==================================================================

CREATE DATABASE IF NOT EXISTS smartmoveis
  CHARACTER SET utf8mb4;

USE smartmoveis;

-- ------------------------------------------------------------------
-- Usuarios do sistema (login da web e do mobile)
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    Id        INT          NOT NULL AUTO_INCREMENT,
    Nome      VARCHAR(100) NOT NULL,
    Email     VARCHAR(150) NOT NULL,
    SenhaHash VARCHAR(255) NOT NULL,   -- hash BCrypt, nunca a senha
    Perfil    VARCHAR(30)  NOT NULL,   -- Administrador | Vendedor
    Ativo     TINYINT(1)   NOT NULL,
    CriadoEm  DATETIME(6)  NOT NULL,
    CONSTRAINT PK_usuarios PRIMARY KEY (Id)
) CHARACTER SET = utf8mb4;

-- ------------------------------------------------------------------
-- Clientes
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Clientes (
    Id       INT          NOT NULL AUTO_INCREMENT,
    Nome     VARCHAR(120) NOT NULL,
    CPF      VARCHAR(14)  NOT NULL,    -- 000.000.000-00
    Telefone VARCHAR(20)  NULL,
    Email    VARCHAR(150) NULL,
    Endereco VARCHAR(250) NULL,
    Ativo    TINYINT(1)   NOT NULL,
    CriadoEm DATETIME(6)  NOT NULL,
    CONSTRAINT PK_Clientes PRIMARY KEY (Id)
) CHARACTER SET = utf8mb4;

-- ------------------------------------------------------------------
-- Produtos
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Produtos (
    Id                INT            NOT NULL AUTO_INCREMENT,
    Nome              VARCHAR(120)   NOT NULL,
    Descricao         VARCHAR(500)   NULL,
    Categoria         VARCHAR(100)   NOT NULL,
    Preco             DECIMAL(10,2)  NOT NULL,
    QuantidadeEstoque INT            NOT NULL,
    EstoqueMinimo     INT            NOT NULL,
    Ativo             TINYINT(1)     NOT NULL,
    CriadoEm          DATETIME(6)    NOT NULL,
    CONSTRAINT PK_Produtos PRIMARY KEY (Id)
) CHARACTER SET = utf8mb4;

-- ------------------------------------------------------------------
-- Vendas (cabecalho)
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Vendas (
    Id         INT           NOT NULL AUTO_INCREMENT,
    ClienteId  INT           NOT NULL,
    ValorTotal DECIMAL(10,2) NOT NULL,
    CriadoEm   DATETIME(6)   NOT NULL,
    CONSTRAINT PK_Vendas PRIMARY KEY (Id),
    CONSTRAINT FK_Vendas_Clientes_ClienteId
        FOREIGN KEY (ClienteId) REFERENCES Clientes (Id) ON DELETE RESTRICT,
    INDEX IX_Vendas_ClienteId (ClienteId)
) CHARACTER SET = utf8mb4;

-- ------------------------------------------------------------------
-- Itens de cada venda
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ItensVenda (
    Id            INT           NOT NULL AUTO_INCREMENT,
    VendaId       INT           NOT NULL,
    ProdutoId     INT           NOT NULL,
    Quantidade    INT           NOT NULL,
    PrecoUnitario DECIMAL(10,2) NOT NULL,
    Subtotal      DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_ItensVenda PRIMARY KEY (Id),
    CONSTRAINT FK_ItensVenda_Produtos_ProdutoId
        FOREIGN KEY (ProdutoId) REFERENCES Produtos (Id) ON DELETE RESTRICT,
    CONSTRAINT FK_ItensVenda_Vendas_VendaId
        FOREIGN KEY (VendaId) REFERENCES Vendas (Id) ON DELETE CASCADE,
    INDEX IX_ItensVenda_ProdutoId (ProdutoId),
    INDEX IX_ItensVenda_VendaId (VendaId)
) CHARACTER SET = utf8mb4;

-- ------------------------------------------------------------------
-- PIM IV - indices unicos (CPF do cliente e e-mail do usuario)
--
-- Feito com checagem no information_schema para poder rodar o script
-- de novo sem erro, tanto em banco novo quanto em banco do PIM III.
-- Corresponde a migration 20261019120000_AdicionarIndicesUnicos.
-- ------------------------------------------------------------------
SET @existe := (SELECT COUNT(*) FROM information_schema.statistics
                WHERE table_schema = DATABASE() AND table_name = 'Clientes'
                  AND index_name = 'IX_Clientes_CPF');
SET @comando := IF(@existe = 0,
    'CREATE UNIQUE INDEX IX_Clientes_CPF ON Clientes (CPF)', 'SELECT 1');
PREPARE passo FROM @comando; EXECUTE passo; DEALLOCATE PREPARE passo;

SET @existe := (SELECT COUNT(*) FROM information_schema.statistics
                WHERE table_schema = DATABASE() AND table_name = 'usuarios'
                  AND index_name = 'IX_usuarios_Email');
SET @comando := IF(@existe = 0,
    'CREATE UNIQUE INDEX IX_usuarios_Email ON usuarios (Email)', 'SELECT 1');
PREPARE passo FROM @comando; EXECUTE passo; DEALLOCATE PREPARE passo;

-- ------------------------------------------------------------------
-- Historico de migrations do Entity Framework
--
-- Registra que as migrations do PIM III e do PIM IV ja estao aplicadas. Assim,
-- se alguem rodar "dotnet ef database update" depois, o EF nao tenta
-- criar de novo as tabelas que este script ja criou.
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS __EFMigrationsHistory (
    MigrationId    VARCHAR(150) NOT NULL,
    ProductVersion VARCHAR(32)  NOT NULL,
    CONSTRAINT PK___EFMigrationsHistory PRIMARY KEY (MigrationId)
) CHARACTER SET = utf8mb4;

INSERT IGNORE INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES
    ('20260822015154_CriarTabelaUsuarios', '9.0.13'),
    ('20260822131159_CriarTabelaClientes', '9.0.13'),
    ('20260822141742_CriarTabelaProdutos', '9.0.13'),
    ('20260822170649_CriarTabelasVendas',  '9.0.13'),
    ('20261019120000_AdicionarIndicesUnicos', '9.0.13');

SELECT 'Banco smartmoveis pronto.' AS resultado;
