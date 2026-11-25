using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>
/// Converte o resultado da camada de serviço em resposta HTTP.
/// Fica na camada de apresentação (Controllers) para que os
/// serviços não conheçam detalhes do protocolo HTTP.
/// </summary>
public static class ResultadoServicoExtensions
{
    public static ActionResult ParaFalha<T>(
        this ControllerBase controller,
        ResultadoServico<T> resultado)
    {
        return resultado.Falha switch
        {
            TipoFalha.NaoEncontrado => controller.NotFound(resultado.Erro),
            TipoFalha.Conflito => controller.Conflict(resultado.Erro),
            _ => controller.BadRequest(resultado.Erro)
        };
    }

    public static ActionResult ParaResposta<T>(
        this ControllerBase controller,
        ResultadoServico<T> resultado)
    {
        return resultado.Sucesso
            ? controller.Ok(resultado.Dados)
            : controller.ParaFalha(resultado);
    }
}
