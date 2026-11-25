using System.ComponentModel.DataAnnotations;

namespace SmartMoveis.API.Validacoes;

/// <summary>
/// Valida o CPF pelos dígitos verificadores. Aceita com ou sem máscara
/// (000.000.000-00 ou 00000000000). Recusa sequências repetidas
/// como 111.111.111-11.
/// </summary>
[AttributeUsage(AttributeTargets.Property)]
public sealed class CpfAttribute : ValidationAttribute
{
    public CpfAttribute()
        : base("CPF inválido.")
    {
    }

    public override bool IsValid(object? value)
    {
        // Campo vazio é tratado pelo [Required].
        if (value is not string texto || string.IsNullOrWhiteSpace(texto))
        {
            return true;
        }

        return CpfValido(texto);
    }

    public static bool CpfValido(string texto)
    {
        var digitos = texto.Where(char.IsDigit).Select(c => c - '0').ToArray();

        if (digitos.Length != 11 || digitos.Distinct().Count() == 1)
        {
            return false;
        }

        return digitos[9] == CalcularDigito(digitos, 9)
            && digitos[10] == CalcularDigito(digitos, 10);
    }

    private static int CalcularDigito(int[] digitos, int quantidade)
    {
        var soma = 0;

        for (var i = 0; i < quantidade; i++)
        {
            soma += digitos[i] * (quantidade + 1 - i);
        }

        var resto = soma % 11;
        return resto < 2 ? 0 : 11 - resto;
    }
}
