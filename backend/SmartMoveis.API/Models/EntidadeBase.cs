namespace SmartMoveis.API.Models;

public abstract class EntidadeBase
{
    private string _identificadorInterno = Guid.NewGuid().ToString();

    protected string IdentificadorInterno
    {
        get => _identificadorInterno;
        private set => _identificadorInterno = value;
    }

    public string ObterIdentificadorInterno()
    {
        return IdentificadorInterno;
    }

    public virtual string ObterDescricao()
    {
        return "Entidade do sistema MoveTech";
    }
}