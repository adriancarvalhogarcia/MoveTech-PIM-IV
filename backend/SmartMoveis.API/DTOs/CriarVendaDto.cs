using System.ComponentModel.DataAnnotations;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.DTOs;

public class CriarVendaDto
{
    [Required(ErrorMessage = "O campo Cliente é obrigatório.")]
    public int ClienteId { get; set; }

    [Required(ErrorMessage = "O campo Itens é obrigatório.")]
    [MinLength(1, ErrorMessage = "Informe pelo menos um item.")]
    public List<CriarItemVendaDto> Itens { get; set; } = new();

    /// <summary>
    /// Dinheiro, Pix ou CartaoDebito: recebido na hora (conta já baixada).
    /// CartaoCredito, Boleto ou Crediario: gera parcelas em aberto.
    /// Se não for informada (versões antigas do app), a venda gera uma
    /// conta a receber em aberto para ser baixada no Financeiro.
    /// </summary>
    [RegularExpression(FormasPagamento.ExpressaoVenda, ErrorMessage = "Forma de pagamento inválida.")]
    public string? FormaPagamento { get; set; }

    [Range(1, 12, ErrorMessage = "O número de parcelas deve estar entre 1 e 12.")]
    public int Parcelas { get; set; } = 1;
}
