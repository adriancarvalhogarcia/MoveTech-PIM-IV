namespace SmartMoveis.API.Models;

/// <summary>Formas de pagamento aceitas nas vendas e nas baixas financeiras.</summary>
public static class FormasPagamento
{
    public const string NaoInformada = "NaoInformada";
    public const string Dinheiro = "Dinheiro";
    public const string Pix = "Pix";
    public const string CartaoDebito = "CartaoDebito";
    public const string CartaoCredito = "CartaoCredito";
    public const string Boleto = "Boleto";
    public const string Crediario = "Crediario";
    public const string Transferencia = "Transferencia";

    /// <summary>Formas aceitas ao registrar uma venda.</summary>
    public static readonly string[] Venda =
        { Dinheiro, Pix, CartaoDebito, CartaoCredito, Boleto, Crediario };

    /// <summary>Formas aceitas ao baixar (pagar/receber) uma conta.</summary>
    public static readonly string[] Baixa =
        { Dinheiro, Pix, CartaoDebito, CartaoCredito, Boleto, Transferencia };

    /// <summary>Recebidas no ato: a conta a receber já nasce baixada.</summary>
    public static readonly string[] AVista = { Dinheiro, Pix, CartaoDebito };

    public const string ExpressaoVenda =
        "^(Dinheiro|Pix|CartaoDebito|CartaoCredito|Boleto|Crediario)$";

    public const string ExpressaoBaixa =
        "^(Dinheiro|Pix|CartaoDebito|CartaoCredito|Boleto|Transferencia)$";
}

public static class StatusVenda
{
    public const string Concluida = "Concluida";
    public const string DevolvidaParcial = "DevolvidaParcial";
    public const string Devolvida = "Devolvida";
}

public static class TipoConta
{
    public const string Receber = "Receber";
    public const string Pagar = "Pagar";
}

public static class StatusConta
{
    public const string Aberta = "Aberta";
    public const string Paga = "Paga";
    public const string Cancelada = "Cancelada";
}

public static class OrigemConta
{
    public const string Venda = "Venda";
    public const string NotaEntrada = "NotaEntrada";
    public const string Devolucao = "Devolucao";
    public const string Manual = "Manual";
}
