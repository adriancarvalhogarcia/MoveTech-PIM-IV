using Microsoft.Extensions.Diagnostics.HealthChecks;
using SmartMoveis.API.Data;

namespace SmartMoveis.API.Infraestrutura;

/// <summary>
/// Verificação de saúde usada pelo monitoramento (Docker, nuvem):
/// GET /health responde Healthy quando a API consegue falar com o MySQL.
/// </summary>
public class BancoHealthCheck : IHealthCheck
{
    private readonly ApplicationDbContext _contexto;

    public BancoHealthCheck(ApplicationDbContext contexto)
    {
        _contexto = contexto;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            return await _contexto.Database.CanConnectAsync(cancellationToken)
                ? HealthCheckResult.Healthy("MySQL acessível.")
                : HealthCheckResult.Unhealthy("MySQL indisponível.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("MySQL indisponível.", ex);
        }
    }
}
