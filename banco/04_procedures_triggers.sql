-- =============================================================
-- MoveTech - PIM IV - Programação de Banco de Dados
-- Triggers e stored procedures do banco smartmoveis
--
-- Este script é o mesmo conteúdo da migration
-- 20261104120000_ProceduresETriggers, que a API aplica sozinha ao
-- iniciar. Use-o para estudar ou para aplicar pelo MySQL Workbench
-- (execute depois do 01_criar_banco.sql e de a API ter rodado uma vez,
-- porque as tabelas do PIM IV são criadas pelas migrations).
-- Pode ser executado mais de uma vez.
-- =============================================================

USE smartmoveis;

-- Remove versões anteriores
DROP TRIGGER IF EXISTS trg_produtos_valida_estoque_insert;
DROP TRIGGER IF EXISTS trg_produtos_valida_estoque_update;
DROP TRIGGER IF EXISTS trg_produtos_auditoria_estoque;
DROP TRIGGER IF EXISTS trg_contas_valida_valor;
DROP PROCEDURE IF EXISTS sp_resumo_vendas_periodo;
DROP PROCEDURE IF EXISTS sp_produtos_estoque_baixo;
DROP PROCEDURE IF EXISTS sp_movimentacoes_estoque;
DROP PROCEDURE IF EXISTS sp_contas_vencidas;

-- Tabela de auditoria (alimentada somente pela trigger)
CREATE TABLE IF NOT EXISTS MovimentacoesEstoque (
    Id                 INT          NOT NULL AUTO_INCREMENT,
    ProdutoId          INT          NOT NULL,
    QuantidadeAnterior INT          NOT NULL,
    QuantidadeNova     INT          NOT NULL,
    Diferenca          INT          NOT NULL,
    Tipo               VARCHAR(10)  NOT NULL,
    CriadoEm           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_MovimentacoesEstoque PRIMARY KEY (Id),
    CONSTRAINT FK_MovimentacoesEstoque_Produtos FOREIGN KEY (ProdutoId)
        REFERENCES Produtos (Id) ON DELETE CASCADE,
    INDEX IX_MovimentacoesEstoque_Produto_Data (ProdutoId, CriadoEm)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELIMITER $$

CREATE TRIGGER trg_produtos_valida_estoque_insert
BEFORE INSERT ON Produtos
FOR EACH ROW
BEGIN
    IF NEW.QuantidadeEstoque < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque nao pode ser negativo.';
    END IF;
END$$

CREATE TRIGGER trg_produtos_valida_estoque_update
BEFORE UPDATE ON Produtos
FOR EACH ROW
BEGIN
    IF NEW.QuantidadeEstoque < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque nao pode ser negativo.';
    END IF;
END$$

CREATE TRIGGER trg_produtos_auditoria_estoque
AFTER UPDATE ON Produtos
FOR EACH ROW
BEGIN
    IF NEW.QuantidadeEstoque <> OLD.QuantidadeEstoque THEN
        INSERT INTO MovimentacoesEstoque
            (ProdutoId, QuantidadeAnterior, QuantidadeNova, Diferenca, Tipo)
        VALUES
            (NEW.Id, OLD.QuantidadeEstoque, NEW.QuantidadeEstoque,
             NEW.QuantidadeEstoque - OLD.QuantidadeEstoque,
             IF(NEW.QuantidadeEstoque > OLD.QuantidadeEstoque, 'ENTRADA', 'SAIDA'));
    END IF;
END$$

CREATE TRIGGER trg_contas_valida_valor
BEFORE INSERT ON ContasFinanceiras
FOR EACH ROW
BEGIN
    IF NEW.Valor <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O valor da conta deve ser maior que zero.';
    END IF;
END$$

CREATE PROCEDURE sp_resumo_vendas_periodo(IN p_inicio DATE, IN p_fim DATE)
BEGIN
    SELECT
        COUNT(*)                                   AS QuantidadeVendas,
        COALESCE(SUM(ValorTotal), 0)               AS FaturamentoBruto,
        COALESCE(SUM(ValorDevolvido), 0)           AS TotalDevolvido,
        COALESCE(SUM(ValorTotal - ValorDevolvido), 0) AS FaturamentoLiquido,
        COALESCE(ROUND(AVG(ValorTotal), 2), 0)     AS TicketMedio
    FROM Vendas
    WHERE DATE(CriadoEm) BETWEEN p_inicio AND p_fim;
END$$

CREATE PROCEDURE sp_produtos_estoque_baixo()
BEGIN
    SELECT Id, Nome, Categoria, QuantidadeEstoque, EstoqueMinimo,
           (EstoqueMinimo - QuantidadeEstoque) AS FaltaParaMinimo
    FROM Produtos
    WHERE Ativo = 1 AND QuantidadeEstoque <= EstoqueMinimo
    ORDER BY FaltaParaMinimo DESC, Nome;
END$$

CREATE PROCEDURE sp_movimentacoes_estoque(IN p_produto_id INT, IN p_limite INT)
BEGIN
    SELECT m.Id, m.ProdutoId, p.Nome AS Produto, m.Tipo,
           m.QuantidadeAnterior, m.QuantidadeNova, m.Diferenca, m.CriadoEm
    FROM MovimentacoesEstoque m
    INNER JOIN Produtos p ON p.Id = m.ProdutoId
    WHERE p_produto_id = 0 OR m.ProdutoId = p_produto_id
    ORDER BY m.CriadoEm DESC, m.Id DESC
    LIMIT p_limite;
END$$

CREATE PROCEDURE sp_contas_vencidas()
BEGIN
    SELECT Id, Tipo, Descricao, Origem, NumeroParcela, TotalParcelas,
           Valor, Vencimento, DATEDIFF(CURDATE(), Vencimento) AS DiasEmAtraso
    FROM ContasFinanceiras
    WHERE Status = 'Aberta' AND Vencimento < CURDATE()
    ORDER BY Vencimento, Id;
END$$

DELIMITER ;

-- =============================================================
-- TESTES (descomente para conferir)
-- =============================================================
-- CALL sp_resumo_vendas_periodo('2026-01-01', CURDATE());
-- CALL sp_produtos_estoque_baixo();
-- CALL sp_movimentacoes_estoque(0, 20);
-- CALL sp_contas_vencidas();
-- UPDATE Produtos SET QuantidadeEstoque = -1 WHERE Id = 1;  -- deve dar erro (trigger)
-- SHOW TRIGGERS FROM smartmoveis;
-- SHOW PROCEDURE STATUS WHERE Db = 'smartmoveis';
