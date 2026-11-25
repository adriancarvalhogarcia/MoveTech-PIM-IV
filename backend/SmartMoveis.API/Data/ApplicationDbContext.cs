using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<Cliente> Clientes { get; set; }
    public DbSet<Produto> Produtos { get; set; }
    public DbSet<Venda> Vendas { get; set; }
    public DbSet<ItemVenda> ItensVenda { get; set; }

    // PIM IV
    public DbSet<Fornecedor> Fornecedores { get; set; }
    public DbSet<ProdutoFornecedor> ProdutosFornecedores { get; set; }
    public DbSet<NotaEntrada> NotasEntrada { get; set; }
    public DbSet<ItemNotaEntrada> ItensNotaEntrada { get; set; }
    public DbSet<Devolucao> Devolucoes { get; set; }
    public DbSet<ItemDevolucao> ItensDevolucao { get; set; }
    public DbSet<ContaFinanceira> ContasFinanceiras { get; set; }
    public DbSet<HistoricoContaFinanceira> HistoricoContasFinanceiras { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // CPF do cliente e e-mail do usuário são únicos também no banco,
        // e não só na validação da API.
        modelBuilder.Entity<Cliente>()
            .HasIndex(c => c.CPF)
            .IsUnique();

        modelBuilder.Entity<Usuario>()
            .HasIndex(u => u.Email)
            .IsUnique();

        modelBuilder.Entity<Venda>()
            .HasOne(v => v.Cliente)
            .WithMany()
            .HasForeignKey(v => v.ClienteId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ItemVenda>()
            .HasOne(i => i.Venda)
            .WithMany(v => v.Itens)
            .HasForeignKey(i => i.VendaId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ItemVenda>()
            .HasOne(i => i.Produto)
            .WithMany()
            .HasForeignKey(i => i.ProdutoId)
            .OnDelete(DeleteBehavior.Restrict);

        // =====================================================
        // PIM IV - fornecedores, notas de entrada, devoluções
        // e financeiro
        // =====================================================

        modelBuilder.Entity<Produto>()
            .HasIndex(p => p.CodigoBarras);

        modelBuilder.Entity<Fornecedor>()
            .HasIndex(f => f.Documento)
            .IsUnique();

        modelBuilder.Entity<ProdutoFornecedor>(e =>
        {
            e.ToTable("ProdutosFornecedores");
            e.HasIndex(pf => new { pf.FornecedorId, pf.CodigoFornecedor }).IsUnique();
            e.HasOne(pf => pf.Fornecedor).WithMany().HasForeignKey(pf => pf.FornecedorId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(pf => pf.Produto).WithMany().HasForeignKey(pf => pf.ProdutoId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<NotaEntrada>(e =>
        {
            e.ToTable("NotasEntrada");
            e.HasIndex(n => n.ChaveAcesso).IsUnique();
            e.HasOne(n => n.Fornecedor).WithMany().HasForeignKey(n => n.FornecedorId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ItemNotaEntrada>(e =>
        {
            e.ToTable("ItensNotaEntrada");
            e.HasOne(i => i.NotaEntrada).WithMany(n => n.Itens).HasForeignKey(i => i.NotaEntradaId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(i => i.Produto).WithMany().HasForeignKey(i => i.ProdutoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Devolucao>(e =>
        {
            e.ToTable("Devolucoes");
            e.HasOne(d => d.Venda).WithMany(v => v.Devolucoes).HasForeignKey(d => d.VendaId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ItemDevolucao>(e =>
        {
            e.ToTable("ItensDevolucao");
            e.HasOne(i => i.Devolucao).WithMany(d => d.Itens).HasForeignKey(i => i.DevolucaoId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(i => i.ItemVenda).WithMany().HasForeignKey(i => i.ItemVendaId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(i => i.Produto).WithMany().HasForeignKey(i => i.ProdutoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ContaFinanceira>(e =>
        {
            e.ToTable("ContasFinanceiras");
            e.HasIndex(c => new { c.Tipo, c.Status, c.Vencimento });
            e.HasOne(c => c.Venda).WithMany().HasForeignKey(c => c.VendaId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(c => c.NotaEntrada).WithMany().HasForeignKey(c => c.NotaEntradaId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(c => c.Cliente).WithMany().HasForeignKey(c => c.ClienteId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(c => c.Fornecedor).WithMany().HasForeignKey(c => c.FornecedorId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne<Devolucao>().WithMany().HasForeignKey(c => c.DevolucaoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<HistoricoContaFinanceira>(e =>
        {
            e.ToTable("HistoricoContasFinanceiras");
            e.HasOne(h => h.ContaFinanceira).WithMany(c => c.Historico)
                .HasForeignKey(h => h.ContaFinanceiraId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}