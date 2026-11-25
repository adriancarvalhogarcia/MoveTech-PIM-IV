using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartMoveis.API.Migrations
{
    /// <inheritdoc />
    public partial class ModulosFinanceiroNotasDevolucao : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FormaPagamento",
                table: "Vendas",
                type: "varchar(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "Parcelas",
                table: "Vendas",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Vendas",
                type: "varchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<decimal>(
                name: "ValorDevolvido",
                table: "Vendas",
                type: "decimal(10,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "CodigoBarras",
                table: "Produtos",
                type: "varchar(14)",
                maxLength: 14,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<decimal>(
                name: "CustoMedio",
                table: "Produtos",
                type: "decimal(12,4)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "QuantidadeDevolvida",
                table: "ItensVenda",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Devolucoes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    VendaId = table.Column<int>(type: "int", nullable: false),
                    Motivo = table.Column<string>(type: "varchar(250)", maxLength: 250, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ValorTotal = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    UsuarioNome = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CriadoEm = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Devolucoes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Devolucoes_Vendas_VendaId",
                        column: x => x.VendaId,
                        principalTable: "Vendas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Fornecedores",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    RazaoSocial = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    NomeFantasia = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Documento = table.Column<string>(type: "varchar(14)", maxLength: 14, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Ativo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    CriadoEm = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Fornecedores", x => x.Id);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "ItensDevolucao",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    DevolucaoId = table.Column<int>(type: "int", nullable: false),
                    ItemVendaId = table.Column<int>(type: "int", nullable: false),
                    ProdutoId = table.Column<int>(type: "int", nullable: false),
                    Quantidade = table.Column<int>(type: "int", nullable: false),
                    PrecoUnitario = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    Subtotal = table.Column<decimal>(type: "decimal(10,2)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ItensDevolucao", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ItensDevolucao_Devolucoes_DevolucaoId",
                        column: x => x.DevolucaoId,
                        principalTable: "Devolucoes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ItensDevolucao_ItensVenda_ItemVendaId",
                        column: x => x.ItemVendaId,
                        principalTable: "ItensVenda",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ItensDevolucao_Produtos_ProdutoId",
                        column: x => x.ProdutoId,
                        principalTable: "Produtos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "NotasEntrada",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    FornecedorId = table.Column<int>(type: "int", nullable: false),
                    Numero = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Serie = table.Column<string>(type: "varchar(5)", maxLength: 5, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ChaveAcesso = table.Column<string>(type: "varchar(44)", maxLength: 44, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DataEmissao = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    ValorProdutos = table.Column<decimal>(type: "decimal(12,2)", nullable: false),
                    ValorTotal = table.Column<decimal>(type: "decimal(12,2)", nullable: false),
                    MarkupPercentual = table.Column<decimal>(type: "decimal(6,2)", nullable: false),
                    UsuarioNome = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CriadoEm = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotasEntrada", x => x.Id);
                    table.ForeignKey(
                        name: "FK_NotasEntrada_Fornecedores_FornecedorId",
                        column: x => x.FornecedorId,
                        principalTable: "Fornecedores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "ProdutosFornecedores",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    FornecedorId = table.Column<int>(type: "int", nullable: false),
                    CodigoFornecedor = table.Column<string>(type: "varchar(60)", maxLength: 60, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ProdutoId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProdutosFornecedores", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProdutosFornecedores_Fornecedores_FornecedorId",
                        column: x => x.FornecedorId,
                        principalTable: "Fornecedores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ProdutosFornecedores_Produtos_ProdutoId",
                        column: x => x.ProdutoId,
                        principalTable: "Produtos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "ContasFinanceiras",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    Tipo = table.Column<string>(type: "varchar(10)", maxLength: 10, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Descricao = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Origem = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    VendaId = table.Column<int>(type: "int", nullable: true),
                    NotaEntradaId = table.Column<int>(type: "int", nullable: true),
                    DevolucaoId = table.Column<int>(type: "int", nullable: true),
                    ClienteId = table.Column<int>(type: "int", nullable: true),
                    FornecedorId = table.Column<int>(type: "int", nullable: true),
                    NumeroParcela = table.Column<int>(type: "int", nullable: false),
                    TotalParcelas = table.Column<int>(type: "int", nullable: false),
                    Valor = table.Column<decimal>(type: "decimal(12,2)", nullable: false),
                    Vencimento = table.Column<DateTime>(type: "date", nullable: false),
                    Status = table.Column<string>(type: "varchar(12)", maxLength: 12, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DataPagamento = table.Column<DateTime>(type: "date", nullable: true),
                    ValorPago = table.Column<decimal>(type: "decimal(12,2)", nullable: true),
                    FormaPagamento = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Observacao = table.Column<string>(type: "varchar(250)", maxLength: 250, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CriadoEm = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ContasFinanceiras", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ContasFinanceiras_Clientes_ClienteId",
                        column: x => x.ClienteId,
                        principalTable: "Clientes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ContasFinanceiras_Devolucoes_DevolucaoId",
                        column: x => x.DevolucaoId,
                        principalTable: "Devolucoes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ContasFinanceiras_Fornecedores_FornecedorId",
                        column: x => x.FornecedorId,
                        principalTable: "Fornecedores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ContasFinanceiras_NotasEntrada_NotaEntradaId",
                        column: x => x.NotaEntradaId,
                        principalTable: "NotasEntrada",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ContasFinanceiras_Vendas_VendaId",
                        column: x => x.VendaId,
                        principalTable: "Vendas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "ItensNotaEntrada",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    NotaEntradaId = table.Column<int>(type: "int", nullable: false),
                    ProdutoId = table.Column<int>(type: "int", nullable: false),
                    CodigoFornecedor = table.Column<string>(type: "varchar(60)", maxLength: 60, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Descricao = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Quantidade = table.Column<int>(type: "int", nullable: false),
                    CustoUnitario = table.Column<decimal>(type: "decimal(12,4)", nullable: false),
                    CustoTotal = table.Column<decimal>(type: "decimal(12,2)", nullable: false),
                    ProdutoCriado = table.Column<bool>(type: "tinyint(1)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ItensNotaEntrada", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ItensNotaEntrada_NotasEntrada_NotaEntradaId",
                        column: x => x.NotaEntradaId,
                        principalTable: "NotasEntrada",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ItensNotaEntrada_Produtos_ProdutoId",
                        column: x => x.ProdutoId,
                        principalTable: "Produtos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "HistoricoContasFinanceiras",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    ContaFinanceiraId = table.Column<int>(type: "int", nullable: false),
                    Acao = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Detalhe = table.Column<string>(type: "varchar(250)", maxLength: 250, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    UsuarioNome = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CriadoEm = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_HistoricoContasFinanceiras", x => x.Id);
                    table.ForeignKey(
                        name: "FK_HistoricoContasFinanceiras_ContasFinanceiras_ContaFinanceira~",
                        column: x => x.ContaFinanceiraId,
                        principalTable: "ContasFinanceiras",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Produtos_CodigoBarras",
                table: "Produtos",
                column: "CodigoBarras");

            migrationBuilder.CreateIndex(
                name: "IX_ContasFinanceiras_ClienteId",
                table: "ContasFinanceiras",
                column: "ClienteId");

            migrationBuilder.CreateIndex(
                name: "IX_ContasFinanceiras_DevolucaoId",
                table: "ContasFinanceiras",
                column: "DevolucaoId");

            migrationBuilder.CreateIndex(
                name: "IX_ContasFinanceiras_FornecedorId",
                table: "ContasFinanceiras",
                column: "FornecedorId");

            migrationBuilder.CreateIndex(
                name: "IX_ContasFinanceiras_NotaEntradaId",
                table: "ContasFinanceiras",
                column: "NotaEntradaId");

            migrationBuilder.CreateIndex(
                name: "IX_ContasFinanceiras_Tipo_Status_Vencimento",
                table: "ContasFinanceiras",
                columns: new[] { "Tipo", "Status", "Vencimento" });

            migrationBuilder.CreateIndex(
                name: "IX_ContasFinanceiras_VendaId",
                table: "ContasFinanceiras",
                column: "VendaId");

            migrationBuilder.CreateIndex(
                name: "IX_Devolucoes_VendaId",
                table: "Devolucoes",
                column: "VendaId");

            migrationBuilder.CreateIndex(
                name: "IX_Fornecedores_Documento",
                table: "Fornecedores",
                column: "Documento",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_HistoricoContasFinanceiras_ContaFinanceiraId",
                table: "HistoricoContasFinanceiras",
                column: "ContaFinanceiraId");

            migrationBuilder.CreateIndex(
                name: "IX_ItensDevolucao_DevolucaoId",
                table: "ItensDevolucao",
                column: "DevolucaoId");

            migrationBuilder.CreateIndex(
                name: "IX_ItensDevolucao_ItemVendaId",
                table: "ItensDevolucao",
                column: "ItemVendaId");

            migrationBuilder.CreateIndex(
                name: "IX_ItensDevolucao_ProdutoId",
                table: "ItensDevolucao",
                column: "ProdutoId");

            migrationBuilder.CreateIndex(
                name: "IX_ItensNotaEntrada_NotaEntradaId",
                table: "ItensNotaEntrada",
                column: "NotaEntradaId");

            migrationBuilder.CreateIndex(
                name: "IX_ItensNotaEntrada_ProdutoId",
                table: "ItensNotaEntrada",
                column: "ProdutoId");

            migrationBuilder.CreateIndex(
                name: "IX_NotasEntrada_ChaveAcesso",
                table: "NotasEntrada",
                column: "ChaveAcesso",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_NotasEntrada_FornecedorId",
                table: "NotasEntrada",
                column: "FornecedorId");

            migrationBuilder.CreateIndex(
                name: "IX_ProdutosFornecedores_FornecedorId_CodigoFornecedor",
                table: "ProdutosFornecedores",
                columns: new[] { "FornecedorId", "CodigoFornecedor" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProdutosFornecedores_ProdutoId",
                table: "ProdutosFornecedores",
                column: "ProdutoId");

            // Dados existentes (PIM III): vendas antigas e o perfil Vendedor.
            migrationBuilder.Sql("UPDATE Vendas SET FormaPagamento = 'NaoInformada' WHERE FormaPagamento = '' OR FormaPagamento IS NULL;");
            migrationBuilder.Sql("UPDATE Vendas SET Status = 'Concluida' WHERE Status = '' OR Status IS NULL;");
            migrationBuilder.Sql("UPDATE Vendas SET Parcelas = 1 WHERE Parcelas < 1;");
            migrationBuilder.Sql("UPDATE usuarios SET Perfil = 'Funcionario' WHERE Perfil = 'Vendedor';");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "HistoricoContasFinanceiras");

            migrationBuilder.DropTable(
                name: "ItensDevolucao");

            migrationBuilder.DropTable(
                name: "ItensNotaEntrada");

            migrationBuilder.DropTable(
                name: "ProdutosFornecedores");

            migrationBuilder.DropTable(
                name: "ContasFinanceiras");

            migrationBuilder.DropTable(
                name: "Devolucoes");

            migrationBuilder.DropTable(
                name: "NotasEntrada");

            migrationBuilder.DropTable(
                name: "Fornecedores");

            migrationBuilder.DropIndex(
                name: "IX_Produtos_CodigoBarras",
                table: "Produtos");

            migrationBuilder.DropColumn(
                name: "FormaPagamento",
                table: "Vendas");

            migrationBuilder.DropColumn(
                name: "Parcelas",
                table: "Vendas");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Vendas");

            migrationBuilder.DropColumn(
                name: "ValorDevolvido",
                table: "Vendas");

            migrationBuilder.DropColumn(
                name: "CodigoBarras",
                table: "Produtos");

            migrationBuilder.DropColumn(
                name: "CustoMedio",
                table: "Produtos");

            migrationBuilder.DropColumn(
                name: "QuantidadeDevolvida",
                table: "ItensVenda");
        }
    }
}
