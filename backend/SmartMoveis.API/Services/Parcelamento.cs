namespace SmartMoveis.API.Services;

/// <summary>Divide valores em parcelas sem perder centavos.</summary>
public static class Parcelamento
{
    /// <summary>
    /// Divide o total em <paramref name="parcelas"/> partes iguais em centavos;
    /// a diferença do arredondamento vai para a primeira parcela.
    /// Ex.: 100,00 em 3 → 33,34 + 33,33 + 33,33.
    /// </summary>
    public static List<decimal> Dividir(decimal total, int parcelas)
    {
        if (parcelas < 1) parcelas = 1;

        var baseParcela = Math.Floor(total / parcelas * 100m) / 100m;
        var resultado = Enumerable.Repeat(baseParcela, parcelas).ToList();
        resultado[0] += total - baseParcela * parcelas;

        return resultado;
    }
}
