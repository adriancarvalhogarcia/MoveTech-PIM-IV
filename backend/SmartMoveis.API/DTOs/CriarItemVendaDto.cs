using System.ComponentModel.DataAnnotations;

namespace SmartMoveis.API.DTOs;

public class CriarItemVendaDto
{
    [Required(ErrorMessage = "O campo Produto é obrigatório.")]
    public int ProdutoId { get; set; }

    [Required(ErrorMessage = "O campo Quantidade é obrigatório.")]
    [Range(1, int.MaxValue, ErrorMessage = "A quantidade deve ser no mínimo 1.")]
    public int Quantidade { get; set; }
}