namespace SmartMoveis.API.Services;

/// <summary>
/// Tipos de falha que a camada de serviço pode devolver.
/// O controller traduz cada um para o status HTTP correspondente.
/// </summary>
public enum TipoFalha
{
    Nenhuma,
    NaoEncontrado,
    Conflito,
    Invalido
}

/// <summary>
/// Resultado de uma operação de negócio. Permite que os serviços
/// informem sucesso ou falha sem depender de classes do ASP.NET,
/// mantendo as regras de negócio separadas da camada HTTP.
/// </summary>
public class ResultadoServico<T>
{
    public bool Sucesso { get; private init; }
    public T? Dados { get; private init; }
    public TipoFalha Falha { get; private init; } = TipoFalha.Nenhuma;
    public object? Erro { get; private init; }

    public static ResultadoServico<T> Ok(T dados) =>
        new() { Sucesso = true, Dados = dados };

    public static ResultadoServico<T> NaoEncontrado(string mensagem) =>
        new() { Falha = TipoFalha.NaoEncontrado, Erro = new { mensagem } };

    public static ResultadoServico<T> Conflito(string mensagem) =>
        new() { Falha = TipoFalha.Conflito, Erro = new { mensagem } };

    public static ResultadoServico<T> Invalido(string mensagem) =>
        new() { Falha = TipoFalha.Invalido, Erro = new { mensagem } };

    /// <summary>Falha de validação com dados extras no corpo da resposta.</summary>
    public static ResultadoServico<T> Invalido(object erro) =>
        new() { Falha = TipoFalha.Invalido, Erro = erro };
}
