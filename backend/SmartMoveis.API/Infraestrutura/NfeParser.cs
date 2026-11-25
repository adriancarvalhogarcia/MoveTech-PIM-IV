using System.Globalization;
using System.Xml;
using System.Xml.Linq;

namespace SmartMoveis.API.Infraestrutura;

/// <summary>Erro de leitura do XML da nota (mensagem pronta para o usuário).</summary>
public class NfeInvalidaException : Exception
{
    public NfeInvalidaException(string mensagem) : base(mensagem) { }
}

public record NfeEmitente(string Documento, string RazaoSocial, string? NomeFantasia);

public record NfeDuplicata(string Numero, DateTime Vencimento, decimal Valor);

public record NfeItem(
    int NumeroItem,
    string Codigo,
    string? CodigoBarras,
    string Descricao,
    string? Ncm,
    string? Unidade,
    decimal Quantidade,
    decimal ValorProdutos,
    decimal CustoTotal,
    decimal CustoUnitario)
{
    public bool QuantidadeInteira => Quantidade == Math.Floor(Quantidade) && Quantidade > 0;
}

public record NfeLida(
    string ChaveAcesso,
    string Numero,
    string Serie,
    DateTime DataEmissao,
    NfeEmitente Emitente,
    decimal ValorProdutos,
    decimal ValorTotal,
    List<NfeItem> Itens,
    List<NfeDuplicata> Duplicatas);

/// <summary>
/// Lê o XML da NF-e (modelo 55, layout 4.00), com ou sem o envelope
/// nfeProc. Usa só os campos necessários para a entrada de mercadoria.
/// O custo de cada item inclui frete, seguro, outras despesas, IPI e
/// ICMS-ST, e desconta o desconto do item.
/// </summary>
public static class NfeParser
{
    private static readonly CultureInfo Ponto = CultureInfo.InvariantCulture;

    public static NfeLida Ler(string xml)
    {
        if (string.IsNullOrWhiteSpace(xml))
        {
            throw new NfeInvalidaException("O arquivo XML está vazio.");
        }

        XDocument documento;

        try
        {
            // Bloqueia DTD e entidades externas (proteção contra XXE).
            var configuracao = new XmlReaderSettings
            {
                DtdProcessing = DtdProcessing.Prohibit,
                XmlResolver = null,
                MaxCharactersInDocument = 10_000_000
            };

            using var leitor = XmlReader.Create(new StringReader(xml.Trim()), configuracao);
            documento = XDocument.Load(leitor);
        }
        catch (XmlException)
        {
            throw new NfeInvalidaException("O arquivo não é um XML válido.");
        }

        var infNFe = documento.Descendants().FirstOrDefault(e => e.Name.LocalName == "infNFe")
            ?? throw new NfeInvalidaException("O XML não é de uma NF-e (tag infNFe não encontrada).");

        var ide = Filho(infNFe, "ide") ?? throw new NfeInvalidaException("Tag ide não encontrada.");
        var emit = Filho(infNFe, "emit") ?? throw new NfeInvalidaException("Emitente (emit) não encontrado.");

        var chave = SoDigitos(infNFe.Attribute("Id")?.Value);

        if (chave.Length != 44)
        {
            chave = SoDigitos(documento.Descendants().FirstOrDefault(e => e.Name.LocalName == "chNFe")?.Value);
        }

        if (chave.Length != 44)
        {
            throw new NfeInvalidaException("Chave de acesso da nota não encontrada.");
        }

        var documentoEmitente = SoDigitos(Texto(emit, "CNPJ") ?? Texto(emit, "CPF"));

        if (documentoEmitente.Length is not (11 or 14))
        {
            throw new NfeInvalidaException("CNPJ/CPF do emitente não encontrado.");
        }

        var emitente = new NfeEmitente(
            documentoEmitente,
            Limitar(Texto(emit, "xNome") ?? "Fornecedor sem nome", 150)!,
            Limitar(Texto(emit, "xFant"), 150));

        var dataTexto = Texto(ide, "dhEmi") ?? Texto(ide, "dEmi");

        if (!DateTimeOffset.TryParse(dataTexto, Ponto, DateTimeStyles.AssumeLocal, out var emissao))
        {
            throw new NfeInvalidaException("Data de emissão da nota inválida.");
        }

        var itens = new List<NfeItem>();

        foreach (var det in infNFe.Elements().Where(e => e.Name.LocalName == "det"))
        {
            var prod = Filho(det, "prod") ?? throw new NfeInvalidaException("Item da nota sem a tag prod.");
            var imposto = Filho(det, "imposto");

            var quantidade = Numero(prod, "qCom");
            var valorProdutos = Numero(prod, "vProd");

            if (quantidade <= 0)
            {
                throw new NfeInvalidaException($"Item {det.Attribute("nItem")?.Value}: quantidade inválida.");
            }

            var ipi = imposto?.Descendants().FirstOrDefault(e => e.Name.LocalName == "vIPI");
            var st = imposto?.Descendants().FirstOrDefault(e => e.Name.LocalName == "vICMSST");

            var custoTotal =
                valorProdutos
                + Numero(prod, "vFrete")
                + Numero(prod, "vSeg")
                + Numero(prod, "vOutro")
                - Numero(prod, "vDesc")
                + ParaDecimal(ipi?.Value)
                + ParaDecimal(st?.Value);

            var ean = SoDigitos(Texto(prod, "cEAN"));

            itens.Add(new NfeItem(
                int.TryParse(det.Attribute("nItem")?.Value, out var n) ? n : itens.Count + 1,
                Limitar(Texto(prod, "cProd") ?? $"ITEM{itens.Count + 1}", 60)!,
                ean.Length is 8 or 12 or 13 or 14 ? ean : null,
                Limitar(Texto(prod, "xProd") ?? "Produto sem descrição", 150)!,
                Texto(prod, "NCM"),
                Texto(prod, "uCom"),
                quantidade,
                Math.Round(valorProdutos, 2),
                Math.Round(custoTotal, 2),
                Math.Round(custoTotal / quantidade, 4)));
        }

        if (itens.Count == 0)
        {
            throw new NfeInvalidaException("A nota não possui itens.");
        }

        var total = infNFe.Descendants().FirstOrDefault(e => e.Name.LocalName == "ICMSTot");

        var duplicatas = infNFe.Descendants()
            .Where(e => e.Name.LocalName == "dup")
            .Select(d => new NfeDuplicata(
                Texto(d, "nDup") ?? "",
                DateTime.TryParse(Texto(d, "dVenc"), Ponto, DateTimeStyles.None, out var venc) ? venc.Date : emissao.Date,
                Numero(d, "vDup")))
            .Where(d => d.Valor > 0)
            .ToList();

        return new NfeLida(
            chave,
            Texto(ide, "nNF") ?? "",
            Texto(ide, "serie") ?? "",
            emissao.DateTime,
            emitente,
            total != null ? Numero(total, "vProd") : itens.Sum(i => i.ValorProdutos),
            total != null ? Numero(total, "vNF") : itens.Sum(i => i.CustoTotal),
            itens,
            duplicatas);
    }

    private static XElement? Filho(XElement pai, string nome) =>
        pai.Elements().FirstOrDefault(e => e.Name.LocalName == nome);

    private static string? Texto(XElement pai, string nome)
    {
        var valor = Filho(pai, nome)?.Value?.Trim();
        return string.IsNullOrEmpty(valor) ? null : valor;
    }

    private static decimal Numero(XElement pai, string nome) => ParaDecimal(Texto(pai, nome));

    private static decimal ParaDecimal(string? texto) =>
        decimal.TryParse(texto, NumberStyles.Number, Ponto, out var valor) ? valor : 0m;

    private static string SoDigitos(string? texto) =>
        new((texto ?? "").Where(char.IsDigit).ToArray());

    private static string? Limitar(string? texto, int maximo) =>
        texto == null ? null : texto.Length <= maximo ? texto : texto[..maximo];
}
