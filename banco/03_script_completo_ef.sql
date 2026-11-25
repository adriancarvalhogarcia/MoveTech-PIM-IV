CREATE TABLE IF NOT EXISTS `__EFMigrationsHistory` (
    `MigrationId` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
    `ProductVersion` varchar(32) CHARACTER SET utf8mb4 NOT NULL,
    CONSTRAINT `PK___EFMigrationsHistory` PRIMARY KEY (`MigrationId`)
) CHARACTER SET=utf8mb4;

START TRANSACTION;
DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822015154_CriarTabelaUsuarios') THEN

    ALTER DATABASE CHARACTER SET utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822015154_CriarTabelaUsuarios') THEN

    CREATE TABLE `usuarios` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `Nome` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
        `Email` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
        `SenhaHash` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
        `Perfil` varchar(30) CHARACTER SET utf8mb4 NOT NULL,
        `Ativo` tinyint(1) NOT NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_usuarios` PRIMARY KEY (`Id`)
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822015154_CriarTabelaUsuarios') THEN

    INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
    VALUES ('20260822015154_CriarTabelaUsuarios', '9.0.13');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822131159_CriarTabelaClientes') THEN

    CREATE TABLE `Clientes` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `Nome` varchar(120) CHARACTER SET utf8mb4 NOT NULL,
        `CPF` varchar(14) CHARACTER SET utf8mb4 NOT NULL,
        `Telefone` varchar(20) CHARACTER SET utf8mb4 NULL,
        `Email` varchar(150) CHARACTER SET utf8mb4 NULL,
        `Endereco` varchar(250) CHARACTER SET utf8mb4 NULL,
        `Ativo` tinyint(1) NOT NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_Clientes` PRIMARY KEY (`Id`)
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822131159_CriarTabelaClientes') THEN

    INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
    VALUES ('20260822131159_CriarTabelaClientes', '9.0.13');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822141742_CriarTabelaProdutos') THEN

    CREATE TABLE `Produtos` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `Nome` varchar(120) CHARACTER SET utf8mb4 NOT NULL,
        `Descricao` varchar(500) CHARACTER SET utf8mb4 NULL,
        `Categoria` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
        `Preco` decimal(10,2) NOT NULL,
        `QuantidadeEstoque` int NOT NULL,
        `EstoqueMinimo` int NOT NULL,
        `Ativo` tinyint(1) NOT NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_Produtos` PRIMARY KEY (`Id`)
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822141742_CriarTabelaProdutos') THEN

    INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
    VALUES ('20260822141742_CriarTabelaProdutos', '9.0.13');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822170649_CriarTabelasVendas') THEN

    CREATE TABLE `Vendas` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `ClienteId` int NOT NULL,
        `ValorTotal` decimal(10,2) NOT NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_Vendas` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_Vendas_Clientes_ClienteId` FOREIGN KEY (`ClienteId`) REFERENCES `Clientes` (`Id`) ON DELETE RESTRICT
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822170649_CriarTabelasVendas') THEN

    CREATE TABLE `ItensVenda` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `VendaId` int NOT NULL,
        `ProdutoId` int NOT NULL,
        `Quantidade` int NOT NULL,
        `PrecoUnitario` decimal(10,2) NOT NULL,
        `Subtotal` decimal(10,2) NOT NULL,
        CONSTRAINT `PK_ItensVenda` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_ItensVenda_Produtos_ProdutoId` FOREIGN KEY (`ProdutoId`) REFERENCES `Produtos` (`Id`) ON DELETE RESTRICT,
        CONSTRAINT `FK_ItensVenda_Vendas_VendaId` FOREIGN KEY (`VendaId`) REFERENCES `Vendas` (`Id`) ON DELETE CASCADE
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822170649_CriarTabelasVendas') THEN

    CREATE INDEX `IX_ItensVenda_ProdutoId` ON `ItensVenda` (`ProdutoId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822170649_CriarTabelasVendas') THEN

    CREATE INDEX `IX_ItensVenda_VendaId` ON `ItensVenda` (`VendaId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822170649_CriarTabelasVendas') THEN

    CREATE INDEX `IX_Vendas_ClienteId` ON `Vendas` (`ClienteId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260822170649_CriarTabelasVendas') THEN

    INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
    VALUES ('20260822170649_CriarTabelasVendas', '9.0.13');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019120000_AdicionarIndicesUnicos') THEN

    CREATE UNIQUE INDEX `IX_Clientes_CPF` ON `Clientes` (`CPF`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019120000_AdicionarIndicesUnicos') THEN

    CREATE UNIQUE INDEX `IX_usuarios_Email` ON `usuarios` (`Email`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019120000_AdicionarIndicesUnicos') THEN

    INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
    VALUES ('20261019120000_AdicionarIndicesUnicos', '9.0.13');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    ALTER TABLE `Vendas` ADD `FormaPagamento` varchar(30) CHARACTER SET utf8mb4 NOT NULL DEFAULT '';

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    ALTER TABLE `Vendas` ADD `Parcelas` int NOT NULL DEFAULT 0;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    ALTER TABLE `Vendas` ADD `Status` varchar(20) CHARACTER SET utf8mb4 NOT NULL DEFAULT '';

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    ALTER TABLE `Vendas` ADD `ValorDevolvido` decimal(10,2) NOT NULL DEFAULT 0.0;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    ALTER TABLE `Produtos` ADD `CodigoBarras` varchar(14) CHARACTER SET utf8mb4 NULL;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    ALTER TABLE `Produtos` ADD `CustoMedio` decimal(12,4) NOT NULL DEFAULT 0.0;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    ALTER TABLE `ItensVenda` ADD `QuantidadeDevolvida` int NOT NULL DEFAULT 0;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE TABLE `Devolucoes` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `VendaId` int NOT NULL,
        `Motivo` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
        `ValorTotal` decimal(10,2) NOT NULL,
        `UsuarioNome` varchar(100) CHARACTER SET utf8mb4 NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_Devolucoes` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_Devolucoes_Vendas_VendaId` FOREIGN KEY (`VendaId`) REFERENCES `Vendas` (`Id`) ON DELETE RESTRICT
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE TABLE `Fornecedores` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `RazaoSocial` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
        `NomeFantasia` varchar(150) CHARACTER SET utf8mb4 NULL,
        `Documento` varchar(14) CHARACTER SET utf8mb4 NOT NULL,
        `Ativo` tinyint(1) NOT NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_Fornecedores` PRIMARY KEY (`Id`)
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE TABLE `ItensDevolucao` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `DevolucaoId` int NOT NULL,
        `ItemVendaId` int NOT NULL,
        `ProdutoId` int NOT NULL,
        `Quantidade` int NOT NULL,
        `PrecoUnitario` decimal(10,2) NOT NULL,
        `Subtotal` decimal(10,2) NOT NULL,
        CONSTRAINT `PK_ItensDevolucao` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_ItensDevolucao_Devolucoes_DevolucaoId` FOREIGN KEY (`DevolucaoId`) REFERENCES `Devolucoes` (`Id`) ON DELETE CASCADE,
        CONSTRAINT `FK_ItensDevolucao_ItensVenda_ItemVendaId` FOREIGN KEY (`ItemVendaId`) REFERENCES `ItensVenda` (`Id`) ON DELETE RESTRICT,
        CONSTRAINT `FK_ItensDevolucao_Produtos_ProdutoId` FOREIGN KEY (`ProdutoId`) REFERENCES `Produtos` (`Id`) ON DELETE RESTRICT
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE TABLE `NotasEntrada` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `FornecedorId` int NOT NULL,
        `Numero` varchar(20) CHARACTER SET utf8mb4 NOT NULL,
        `Serie` varchar(5) CHARACTER SET utf8mb4 NOT NULL,
        `ChaveAcesso` varchar(44) CHARACTER SET utf8mb4 NOT NULL,
        `DataEmissao` datetime(6) NOT NULL,
        `ValorProdutos` decimal(12,2) NOT NULL,
        `ValorTotal` decimal(12,2) NOT NULL,
        `MarkupPercentual` decimal(6,2) NOT NULL,
        `UsuarioNome` varchar(100) CHARACTER SET utf8mb4 NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_NotasEntrada` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_NotasEntrada_Fornecedores_FornecedorId` FOREIGN KEY (`FornecedorId`) REFERENCES `Fornecedores` (`Id`) ON DELETE RESTRICT
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE TABLE `ProdutosFornecedores` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `FornecedorId` int NOT NULL,
        `CodigoFornecedor` varchar(60) CHARACTER SET utf8mb4 NOT NULL,
        `ProdutoId` int NOT NULL,
        CONSTRAINT `PK_ProdutosFornecedores` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_ProdutosFornecedores_Fornecedores_FornecedorId` FOREIGN KEY (`FornecedorId`) REFERENCES `Fornecedores` (`Id`) ON DELETE CASCADE,
        CONSTRAINT `FK_ProdutosFornecedores_Produtos_ProdutoId` FOREIGN KEY (`ProdutoId`) REFERENCES `Produtos` (`Id`) ON DELETE CASCADE
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE TABLE `ContasFinanceiras` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `Tipo` varchar(10) CHARACTER SET utf8mb4 NOT NULL,
        `Descricao` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
        `Origem` varchar(20) CHARACTER SET utf8mb4 NOT NULL,
        `VendaId` int NULL,
        `NotaEntradaId` int NULL,
        `DevolucaoId` int NULL,
        `ClienteId` int NULL,
        `FornecedorId` int NULL,
        `NumeroParcela` int NOT NULL,
        `TotalParcelas` int NOT NULL,
        `Valor` decimal(12,2) NOT NULL,
        `Vencimento` date NOT NULL,
        `Status` varchar(12) CHARACTER SET utf8mb4 NOT NULL,
        `DataPagamento` date NULL,
        `ValorPago` decimal(12,2) NULL,
        `FormaPagamento` varchar(30) CHARACTER SET utf8mb4 NULL,
        `Observacao` varchar(250) CHARACTER SET utf8mb4 NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_ContasFinanceiras` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_ContasFinanceiras_Clientes_ClienteId` FOREIGN KEY (`ClienteId`) REFERENCES `Clientes` (`Id`) ON DELETE RESTRICT,
        CONSTRAINT `FK_ContasFinanceiras_Devolucoes_DevolucaoId` FOREIGN KEY (`DevolucaoId`) REFERENCES `Devolucoes` (`Id`) ON DELETE RESTRICT,
        CONSTRAINT `FK_ContasFinanceiras_Fornecedores_FornecedorId` FOREIGN KEY (`FornecedorId`) REFERENCES `Fornecedores` (`Id`) ON DELETE RESTRICT,
        CONSTRAINT `FK_ContasFinanceiras_NotasEntrada_NotaEntradaId` FOREIGN KEY (`NotaEntradaId`) REFERENCES `NotasEntrada` (`Id`) ON DELETE RESTRICT,
        CONSTRAINT `FK_ContasFinanceiras_Vendas_VendaId` FOREIGN KEY (`VendaId`) REFERENCES `Vendas` (`Id`) ON DELETE RESTRICT
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE TABLE `ItensNotaEntrada` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `NotaEntradaId` int NOT NULL,
        `ProdutoId` int NOT NULL,
        `CodigoFornecedor` varchar(60) CHARACTER SET utf8mb4 NOT NULL,
        `Descricao` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
        `Quantidade` int NOT NULL,
        `CustoUnitario` decimal(12,4) NOT NULL,
        `CustoTotal` decimal(12,2) NOT NULL,
        `ProdutoCriado` tinyint(1) NOT NULL,
        CONSTRAINT `PK_ItensNotaEntrada` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_ItensNotaEntrada_NotasEntrada_NotaEntradaId` FOREIGN KEY (`NotaEntradaId`) REFERENCES `NotasEntrada` (`Id`) ON DELETE CASCADE,
        CONSTRAINT `FK_ItensNotaEntrada_Produtos_ProdutoId` FOREIGN KEY (`ProdutoId`) REFERENCES `Produtos` (`Id`) ON DELETE RESTRICT
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE TABLE `HistoricoContasFinanceiras` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `ContaFinanceiraId` int NOT NULL,
        `Acao` varchar(20) CHARACTER SET utf8mb4 NOT NULL,
        `Detalhe` varchar(250) CHARACTER SET utf8mb4 NULL,
        `UsuarioNome` varchar(100) CHARACTER SET utf8mb4 NULL,
        `CriadoEm` datetime(6) NOT NULL,
        CONSTRAINT `PK_HistoricoContasFinanceiras` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_HistoricoContasFinanceiras_ContasFinanceiras_ContaFinanceira~` FOREIGN KEY (`ContaFinanceiraId`) REFERENCES `ContasFinanceiras` (`Id`) ON DELETE CASCADE
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_Produtos_CodigoBarras` ON `Produtos` (`CodigoBarras`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ContasFinanceiras_ClienteId` ON `ContasFinanceiras` (`ClienteId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ContasFinanceiras_DevolucaoId` ON `ContasFinanceiras` (`DevolucaoId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ContasFinanceiras_FornecedorId` ON `ContasFinanceiras` (`FornecedorId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ContasFinanceiras_NotaEntradaId` ON `ContasFinanceiras` (`NotaEntradaId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ContasFinanceiras_Tipo_Status_Vencimento` ON `ContasFinanceiras` (`Tipo`, `Status`, `Vencimento`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ContasFinanceiras_VendaId` ON `ContasFinanceiras` (`VendaId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_Devolucoes_VendaId` ON `Devolucoes` (`VendaId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE UNIQUE INDEX `IX_Fornecedores_Documento` ON `Fornecedores` (`Documento`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_HistoricoContasFinanceiras_ContaFinanceiraId` ON `HistoricoContasFinanceiras` (`ContaFinanceiraId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ItensDevolucao_DevolucaoId` ON `ItensDevolucao` (`DevolucaoId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ItensDevolucao_ItemVendaId` ON `ItensDevolucao` (`ItemVendaId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ItensDevolucao_ProdutoId` ON `ItensDevolucao` (`ProdutoId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ItensNotaEntrada_NotaEntradaId` ON `ItensNotaEntrada` (`NotaEntradaId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ItensNotaEntrada_ProdutoId` ON `ItensNotaEntrada` (`ProdutoId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE UNIQUE INDEX `IX_NotasEntrada_ChaveAcesso` ON `NotasEntrada` (`ChaveAcesso`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_NotasEntrada_FornecedorId` ON `NotasEntrada` (`FornecedorId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE UNIQUE INDEX `IX_ProdutosFornecedores_FornecedorId_CodigoFornecedor` ON `ProdutosFornecedores` (`FornecedorId`, `CodigoFornecedor`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    CREATE INDEX `IX_ProdutosFornecedores_ProdutoId` ON `ProdutosFornecedores` (`ProdutoId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    UPDATE Vendas SET FormaPagamento = 'NaoInformada' WHERE FormaPagamento = '' OR FormaPagamento IS NULL;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    UPDATE Vendas SET Status = 'Concluida' WHERE Status = '' OR Status IS NULL;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    UPDATE Vendas SET Parcelas = 1 WHERE Parcelas < 1;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    UPDATE usuarios SET Perfil = 'Funcionario' WHERE Perfil = 'Vendedor';

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20261019135229_ModulosFinanceiroNotasDevolucao') THEN

    INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
    VALUES ('20261019135229_ModulosFinanceiroNotasDevolucao', '9.0.13');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

COMMIT;

