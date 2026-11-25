using System.ComponentModel.DataAnnotations;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.DTOs;

public class CriarDevolucaoDto
{
    [Required(ErrorMessage = "Informe o motivo da devolução.")]
    [MinLength(3, ErrorMessage = "Descreva o motivo com pelo menos 3 caracteres.")]
    [MaxLength(250, ErrorMessage = "O campo Motivo deve ter no máximo 250 caracteres.")]
    public string Motivo { get; set; } = string.Empty;

    [Required(ErrorMessage = "O campo Itens é obrigatório.")]
    [MinLength(1, ErrorMessage = "Selecione pelo menos um item para devolver.")]
    public List<ItemDevolucaoDto> Itens { get; set; } = new();

    /// <summary>
    /// Se a parte devolvida já tinha sido paga pelo cliente, o sistema gera
    /// um reembolso (conta a pagar). Informando a forma aqui, o reembolso
    /// já é registrado como pago; sem ela, fica em aberto no Financeiro.
    /// </summary>
    [RegularExpression(FormasPagamento.ExpressaoBaixa, ErrorMessage = "Forma de reembolso inválida.")]
    public string? FormaReembolso { get; set; }
}

public class ItemDevolucaoDto
{
    [Required(ErrorMessage = "O campo Item da venda é obrigatório.")]
    public int ItemVendaId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "A quantidade devolvida deve ser maior que zero.")]
    public int Quantidade { get; set; }
}
