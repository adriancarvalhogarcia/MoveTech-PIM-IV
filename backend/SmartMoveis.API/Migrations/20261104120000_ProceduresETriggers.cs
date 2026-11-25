using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using SmartMoveis.API.Data;

#nullable disable

namespace SmartMoveis.API.Migrations
{
    /// <summary>
    /// PIM IV - Programação de Banco de Dados: cria a tabela de auditoria
    /// de estoque, as triggers e as stored procedures usadas pela API.
    /// O mesmo conteúdo, em formato para o MySQL Workbench, está em
    /// banco/04_procedures_triggers.sql.
    /// </summary>
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20261104120000_ProceduresETriggers")]
    public partial class ProceduresETriggers : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            foreach (var comando in BancoProgramado.Criar)
            {
                migrationBuilder.Sql(comando);
            }
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            foreach (var comando in BancoProgramado.Remover)
            {
                migrationBuilder.Sql(comando);
            }
        }
    }

    /// <summary>
    /// Comandos SQL das triggers e procedures. Cada item é enviado
    /// separadamente ao MySQL, por isso não precisa de DELIMITER.
    /// </summary>
    internal static class BancoProgramado
    {
        public static readonly string[] Remover =
        {
            "DROP TRIGGER IF EXISTS trg_produtos_valida_estoque_insert;",
            "DROP TRIGGER IF EXISTS trg_produtos_valida_estoque_update;",
            "DROP TRIGGER IF EXISTS trg_produtos_auditoria_estoque;",
            "DROP TRIGGER IF EXISTS trg_contas_valida_valor;",
            "DROP PROCEDURE IF EXISTS sp_resumo_vendas_periodo;",
            "DROP PROCEDURE IF EXISTS sp_produtos_estoque_baixo;",
            "DROP PROCEDURE IF EXISTS sp_movimentacoes_estoque;",
            "DROP PROCEDURE IF EXISTS sp_contas_vencidas;",
            "DROP TABLE IF EXISTS MovimentacoesEstoque;"
        };

        public static readonly string[] Criar =
        {
            // Limpa versões anteriores (deixa a migration reexecutável).
            Remover[0], Remover[1], Remover[2], Remover[3],
            Remover[4], Remover[5], Remover[6], Remover[7],

            // ---------------------------------------------------------
            // Tabela alimentada somente pela trigger de auditoria
            // ---------------------------------------------------------
            @"CREATE TABLE IF NOT EXISTS MovimentacoesEstoque (
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",

            // ---------------------------------------------------------
            // TRIGGERS
            // ---------------------------------------------------------

            // 1. Estoque nunca fica negativo (cadastro).
            @"CREATE TRIGGER trg_produtos_valida_estoque_insert
              BEFORE INSERT ON Produtos
              FOR EACH ROW
              BEGIN
                  IF NEW.QuantidadeEstoque < 0 THEN
                      SIGNAL SQLSTATE '45000'
                          SET MESSAGE_TEXT = 'Estoque nao pode ser negativo.';
                  END IF;
              END;",

            // 2. Estoque nunca fica negativo (alteração, venda, devolução).
            @"CREATE TRIGGER trg_produtos_valida_estoque_update
              BEFORE UPDATE ON Produtos
              FOR EACH ROW
              BEGIN
                  IF NEW.QuantidadeEstoque < 0 THEN
                      SIGNAL SQLSTATE '45000'
                          SET MESSAGE_TEXT = 'Estoque nao pode ser negativo.';
                  END IF;
              END;",

            // 3. Toda mudança de estoque fica registrada (auditoria).
            @"CREATE TRIGGER trg_produtos_auditoria_estoque
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
              END;",

            // 4. Conta financeira precisa ter valor positivo.
            @"CREATE TRIGGER trg_contas_valida_valor
              BEFORE INSERT ON ContasFinanceiras
              FOR EACH ROW
              BEGIN
                  IF NEW.Valor <= 0 THEN
                      SIGNAL SQLSTATE '45000'
                          SET MESSAGE_TEXT = 'O valor da conta deve ser maior que zero.';
                  END IF;
              END;",

            // ---------------------------------------------------------
            // STORED PROCEDURES
            // ---------------------------------------------------------

            // Resumo de vendas de um período (faturamento bruto e líquido).
            @"CREATE PROCEDURE sp_resumo_vendas_periodo(IN p_inicio DATE, IN p_fim DATE)
              BEGIN
                  SELECT
                      COUNT(*)                                   AS QuantidadeVendas,
                      COALESCE(SUM(ValorTotal), 0)               AS FaturamentoBruto,
                      COALESCE(SUM(ValorDevolvido), 0)           AS TotalDevolvido,
                      COALESCE(SUM(ValorTotal - ValorDevolvido), 0) AS FaturamentoLiquido,
                      COALESCE(ROUND(AVG(ValorTotal), 2), 0)     AS TicketMedio
                  FROM Vendas
                  WHERE DATE(CriadoEm) BETWEEN p_inicio AND p_fim;
              END;",

            // Produtos ativos no estoque mínimo ou abaixo dele.
            @"CREATE PROCEDURE sp_produtos_estoque_baixo()
              BEGIN
                  SELECT Id, Nome, Categoria, QuantidadeEstoque, EstoqueMinimo,
                         (EstoqueMinimo - QuantidadeEstoque) AS FaltaParaMinimo
                  FROM Produtos
                  WHERE Ativo = 1 AND QuantidadeEstoque <= EstoqueMinimo
                  ORDER BY FaltaParaMinimo DESC, Nome;
              END;",

            // Histórico gravado pela trigger de auditoria (0 = todos os produtos).
            @"CREATE PROCEDURE sp_movimentacoes_estoque(IN p_produto_id INT, IN p_limite INT)
              BEGIN
                  SELECT m.Id, m.ProdutoId, p.Nome AS Produto, m.Tipo,
                         m.QuantidadeAnterior, m.QuantidadeNova, m.Diferenca, m.CriadoEm
                  FROM MovimentacoesEstoque m
                  INNER JOIN Produtos p ON p.Id = m.ProdutoId
                  WHERE p_produto_id = 0 OR m.ProdutoId = p_produto_id
                  ORDER BY m.CriadoEm DESC, m.Id DESC
                  LIMIT p_limite;
              END;",

            // Contas a pagar e a receber em aberto e já vencidas.
            @"CREATE PROCEDURE sp_contas_vencidas()
              BEGIN
                  SELECT Id, Tipo, Descricao, Origem, NumeroParcela, TotalParcelas,
                         Valor, Vencimento, DATEDIFF(CURDATE(), Vencimento) AS DiasEmAtraso
                  FROM ContasFinanceiras
                  WHERE Status = 'Aberta' AND Vencimento < CURDATE()
                  ORDER BY Vencimento, Id;
              END;"
        };
    }
}
