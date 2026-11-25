using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

public class DescricaoEntidadesService
{
    public List<string> ObterDescricoes(IEnumerable<EntidadeBase> entidades)
    {
        var descricoes = new List<string>();

        foreach (var entidade in entidades)
        {
            descricoes.Add(entidade.ObterDescricao());
        }

        return descricoes;
    }
}