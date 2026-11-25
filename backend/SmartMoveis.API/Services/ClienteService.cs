using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

public interface IClienteService
{
    Task<List<Cliente>> ListarAsync();
    Task<ResultadoServico<Cliente>> ObterAsync(int id);
    Task<ResultadoServico<Cliente>> CriarAsync(CriarClienteDto dto);
    Task<ResultadoServico<Cliente>> AtualizarAsync(int id, AtualizarClienteDto dto);
    Task<ResultadoServico<object>> DesativarAsync(int id);
}

/// <summary>Regras de negócio do cadastro de clientes.</summary>
public class ClienteService : IClienteService
{
    private readonly ApplicationDbContext _context;

    public ClienteService(ApplicationDbContext context)
    {
        _context = context;
    }

    public Task<List<Cliente>> ListarAsync()
    {
        return _context.Clientes
            .OrderBy(c => c.Nome)
            .ToListAsync();
    }

    public async Task<ResultadoServico<Cliente>> ObterAsync(int id)
    {
        var cliente = await _context.Clientes
            .FirstOrDefaultAsync(c => c.Id == id);

        return cliente == null
            ? ResultadoServico<Cliente>.NaoEncontrado("Cliente não encontrado.")
            : ResultadoServico<Cliente>.Ok(cliente);
    }

    public async Task<ResultadoServico<Cliente>> CriarAsync(CriarClienteDto dto)
    {
        var cpfExiste = await _context.Clientes
            .AnyAsync(c => c.CPF == dto.CPF);

        if (cpfExiste)
        {
            return ResultadoServico<Cliente>.Conflito(
                "Já existe um cliente cadastrado com este CPF.");
        }

        var cliente = new Cliente
        {
            Nome = dto.Nome.Trim(),
            CPF = dto.CPF,
            Telefone = dto.Telefone,
            Email = dto.Email,
            Endereco = dto.Endereco,
            Ativo = true,
            CriadoEm = DateTime.UtcNow
        };

        _context.Clientes.Add(cliente);
        await _context.SaveChangesAsync();

        return ResultadoServico<Cliente>.Ok(cliente);
    }

    public async Task<ResultadoServico<Cliente>> AtualizarAsync(
        int id,
        AtualizarClienteDto dto)
    {
        var cliente = await _context.Clientes
            .FirstOrDefaultAsync(c => c.Id == id);

        if (cliente == null)
        {
            return ResultadoServico<Cliente>.NaoEncontrado("Cliente não encontrado.");
        }

        var cpfExiste = await _context.Clientes
            .AnyAsync(c => c.CPF == dto.CPF && c.Id != id);

        if (cpfExiste)
        {
            return ResultadoServico<Cliente>.Conflito(
                "Já existe outro cliente cadastrado com este CPF.");
        }

        cliente.Nome = dto.Nome.Trim();
        cliente.CPF = dto.CPF;
        cliente.Telefone = dto.Telefone;
        cliente.Email = dto.Email;
        cliente.Endereco = dto.Endereco;
        cliente.Ativo = dto.Ativo;

        await _context.SaveChangesAsync();

        return ResultadoServico<Cliente>.Ok(cliente);
    }

    public async Task<ResultadoServico<object>> DesativarAsync(int id)
    {
        var cliente = await _context.Clientes
            .FirstOrDefaultAsync(c => c.Id == id);

        if (cliente == null)
        {
            return ResultadoServico<object>.NaoEncontrado("Cliente não encontrado.");
        }

        cliente.Ativo = false;
        await _context.SaveChangesAsync();

        return ResultadoServico<object>.Ok(new
        {
            mensagem = "Cliente desativado com sucesso."
        });
    }
}
