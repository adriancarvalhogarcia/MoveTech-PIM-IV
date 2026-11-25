# =============================================================
# MoveTech API - imagem Docker (build em duas etapas)
#   1) SDK do .NET 10 compila e publica a API
#   2) runtime ASP.NET 10 (imagem menor) executa o resultado
# Uso pelo docker-compose.yml da raiz do projeto.
# =============================================================
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY SmartMoveis.API.csproj ./
RUN dotnet restore SmartMoveis.API.csproj
COPY . ./
RUN dotnet publish SmartMoveis.API.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
# curl só para o healthcheck do container (GET /health)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /app ./
ENV ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080
# Usuário sem privilégios de administrador (já existe na imagem oficial)
USER app
ENTRYPOINT ["dotnet", "SmartMoveis.API.dll"]
