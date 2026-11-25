using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using SmartMoveis.API.Data;

#nullable disable

namespace SmartMoveis.API.Migrations
{
    /// <summary>
    /// PIM IV: garante no banco que não existam dois clientes com o
    /// mesmo CPF nem dois usuários com o mesmo e-mail.
    /// </summary>
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20261019120000_AdicionarIndicesUnicos")]
    public partial class AdicionarIndicesUnicos : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_Clientes_CPF",
                table: "Clientes",
                column: "CPF",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_usuarios_Email",
                table: "usuarios",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Clientes_CPF",
                table: "Clientes");

            migrationBuilder.DropIndex(
                name: "IX_usuarios_Email",
                table: "usuarios");
        }
    }
}
