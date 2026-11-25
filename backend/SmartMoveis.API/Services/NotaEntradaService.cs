using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Infraestrutura;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

public interface INotaEntradaService
{
    Task<ResultadoServico<object>> PreviaAsync(PreviaNotaDto dto);
    Task<ResultadoServico<object>> ConfirmarAsync(ConfirmarNotaDto dto);
    Task<List<object>> ListarAsync();
    Task<ResultadoServico<object>> ObterAsync(int id);
    Task<List<object>> ListarFornecedoresAsync();
}

/// <summary>
/// Entrada de mercadorias pela importação do XML da NF-e:
/// prévia (lê a nota e reconhece os produtos) e confirmação (cadastra o
/// fornecedor, cria os produtos que faltam, soma o estoque, recalcula o
/// custo médio e gera as contas a pagar).
/// </summary>
public class NotaEntradaService : INotaEntradaService
{
    private readonly ApplicationDbContext _context;
    private readonly IUsuarioAtual _usuario;

    public NotaEntradaService(ApplicationDbContext context, IUsuarioAtual usuario)
    {
        _context = context;
        _usuario = usuario;
    }

    // =========================================================
    // PRÉVIA
    // =========================================================

    public async Task<ResultadoServico<object>> PreviaAsync(PreviaNotaDto dto)
    {
        NfeLida nota;

        try
        {
            nota = NfeParser.Ler(dto.Xml);
        }
        catch (NfeInvalidaException ex)
        {
            return ResultadoServico<object>.Invalido(ex.Message);
        }

        var notaExistente = await _context.NotasEntrada
            .Where(n => n.ChaveAcesso == nota.ChaveAcesso)
            .Select(n => (int?)n.Id)
            .FirstOrDefaultAsync();

        var fornecedor = await _context.Fornecedores
            .FirstOrDefaultAsync(f => f.Documento == nota.Emitente.Documento);

        var itens = new List<object>();

        foreach (var item in nota.Itens)
        {
            var (produto, motivo) = await ReconhecerAsync(item, fornecedor?.Id);

            itens.Add(new
            {
                item.NumeroItem,
                item.Codigo,
                item.CodigoBarras,
                item.Descricao,
                item.Ncm,
                item.Unidade,
                item.Quantidade,
                item.QuantidadeInteira,
                item.ValorProdutos,
                item.CustoTotal,
                item.CustoUnitario,
                acaoSugerida = produto != null ? "vincular" : "criar",
                produtoSugerido = produto == null ? null : new
                {
                    produto.Id,
                    produto.Nome,
                    produto.Categoria,
                    produto.Preco,
                    produto.QuantidadeEstoque,
                    produto.CustoMedio,
                    motivo
                },
                precoSugerido = PrecoComMarkup(item.CustoUnitario, dto.MarkupPercentual)
            });
        }

        return ResultadoServico<object>.Ok(new
        {
            nota.ChaveAcesso,
            nota.Numero,
            nota.Serie,
            nota.DataEmissao,
            nota.ValorProdutos,
            nota.ValorTotal,
            jaImportada = notaExistente.HasValue,
            notaExistenteId = notaExistente,
            fornecedor = new
            {
                nota.Emitente.Documento,
                nota.Emitente.RazaoSocial,
                nota.Emitente.NomeFantasia,
                cadastrado = fornecedor != null,
                id = fornecedor?.Id
            },
            duplicatas = nota.Duplicatas,
            dto.MarkupPercentual,
            itens
        });
    }

    // =========================================================
    // CONFIRMAÇÃO
    // =========================================================

    public async Task<ResultadoServico<object>> ConfirmarAsync(ConfirmarNotaDto dto)
    {
        NfeLida nota;

        try
        {
            nota = NfeParser.Ler(dto.Xml);
        }
        catch (NfeInvalidaException ex)
        {
            return ResultadoServico<object>.Invalido(ex.Message);
        }

        if (await _context.NotasEntrada.AnyAsync(n => n.ChaveAcesso == nota.ChaveAcesso))
        {
            return ResultadoServico<object>.Conflito(
                $"A nota {nota.Numero} (chave {nota.ChaveAcesso}) já foi importada.");
        }

        var fracionado = nota.Itens.FirstOrDefault(i => !i.QuantidadeInteira);

        if (fracionado != null)
        {
            return ResultadoServico<object>.Invalido(
                $"Item {fracionado.NumeroItem} ({fracionado.Descricao}) tem quantidade " +
                $"fracionada ({fracionado.Quantidade}). O estoque trabalha com unidades inteiras.");
        }

        await using var transacao = await _context.Database.BeginTransactionAsync();

        // Fornecedor: cadastra ou atualiza o nome pelo CNPJ.
        var fornecedor = await _context.Fornecedores
            .FirstOrDefaultAsync(f => f.Documento == nota.Emitente.Documento);

        if (fornecedor == null)
        {
            fornecedor = new Fornecedor
            {
                Documento = nota.Emitente.Documento,
                RazaoSocial = nota.Emitente.RazaoSocial,
                NomeFantasia = nota.Emitente.NomeFantasia
            };
            _context.Fornecedores.Add(fornecedor);
            await _context.SaveChangesAsync();
        }

        var entrada = new NotaEntrada
        {
            FornecedorId = fornecedor.Id,
            Numero = nota.Numero,
            Serie = nota.Serie,
            ChaveAcesso = nota.ChaveAcesso,
            DataEmissao = nota.DataEmissao,
            ValorProdutos = nota.ValorProdutos,
            ValorTotal = nota.ValorTotal,
            MarkupPercentual = dto.MarkupPercentual,
            UsuarioNome = _usuario.Nome
        };

        var criados = 0;
        var atualizados = 0;

        foreach (var item in nota.Itens)
        {
            var decisao = dto.Itens.FirstOrDefault(d => d.NumeroItem == item.NumeroItem);
            Produto? produto;

            if (decisao == null)
            {
                (produto, _) = await ReconhecerAsync(item, fornecedor.Id);
            }
            else if (decisao.Acao == "vincular")
            {
                if (decisao.ProdutoId == null)
                {
                    return ResultadoServico<object>.Invalido(
                        $"Item {item.NumeroItem}: escolha o produto para vincular.");
                }

                produto = await _context.Produtos.FirstOrDefaultAsync(p => p.Id == decisao.ProdutoId);

                if (produto == null)
                {
                    return ResultadoServico<object>.Invalido(
                        $"Item {item.NumeroItem}: produto {decisao.ProdutoId} não encontrado.");
                }
            }
            else
            {
                produto = null;
            }

            var quantidade = (int)item.Quantidade;
            var criado = false;

            if (produto == null)
            {
                produto = new Produto
                {
                    Nome = Limitar(decisao?.Nome?.Trim() is { Length: > 0 } nome ? nome : item.Descricao, 120),
                    Descricao = Limitar($"Cadastrado pela NF {nota.Numero} - {fornecedor.RazaoSocial}", 500),
                    Categoria = decisao?.Categoria?.Trim() is { Length: > 0 } cat ? cat : "Geral",
                    Preco = decisao?.PrecoVenda ?? PrecoComMarkup(item.CustoUnitario, dto.MarkupPercentual),
                    QuantidadeEstoque = quantidade,
                    EstoqueMinimo = decisao?.EstoqueMinimo ?? 0,
                    CustoMedio = item.CustoUnitario,
                    CodigoBarras = item.CodigoBarras,
                    Ativo = true,
                    CriadoEm = DateTime.UtcNow
                };

                _context.Produtos.Add(produto);
                await _context.SaveChangesAsync();
                criado = true;
                criados++;
            }
            else
            {
                // Custo médio ponderado: (estoque x custo atual + entrada x custo da nota) / estoque final
                var estoqueAnterior = Math.Max(produto.QuantidadeEstoque, 0);
                var custoAnterior = produto.CustoMedio > 0 ? produto.CustoMedio : item.CustoUnitario;

                produto.CustoMedio = estoqueAnterior + quantidade > 0
                    ? Math.Round(
                        (estoqueAnterior * custoAnterior + quantidade * item.CustoUnitario)
                        / (estoqueAnterior + quantidade), 4)
                    : item.CustoUnitario;

                produto.QuantidadeEstoque += quantidade;
                produto.CodigoBarras ??= item.CodigoBarras;
                atualizados++;
            }

            await LembrarVinculoAsync(fornecedor.Id, item.Codigo, produto.Id);

            entrada.Itens.Add(new ItemNotaEntrada
            {
                ProdutoId = produto.Id,
                CodigoFornecedor = item.Codigo,
                Descricao = item.Descricao,
                Quantidade = quantidade,
                CustoUnitario = item.CustoUnitario,
                CustoTotal = item.CustoTotal,
                ProdutoCriado = criado
            });
        }

        _context.NotasEntrada.Add(entrada);
        await _context.SaveChangesAsync();

        var contas = GerarContasPagar(entrada, fornecedor, nota, dto);
        _context.ContasFinanceiras.AddRange(contas);
        await _context.SaveChangesAsync();

        await transacao.CommitAsync();

        return ResultadoServico<object>.Ok(new
        {
            mensagem = $"Nota {nota.Numero} lançada: {atualizados} produto(s) atualizado(s), " +
                       $"{criados} cadastrado(s) e {contas.Count} conta(s) a pagar gerada(s).",
            entrada.Id,
            produtosCriados = criados,
            produtosAtualizados = atualizados,
            contasPagar = contas.Select(c => new { c.Id, c.NumeroParcela, c.Valor, c.Vencimento })
        });
    }

    private List<ContaFinanceira> GerarContasPagar(
        NotaEntrada entrada,
        Fornecedor fornecedor,
        NfeLida nota,
        ConfirmarNotaDto dto)
    {
        var modelo = new ContaFinanceira
        {
            Tipo = TipoConta.Pagar,
            Origem = OrigemConta.NotaEntrada,
            Descricao = $"NF {nota.Numero} - {fornecedor.RazaoSocial}",
            NotaEntradaId = entrada.Id,
            FornecedorId = fornecedor.Id
        };

        if (nota.Duplicatas.Count == 0)
        {
            var vencimento = dto.PrimeiroVencimento ?? nota.DataEmissao.Date.AddDays(30);
            return FinanceiroService.GerarParcelas(modelo, nota.ValorTotal, dto.Parcelas, vencimento, _usuario.Nome);
        }

        // A nota já traz as duplicatas: respeita valores e vencimentos.
        var contas = new List<ContaFinanceira>();
        var total = nota.Duplicatas.Count;

        for (var i = 0; i < total; i++)
        {
            var duplicata = nota.Duplicatas[i];
            var parcela = FinanceiroService.GerarParcelas(
                new ContaFinanceira
                {
                    Tipo = modelo.Tipo,
                    Origem = modelo.Origem,
                    Descricao = $"{modelo.Descricao} dup {duplicata.Numero}".Trim(),
                    NotaEntradaId = modelo.NotaEntradaId,
                    FornecedorId = modelo.FornecedorId
                },
                duplicata.Valor,
                1,
                duplicata.Vencimento,
                _usuario.Nome)[0];

            parcela.NumeroParcela = i + 1;
            parcela.TotalParcelas = total;
            contas.Add(parcela);
        }

        return contas;
    }

    // =========================================================
    // CONSULTAS
    // =========================================================

    public async Task<List<object>> ListarAsync()
    {
        var notas = await _context.NotasEntrada
            .AsNoTracking()
            .OrderByDescending(n => n.CriadoEm)
            .Select(n => new
            {
                n.Id,
                n.Numero,
                n.Serie,
                n.ChaveAcesso,
                n.DataEmissao,
                Fornecedor = n.Fornecedor!.RazaoSocial,
                FornecedorDocumento = n.Fornecedor.Documento,
                n.ValorTotal,
                QuantidadeItens = n.Itens.Count,
                n.UsuarioNome,
                n.CriadoEm
            })
            .Take(300)
            .ToListAsync();

        return notas.Cast<object>().ToList();
    }

    public async Task<ResultadoServico<object>> ObterAsync(int id)
    {
        var nota = await _context.NotasEntrada
            .AsNoTracking()
            .Where(n => n.Id == id)
            .Select(n => new
            {
                n.Id,
                n.Numero,
                n.Serie,
                n.ChaveAcesso,
                n.DataEmissao,
                Fornecedor = new { n.Fornecedor!.Id, n.Fornecedor.RazaoSocial, n.Fornecedor.Documento },
                n.ValorProdutos,
                n.ValorTotal,
                n.MarkupPercentual,
                n.UsuarioNome,
                n.CriadoEm,
                Itens = n.Itens.Select(i => new
                {
                    i.ProdutoId,
                    Produto = i.Produto!.Nome,
                    i.CodigoFornecedor,
                    i.Descricao,
                    i.Quantidade,
                    i.CustoUnitario,
                    i.CustoTotal,
                    i.ProdutoCriado
                })
            })
            .FirstOrDefaultAsync();

        if (nota == null)
        {
            return ResultadoServico<object>.NaoEncontrado("Nota de entrada não encontrada.");
        }

        var contas = await _context.ContasFinanceiras
            .AsNoTracking()
            .Where(c => c.NotaEntradaId == id)
            .OrderBy(c => c.NumeroParcela)
            .Select(c => new { c.Id, c.NumeroParcela, c.TotalParcelas, c.Valor, c.Vencimento, c.Status })
            .ToListAsync();

        return ResultadoServico<object>.Ok(new { nota, contasPagar = contas });
    }

    public async Task<List<object>> ListarFornecedoresAsync()
    {
        var fornecedores = await _context.Fornecedores
            .AsNoTracking()
            .OrderBy(f => f.RazaoSocial)
            .Select(f => new { f.Id, f.RazaoSocial, f.NomeFantasia, f.Documento, f.Ativo })
            .ToListAsync();

        return fornecedores.Cast<object>().ToList();
    }

    // =========================================================
    // APOIO
    // =========================================================

    /// <summary>
    /// Reconhece o produto do item: 1) vínculo já feito com o código do
    /// fornecedor; 2) código de barras; 3) mesmo nome.
    /// </summary>
    private async Task<(Produto? Produto, string? Motivo)> ReconhecerAsync(NfeItem item, int? fornecedorId)
    {
        if (fornecedorId.HasValue)
        {
            var vinculado = await _context.ProdutosFornecedores
                .Where(pf => pf.FornecedorId == fornecedorId && pf.CodigoFornecedor == item.Codigo)
                .Select(pf => pf.Produto)
                .FirstOrDefaultAsync();

            if (vinculado != null) return (vinculado, "código do fornecedor");
        }

        if (item.CodigoBarras != null)
        {
            var porCodigo = await _context.Produtos
                .FirstOrDefaultAsync(p => p.CodigoBarras == item.CodigoBarras);

            if (porCodigo != null) return (porCodigo, "código de barras");
        }

        var nome = item.Descricao.Trim();
        var porNome = await _context.Produtos.FirstOrDefaultAsync(p => p.Nome == nome);

        return porNome != null ? (porNome, "mesmo nome") : (null, null);
    }

    private async Task LembrarVinculoAsync(int fornecedorId, string codigo, int produtoId)
    {
        // Procura primeiro nos vínculos ainda não salvos (itens repetidos na mesma nota).
        var vinculo = _context.ProdutosFornecedores.Local
                          .FirstOrDefault(pf => pf.FornecedorId == fornecedorId && pf.CodigoFornecedor == codigo)
                      ?? await _context.ProdutosFornecedores
                          .FirstOrDefaultAsync(pf => pf.FornecedorId == fornecedorId && pf.CodigoFornecedor == codigo);

        if (vinculo == null)
        {
            _context.ProdutosFornecedores.Add(new ProdutoFornecedor
            {
                FornecedorId = fornecedorId,
                CodigoFornecedor = codigo,
                ProdutoId = produtoId
            });
        }
        else
        {
            vinculo.ProdutoId = produtoId;
        }
    }

    private static decimal PrecoComMarkup(decimal custo, decimal markup) =>
        Math.Max(0.01m, Math.Round(custo * (1 + markup / 100m), 2));

    private static string Limitar(string texto, int maximo) =>
        texto.Length <= maximo ? texto : texto[..maximo];
}
