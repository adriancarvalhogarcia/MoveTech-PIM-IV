using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;
using SmartMoveis.API.Data;
using SmartMoveis.API.Infraestrutura;
using SmartMoveis.API.Services;

var builder = WebApplication.CreateBuilder(args);

// =============================================================
// BANCO DE DADOS
// =============================================================

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "A connection string 'DefaultConnection' não foi encontrada."
    );
}

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options
        .UseMySql(
            connectionString,
            new MySqlServerVersion(new Version(8, 0, 46))
        )
        .ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning))
);

// =============================================================
// CAMADA DE SERVIÇOS (regras de negócio)
// =============================================================

builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IClienteService, ClienteService>();
builder.Services.AddScoped<IProdutoService, ProdutoService>();
builder.Services.AddScoped<IVendaService, VendaService>();
builder.Services.AddScoped<IUsuarioService, UsuarioService>();
builder.Services.AddScoped<IRelatorioService, RelatorioService>();
builder.Services.AddScoped<IDevolucaoService, DevolucaoService>();
builder.Services.AddScoped<INotaEntradaService, NotaEntradaService>();
builder.Services.AddScoped<IFinanceiroService, FinanceiroService>();
builder.Services.AddScoped<DescricaoEntidadesService>();
builder.Services.AddScoped<IBancoProgramadoService, BancoProgramadoService>();

// Monitoramento: GET /health confere se a API alcança o MySQL.
builder.Services.AddHealthChecks()
    .AddCheck<BancoHealthCheck>("mysql");

// Usuário logado (nome e perfil do token) para auditoria.
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IUsuarioAtual, UsuarioAtual>();

// =============================================================
// CONTROLLERS E VALIDAÇÃO
// =============================================================

builder.Services
    .AddControllers()
    .ConfigureApiBehaviorOptions(options =>
    {
        // Dados inválidos continuam voltando como 400 (ProblemDetails),
        // agora também com "mensagem", o mesmo campo usado nos demais erros.
        options.InvalidModelStateResponseFactory = contexto =>
        {
            var problema = new ValidationProblemDetails(contexto.ModelState)
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "Dados inválidos."
            };

            var primeiroErro = contexto.ModelState.Values
                .SelectMany(v => v.Errors)
                .Select(e => e.ErrorMessage)
                .FirstOrDefault(m => !string.IsNullOrWhiteSpace(m));

            problema.Extensions["mensagem"] = primeiroErro ?? "Dados inválidos.";

            return new BadRequestObjectResult(problema);
        };
    });

// =============================================================
// AUTENTICAÇÃO (JWT) E AUTORIZAÇÃO POR PERFIL
// =============================================================

// A chave não fica mais no appsettings.json: ela é lida dos
// user-secrets (desenvolvimento) ou da variável de ambiente Jwt__Key.
var jwtKey = builder.Configuration["Jwt:Key"];

if (string.IsNullOrWhiteSpace(jwtKey) || jwtKey.Length < 32)
{
    throw new InvalidOperationException(
        "A chave JWT não foi configurada (mínimo de 32 caracteres). " +
        "Rode o 2_iniciar_api.cmd, que gera a chave automaticamente, " +
        "ou defina a variável de ambiente Jwt__Key."
    );
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],

            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)
            )
        };

        options.Events = new JwtBearerEvents
        {
            // 403: usuário autenticado, mas o perfil não tem permissão.
            OnForbidden = async contexto =>
            {
                contexto.Response.StatusCode = StatusCodes.Status403Forbidden;
                await contexto.Response.WriteAsJsonAsync(new
                {
                    mensagem = "Seu perfil não tem permissão para esta operação."
                });
            }
        };
    });

builder.Services.AddAuthorization();

// Origens do sistema web. Em nuvem/Docker podem ser trocadas pela
// configuração Cors:Origens (variável de ambiente Cors__Origens__0 etc.).
var origensPermitidas = builder.Configuration.GetSection("Cors:Origens").Get<string[]>()
    ?? new[] { "http://127.0.0.1:5500", "http://localhost:5500" };

builder.Services.AddCors(options =>
{
    options.AddPolicy("Frontend", policy =>
    {
        policy
            .WithOrigins(origensPermitidas)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

// =============================================================
// MIGRATIONS PENDENTES
// =============================================================

using (var escopo = app.Services.CreateScope())
{
    var contexto = escopo.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    var log = escopo.ServiceProvider.GetRequiredService<ILogger<Program>>();

    try
    {
        var pendentes = contexto.Database.GetPendingMigrations().ToList();

        if (pendentes.Count > 0)
        {
            log.LogInformation("Aplicando migrations: {Migrations}", string.Join(", ", pendentes));
            contexto.Database.Migrate();
        }
    }
    catch (Exception ex)
    {
        // A API continua no ar; o problema fica registrado no console.
        log.LogError(ex,
            "Não foi possível aplicar as migrations. Verifique se existem " +
            "CPFs de clientes ou e-mails de usuários repetidos no banco.");
    }
}

// =============================================================
// PIPELINE HTTP
// =============================================================

// CORS vem antes do tratamento de erros para que as respostas de
// erro também cheguem ao navegador do sistema web.
app.UseCors("Frontend");

// Tratamento global de erros: qualquer exceção não tratada vira um
// 500 em JSON com "mensagem", sem expor detalhes internos ao cliente.
app.UseExceptionHandler(erro =>
{
    erro.Run(async contexto =>
    {
        var excecao = contexto.Features.Get<IExceptionHandlerFeature>()?.Error;

        var log = contexto.RequestServices.GetRequiredService<ILogger<Program>>();
        log.LogError(excecao, "Erro não tratado em {Caminho}", contexto.Request.Path);

        var mensagem = excecao is DbUpdateException
            ? "Não foi possível salvar os dados. Verifique se o registro já existe."
            : "Ocorreu um erro interno. Tente novamente em instantes.";

        contexto.Response.StatusCode = excecao is DbUpdateException
            ? StatusCodes.Status409Conflict
            : StatusCodes.Status500InternalServerError;

        await contexto.Response.WriteAsJsonAsync(new { mensagem });
    });
});

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => "MoveTech API funcionando");
app.MapHealthChecks("/health");

app.MapControllers();

app.Run();
