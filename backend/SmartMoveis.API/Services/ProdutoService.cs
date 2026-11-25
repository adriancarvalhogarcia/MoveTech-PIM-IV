using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

public interface IProdutoService
{
    Task<List<Produto>> ListarAsync();
    Task<ResultadoServico<Produto>> ObterAsync(int id);
    Task<List<Produto>> ListarEstoqueBaixoAsync();
    Task<Produto> CriarAsync(CriarProdutoDto dto);
    Task<ResultadoServico<Produto>> AtualizarAsync(int id, AtualizarProdutoDto dto);
    Task<ResultadoServico<object>> DesativarAsync(int id);
}

/// <summary>Regras de negócio do cadastro de produtos e do estoque.</summary>
public class ProdutoService : IProdutoService
{
    private readonly ApplicationDbContext _context;

    public ProdutoService(ApplicationDbContext context)
    {
        _context = context;
    }

    public Task<List<Produto>> ListarAsync()
    {
        return _context.Produtos
            .OrderBy(p => p.Nome)
            .ToListAsync();
    }

    public async Task<ResultadoServico<Produto>> ObterAsync(int id)
    {
        var produto = await _context.Produtos
            .FirstOrDefaultAsync(p => p.Id == id);

        return produto == null
            ? ResultadoServico<Produto>.NaoEncontrado("Produto não encontrado.")
            : ResultadoServico<Produto>.Ok(produto);
    }

    public Task<List<Produto>> ListarEstoqueBaixoAsync()
    {
        return _context.Produtos
            .Where(p =>
                p.Ativo &&
                p.QuantidadeEstoque <= p.EstoqueMinimo
            )
            .OrderBy(p => p.QuantidadeEstoque)
            .ToListAsync();
    }

    public async Task<Produto> CriarAsync(CriarProdutoDto dto)
    {
        var produto = new Produto
        {
            Nome = dto.Nome.Trim(),
            Descricao = dto.Descricao,
            Categoria = dto.Categoria.Trim(),
            Preco = dto.Preco,
            QuantidadeEstoque = dto.QuantidadeEstoque,
            EstoqueMinimo = dto.EstoqueMinimo,
            CodigoBarras = string.IsNullOrWhiteSpace(dto.CodigoBarras) ? null : dto.CodigoBarras,
            Ativo = true,
            CriadoEm = DateTime.UtcNow
        };

        _context.Produtos.Add(produto);
        await _context.SaveChangesAsync();

        return produto;
    }

    public async Task<ResultadoServico<Produto>> AtualizarAsync(
        int id,
        AtualizarProdutoDto dto)
    {
        var produto = await _context.Produtos
            .FirstOrDefaultAsync(p => p.Id == id);

        if (produto == null)
        {
            return ResultadoServico<Produto>.NaoEncontrado("Produto não encontrado.");
        }

        produto.Nome = dto.Nome.Trim();
        produto.Descricao = dto.Descricao;
        produto.Categoria = dto.Categoria.Trim();
        produto.Preco = dto.Preco;
        produto.QuantidadeEstoque = dto.QuantidadeEstoque;
        produto.EstoqueMinimo = dto.EstoqueMinimo;
        // Campo ausente (null) mantém o código atual; texto vazio apaga.
        if (dto.CodigoBarras != null)
        {
            produto.CodigoBarras = string.IsNullOrWhiteSpace(dto.CodigoBarras)
                ? null
                : dto.CodigoBarras.Trim();
        }

        produto.Ativo = dto.Ativo;

        await _context.SaveChangesAsync();

        return ResultadoServico<Produto>.Ok(produto);
    }

    public async Task<ResultadoServico<object>> DesativarAsync(int id)
    {
        var produto = await _context.Produtos
            .FirstOrDefaultAsync(p => p.Id == id);

        if (produto == null)
        {
            return ResultadoServico<object>.NaoEncontrado("Produto não encontrado.");
        }

        produto.Ativo = false;
        await _context.SaveChangesAsync();

        return ResultadoServico<object>.Ok(new
        {
            mensagem = "Produto desativado com sucesso."
        });
    }
}
