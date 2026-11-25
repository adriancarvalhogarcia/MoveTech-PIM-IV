# MoveTech – pacote completo (PIM III + PIM IV)

Este pacote reúne tudo o que é preciso para rodar o sistema MoveTech:

| Pasta | O que é | Origem |
|---|---|---|
| `backend/` | API REST em ASP.NET Core (.NET 10) | PIM III + módulos do PIM IV (camada de serviços, perfis, devoluções, notas de entrada, financeiro) |
| `frontend/` | Sistema web (HTML, CSS, JS) | PIM III + telas do PIM IV (Usuários, Notas de entrada, Financeiro, devolução) |
| `mobile/` | Aplicativo Android/iOS em Flutter | PIM IV |
| `banco/` | Scripts SQL do banco MySQL e XML de exemplo | Migrations do PIM III e do PIM IV |
| `ferramentas/` | Gerador de migration e do script SQL completo | PIM IV |

A web e o mobile usam **a mesma API e o mesmo banco**. O app nunca acessa o
MySQL direto: ele fala com a API, e a API fala com o banco.

> **Estado desta entrega.** Tudo foi executado e testado num computador
> Windows: banco, API, sistema web e APK instalado em celular Android na
> mesma rede. Se algum passo falhar na sua máquina, veja a Parte 9.

## Resumo rápido

Com os programas instalados (Parte 1), são quatro comandos, nesta ordem:

```powershell
powershell -ExecutionPolicy Bypass -File .\0_verificar_instalacao.ps1
powershell -ExecutionPolicy Bypass -File .\1_preparar_banco.ps1
powershell -ExecutionPolicy Bypass -File .\2_iniciar_api.ps1      # deixe aberto
powershell -ExecutionPolicy Bypass -File .\3_gerar_apk.ps1        # em outra janela
```

O resultado é o arquivo **`MoveTech.apk`** nesta pasta, pronto para instalar
no celular (Parte 6).

| Script | O que faz |
|---|---|
| `0_verificar_instalacao.ps1` | Mostra quais programas estão instalados e quais faltam |
| `1_preparar_banco.ps1` | Inicia o MySQL; cria banco, tabelas e usuário admin se ainda não existirem; grava a connection string na API |
| `2_iniciar_api.ps1` | Sobe a API na rede local e mostra o endereço para o celular |
| `3_gerar_apk.ps1` | Compila o app e gera o `MoveTech.apk` apontando para o IP deste computador |
| `4_compartilhar_apk.ps1` | Abre uma página na rede para o celular baixar o APK |
| `5_rodar_no_emulador.ps1` | Roda o app no emulador ou em celular pelo cabo USB, sem gerar APK |
| `6_iniciar_web.ps1` | Serve o sistema web em `http://localhost:5500` e abre o navegador |
| `liberar_firewall.cmd` | Libera as portas 5071 (API) e 8080 (APK) no firewall; pede administrador sozinho |
| `redefinir_senha_mysql.cmd` | Redefine a senha do usuário root do MySQL, caso tenha sido esquecida |
| `ferramentas\gerar_migration.cmd` | Gera uma nova migration do EF e o `banco\03_script_completo_ef.sql` (feche a API antes) |

Cada script também tem um atalho `.cmd` com o mesmo nome. Basta dar dois
cliques nele no Explorador de Arquivos: ele roda o script e grava o que
apareceu na tela em `logs\`. O `4_compartilhar_apk.cmd` precisa de
administrador (botão direito → Executar como administrador).

## Sumário

1. [Instalar os programas (do zero)](#parte-1--instalar-os-programas-do-zero)
2. [Preparar o banco](#parte-2--preparar-o-banco)
3. [Subir a API](#parte-3--subir-a-api)
4. [Abrir o sistema web (opcional)](#parte-4--abrir-o-sistema-web-opcional)
5. [Gerar o APK](#parte-5--gerar-o-apk)
6. [Instalar e usar no celular (mesma rede)](#parte-6--instalar-e-usar-no-celular-mesma-rede)
7. [Rodar no emulador (opcional)](#parte-7--rodar-no-emulador-opcional)
8. [Roteiro de teste](#parte-8--roteiro-de-teste)
9. [Problemas comuns](#parte-9--problemas-comuns)
10. [Conformidade com o manual do PIM IV](#parte-10--conformidade-com-o-manual-do-pim-iv)
11. [Validações do app](#parte-11--validações-do-app)
12. [Documentação técnica do app](#parte-12--documentação-técnica-do-app)
13. [Módulos do PIM IV: perfis, devolução, notas e financeiro](#parte-13--módulos-do-pim-iv-perfis-devolução-notas-e-financeiro)

---

## Parte 1 – Instalar os programas (do zero)

Para **Windows 10 ou 11**. Reserve uns 20 GB livres e de 1 a 2 horas, quase
tudo de download.

| # | Programa | Para quê |
|---|---|---|
| 1.1 | Git for Windows | O Flutter depende dele |
| 1.2 | .NET 10 SDK | Rodar a API |
| 1.3 | MySQL Server 8 | Banco de dados |
| 1.4 | Flutter SDK | Compilar o app |
| 1.5 | Modo de Desenvolvedor do Windows | Exigido pelo Flutter |
| 1.6 | Android Studio | Android SDK (e emulador, se quiser) |

### Antes de começar: onde extrair e como abrir o PowerShell

1. Extraia o zip em um caminho **sem espaços e sem acentos**, por exemplo
   `C:\projetos\MoveTech_PIM4`. Mantenha as pastas juntas.
2. Para abrir o PowerShell já na pasta: abra a pasta no Explorador de
   Arquivos, clique na barra de endereço, digite `powershell` e tecle Enter.
3. Os scripts são executados sempre neste formato:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\NOME_DO_SCRIPT.ps1
   ```

### 1.1 Git
1. Baixe em https://git-scm.com/download/win e instale com as opções padrão.
2. Feche e abra o PowerShell e confira:
   ```powershell
   git --version
   ```

### 1.2 .NET 10 SDK
1. Baixe em https://dotnet.microsoft.com/download a opção **.NET 10 → SDK**
   (x64). Não serve só o "Runtime".
2. Confira:
   ```powershell
   dotnet --list-sdks
   ```
   Precisa aparecer uma linha começando com `10.`.

### 1.3 MySQL Server 8
1. Baixe o **MySQL Installer** em https://dev.mysql.com/downloads/installer/
   (o arquivo maior, "mysql-installer-community").
2. Em "Choosing a Setup Type", escolha **Custom** e selecione
   **MySQL Server** e **MySQL Workbench**. O Workbench é opcional, mas ajuda
   a ver os dados.
3. Na configuração do servidor, mantenha os padrões:
   - Config Type: Development Computer;
   - Porta: **3306**;
   - defina a **senha do usuário root** e anote. Os scripts vão pedir;
   - deixe marcado "Configure MySQL Server as a Windows Service" e
     "Start the MySQL Server at System Startup".
4. Confira que o serviço existe:
   ```powershell
   Get-Service MySQL*
   ```
   Deve aparecer algo como `MySQL80` com status `Running`.

### 1.4 Flutter SDK
A forma mais direta é pelo Git:
```powershell
mkdir C:\src
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
```
Se preferir, baixe o .zip em
https://docs.flutter.dev/get-started/install/windows/mobile e extraia em
`C:\src\flutter`. Não use `C:\Program Files`.

Depois, coloque o Flutter no PATH:
1. Menu Iniciar → digite "variáveis de ambiente" → **Editar as variáveis de
   ambiente do sistema** → botão **Variáveis de Ambiente**.
2. Em "Variáveis de usuário", selecione `Path` → Editar → Novo →
   `C:\src\flutter\bin` → OK em tudo.
3. **Feche e abra o PowerShell** e confira:
   ```powershell
   flutter --version
   ```
   A primeira execução baixa o Dart SDK e demora alguns minutos.

### 1.5 Modo de Desenvolvedor do Windows
```powershell
start ms-settings:developers
```
Ligue a opção **Modo de Desenvolvedor**. Sem isso, o Flutter não consegue
usar os plugins do app.

### 1.6 Android Studio
1. Baixe em https://developer.android.com/studio e instale com as opções
   padrão.
2. Abra o Android Studio uma vez e conclua o assistente inicial (Standard).
   Ele baixa o Android SDK.
3. Na tela inicial: **More Actions → SDK Manager → aba SDK Tools** → marque
   **Android SDK Command-line Tools (latest)** → Apply.
4. Aceite as licenças do Android:
   ```powershell
   flutter doctor --android-licenses
   ```
   Responda `y` para todas.
5. Diagnóstico final:
   ```powershell
   flutter doctor
   ```
   As linhas **Flutter** e **Android toolchain** precisam estar com ✓.
   Avisos sobre Visual Studio e Chrome podem ser ignorados.

Você não precisa criar emulador para gerar o APK e testar no celular. O
emulador só é necessário para a Parte 7.

### 1.7 Conferência
```powershell
powershell -ExecutionPolicy Bypass -File .\0_verificar_instalacao.ps1
```
Siga para a Parte 2 quando todas as linhas estiverem `[ OK ]`.

---

## Parte 2 – Preparar o banco

```powershell
powershell -ExecutionPolicy Bypass -File .\1_preparar_banco.ps1
```

O script pede a senha do `root` do MySQL (a que você definiu no passo 1.3) e:

1. inicia o serviço do MySQL, se estiver parado;
2. **verifica se o banco `smartmoveis` e as 5 tabelas já existem:**
   - se já existem, não cria nem altera nada;
   - se não existem, ou falta alguma tabela, cria o banco, as tabelas, o
     login `admin@movetech.com` / `Admin@123`, um cliente e dois produtos;
3. grava a connection string na API, com user-secrets, fora do código-fonte.

Você pode rodá-lo sempre antes de subir a API. Para inserir de novo os dados
de exemplo em um banco que já existe, acrescente `-Forcar`. Nada é apagado.

**Se preferir fazer à mão no Workbench:** execute `banco\01_criar_banco.sql`
e depois `banco\02_dados_iniciais.sql`. Em seguida, grave a connection string:
```powershell
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "server=localhost;port=3306;database=smartmoveis;user=root;password=SUA_SENHA" --project backend\SmartMoveis.API
```

**Se iniciar o MySQL der erro de permissão:** abra o PowerShell como
administrador e rode `net start MySQL80` (use o nome que apareceu em
`Get-Service MySQL*`).

| Tabela | Conteúdo |
|---|---|
| `usuarios` | Logins da web e do mobile (senha em hash BCrypt) |
| `Clientes` | Cadastro de clientes |
| `Produtos` | Catálogo, preço e estoque |
| `Vendas` | Cabeçalho de cada venda |
| `ItensVenda` | Produtos de cada venda |
| `__EFMigrationsHistory` | Controle interno do Entity Framework |

---

## Parte 3 – Subir a API

```powershell
powershell -ExecutionPolicy Bypass -File .\2_iniciar_api.ps1
```

**Deixe essa janela aberta.** A primeira execução baixa os pacotes NuGet e
compila; depois aparece um quadro com os endereços:

```
 API MoveTech
   Neste computador:   http://localhost:5071
   No celular (app):   http://192.168.0.15:5071/api
```

Teste no navegador do computador: `http://localhost:5071` deve mostrar
"MoveTech API funcionando".

**Firewall.** Para o celular alcançar a API, a porta 5071 precisa estar
liberada. Se o PowerShell estiver como administrador, o script libera
sozinho. Caso contrário ele mostra o comando para rodar uma única vez, como
administrador:
```powershell
netsh advfirewall firewall add rule name="MoveTech API" dir=in action=allow protocol=TCP localport=5071
```

---

## Parte 4 – Abrir o sistema web (opcional)

O app não precisa da web, mas vale abrir os dois juntos para mostrar a
integração: uma venda feita no celular aparece no dashboard web.

A API só aceita o site quando ele é aberto em `http://localhost:5500` ou
`http://127.0.0.1:5500` (regra de CORS do PIM III). O jeito mais simples:

Dê dois cliques em **`6_iniciar_web.cmd`**. Ele publica a pasta `frontend`
em `http://localhost:5500` e abre o navegador. Deixe a janela aberta.

(Alternativa: abrir a pasta `frontend` no VS Code e usar a extensão
**Live Server** em `index.html`.)

Entre com o mesmo login: `admin@movetech.com` / `Admin@123`.

---

## Parte 5 – Gerar o APK

Com a API já funcionando, abra **outra janela** do PowerShell na pasta do
pacote:

```powershell
powershell -ExecutionPolicy Bypass -File .\3_gerar_apk.ps1
```

O script:
1. gera as pastas nativas do Android na primeira vez (`mobile\configurar.ps1`);
2. descobre o IP deste computador na rede;
3. compila o app em modo release;
4. deixa o **`MoveTech.apk`** na raiz do pacote, já apontando para
   `http://SEU-IP:5071/api`.

A primeira compilação leva de 5 a 15 minutos. As seguintes, 1 a 2 minutos.

Se o IP detectado estiver errado (computador com VPN ou duas redes):
```powershell
powershell -ExecutionPolicy Bypass -File .\3_gerar_apk.ps1 -Ip 192.168.0.15
```

**Alternativa sem instalar Flutter e Android Studio:** envie esta pasta
inteira para um repositório no GitHub. Na aba **Actions**, rode o fluxo
**Gerar APK** informando o endereço da API. Em 6 a 10 minutos o APK fica
disponível para download em "Artifacts".

---

## Parte 6 – Instalar e usar no celular (mesma rede)

O celular e o computador precisam estar **no mesmo Wi-Fi**, e a API precisa
estar rodando (Parte 3).

### 6.1 Teste a rede antes
No navegador do celular, abra o endereço que o script da API mostrou, sem o
`/api`, por exemplo `http://192.168.0.15:5071`. Deve aparecer
"MoveTech API funcionando". Se não aparecer, o problema é de rede ou de
firewall, e não do app (veja a Parte 9).

### 6.2 Leve o APK até o celular
Escolha um jeito:

- **Download pela rede.** Abra o PowerShell **como administrador** e rode:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\4_compartilhar_apk.ps1
  ```
  No navegador do celular, abra o endereço mostrado (por exemplo
  `http://192.168.0.15:8080`) e toque em **Baixar o aplicativo**.
- **Cabo USB:** copie o `MoveTech.apk` para a pasta Download do celular.
- **WhatsApp, e-mail ou Google Drive:** envie o arquivo para você mesmo.

### 6.3 Instale
1. No celular, toque no arquivo `MoveTech.apk`.
2. O Android pede autorização para "instalar apps desconhecidos" do
   aplicativo que abriu o arquivo (Chrome, Arquivos, WhatsApp). Autorize.
3. Se o Play Protect avisar que não reconhece o desenvolvedor, toque em
   **Mais detalhes → Instalar mesmo assim**. É o esperado para um APK de teste.

### 6.4 Use
1. Abra o **MoveTech**.
2. Entre com `admin@movetech.com` / `Admin@123`.
3. Se aparecer "Não foi possível conectar ao servidor", toque na
   **engrenagem** no canto da tela de login, confira o endereço
   (`http://IP-DO-PC:5071/api`), toque em **Testar** e depois em **Salvar**.

Se o computador mudar de rede e o IP mudar, basta trocar o endereço na
engrenagem. Não é preciso gerar outro APK.

Redes de visitantes e algumas redes de faculdade bloqueiam a comunicação
entre aparelhos. Nesse caso, ligue o roteador do celular (hotspot), conecte
o notebook nele e gere o APK de novo, ou troque o endereço na engrenagem.

---

## Parte 7 – Rodar no emulador (opcional)

Útil para desenvolver e tirar prints sem celular.

1. No Android Studio: **More Actions → Virtual Device Manager → Create
   device**, escolha um Pixel e a imagem de sistema mais recente, e inicie
   o emulador (▶).
2. Rode:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\5_rodar_no_emulador.ps1
   ```

No emulador, o endereço `http://10.0.2.2:5071/api` já vem configurado. Ele
aponta para o próprio computador. Também funciona com um celular ligado pelo
cabo USB com a Depuração USB ativada.

---

## Parte 8 – Roteiro de teste

| # | Teste | Resultado esperado |
|---|---|---|
| 1 | Login com senha errada | "E-mail ou senha inválidos." |
| 2 | Login correto | Abre a tela Início com os indicadores |
| 3 | Produtos → buscar e filtrar "Estoque baixo" | Lista filtrada; selo de estoque colorido |
| 4 | Clientes → Novo cliente com CPF inválido | Erro no campo; não envia |
| 5 | Novo cliente com CPF já cadastrado | "CPF já cadastrado para ..." |
| 6 | Novo cliente válido | Aparece na lista do app e no sistema web |
| 7 | Nova venda sem cliente ou sem produto | Aviso; venda não enviada |
| 8 | Nova venda: aumentar a quantidade até o estoque | O botão "+" desabilita no limite |
| 9 | Nova venda válida | "Venda #N registrada"; o estoque baixa na web |
| 10 | **Offline:** pare a API (Ctrl+C) e registre uma venda | "Venda guardada no aparelho"; aparece como Pendente em Vendas |
| 11 | Suba a API de novo | Em até 30 s a venda é enviada e entra no histórico |
| 12 | Minha conta → Sair | Volta ao login; as vendas pendentes continuam guardadas |
| 13 | Nova venda em Pix | A conta a receber já aparece como Recebida no Financeiro |
| 14 | Nova venda no crediário em 3x | 3 parcelas em aberto, a primeira em 30 dias |
| 15 | Vendas → Detalhe → Registrar devolução de 1 item | Estoque volta; parcela em aberto é abatida |
| 16 | Devolução de venda já paga, informando "Já devolvi por Pix" | Reembolso lançado como pago (conta a pagar) |
| 17 | Web → Notas de entrada → Importar `banco\exemplos\nfe_exemplo_moveis.xml` | Prévia com produto reconhecido e produtos novos com preço pelo markup |
| 18 | Confirmar a nota | Estoque somado, custo médio recalculado, 2 contas a pagar (duplicatas) |
| 19 | Importar a mesma nota de novo | "A nota ... já foi importada." |
| 20 | Financeiro → Pagar uma conta → Estornar | Conta volta para Em aberto; histórico mostra Baixada e Estornada |
| 21 | Login com usuário **Funcionário** | Menu sem Usuários, Notas e Financeiro; API responde 403 se tentar |

---

## Parte 9 – Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| "a execução de scripts foi desabilitada neste sistema" | Script chamado sem o Bypass | Use `powershell -ExecutionPolicy Bypass -File .\script.ps1` |
| `flutter` ou `dotnet` não é reconhecido | PATH não atualizado | Feche e abra o PowerShell; confira os passos 1.2 e 1.4 |
| "Building with plugins requires symlink support" | Modo de Desenvolvedor desligado | Passo 1.5 |
| "Android sdkmanager not found" ou licenças pendentes | Command-line Tools ou licenças | Passo 1.6, itens 3 e 4 |
| Script 1: "Nao foi possivel conectar ao MySQL" | Senha errada ou serviço parado | Confira a senha; `Get-Service MySQL*` |
| Script 1: "Nao encontrei o mysql.exe" | MySQL em pasta diferente | Execute os dois arquivos de `banco\` pelo Workbench (Parte 2) |
| API: "Unable to connect to any of the specified MySQL hosts" | MySQL parado | Rode o script 1 de novo |
| API: "Access denied for user 'root'" | Senha mudou | Rode o script 1 de novo |
| API: "Table 'smartmoveis.usuarios' doesn't exist" | Tabelas não criadas | Rode o script 1 de novo |
| API: erro ao compilar por versão do .NET | SDK diferente do 10 | Passo 1.2 |
| Erro de compilação em arquivo `.dart` | Diferença de versão do Flutter | Rode `flutter analyze` dentro de `mobile` e guarde a mensagem para correção |
| App: "Não foi possível conectar ao servidor" | IP errado, API parada, firewall ou redes diferentes | Parte 6.1 e firewall da Parte 3 |
| Funciona no navegador do celular, mas não no app | Endereço sem `/api` no final | Use `http://IP:5071/api` na engrenagem |
| App: "Cleartext HTTP traffic not permitted" | Pastas nativas geradas sem o ajuste | Apague `mobile\android` e rode o script 3 de novo |
| Login cai logo com "Sessão expirou" | Relógio do celular muito diferente do computador | Ative data e hora automáticas |
| Web abre, mas não faz login | Site aberto fora da porta 5500 | Parte 4 (Live Server) |
| Script 4: "Acesso negado" | PowerShell sem administrador | Abra como administrador |

---

## Parte 10 – Conformidade com o manual do PIM IV

O que este pacote cobre de cada etapa do manual e o que ainda depende de
trabalho. Nada aqui substitui o documento escrito em ABNT, que vale metade
da nota.

| Etapa do manual | Pontos | O que o pacote entrega | O que ainda falta |
|---|---|---|---|
| 1 – Caracterização da organização | 1,0 | Contexto da loja de móveis no sistema (módulos de venda, estoque, compras e financeiro) | Texto no documento |
| 2 – Planejamento da solução (Empreendedorismo em TI) | 1,0 | Solução funcionando que materializa a proposta de valor | Texto no documento (problema, público-alvo, proposta de valor, diferenciais, viabilidade) |
| 3 – Responsabilidade social e diversidade | 0,5 | Web: VLibras, A+/A−, alto contraste, teclado, skip-link, ARIA. App: leitor de tela, áreas de toque, fonte do sistema | Texto sobre combate à discriminação, diversidade e cidadania |
| 4 – Web (.NET) | 2,0 | Arquitetura, APIs REST, JWT + BCrypt, perfis Administrador/Funcionário, tela de usuários, integração entre módulos | Prints para o documento |
| 5 – Mobile | 2,0 | Telas, navegação, autenticação, sincronização (cache + fila offline), integração com a API, devolução, notas e financeiro | Testar em aparelho real e tirar os prints |
| 6 – Arquitetura (Programação Aplicada em .NET) | — | Camadas Controllers → Services → Data/Models, interfaces e injeção de dependência, `EntidadeBase` (herança/polimorfismo); app em camadas | Diagrama no documento |
| 7 – Banco de dados | 1,0 | Modelo físico (`01_criar_banco.sql` + migrations), **4 triggers e 4 procedures** (`04_procedures_triggers.sql`), endpoints da API que chamam as procedures | MER e modelo lógico desenhados no documento |
| 8 – Nuvem e DevOps | 0,5 | `Dockerfile`, `docker-compose.yml` (MySQL + API + Nginx), pipeline CI/CD `.github/workflows/ci.yml`, `/health` para monitoramento | Plano escrito (arquitetura em nuvem, escalabilidade, segurança) |
| 9 – Gerenciamento ágil | 1,0 | Quadro Kanban no Trello | Product Backlog, Sprint Backlog e cronograma no documento |
| Formatação ABNT | 1,0 | — | Documento de 20 a 30 páginas de desenvolvimento |

Os cinco itens que a Etapa 5 pede estão no app assim:

| Item do manual | Onde está |
|---|---|
| Telas principais | 10 telas: Login, Início, Produtos, Detalhe do produto, Nova venda, Clientes, Formulário de cliente, Vendas, Detalhe da venda, Minha conta |
| Fluxo de navegação | Login → barra inferior com 5 abas → telas de detalhe (Parte 12) |
| Autenticação | Mesmo login JWT da web; token em armazenamento criptografado; volta ao login quando expira |
| Sincronização de dados | Cache das consultas e fila de vendas offline, com reenvio automático e tratamento de recusa |
| Integração com APIs | Um único `ApiClient` e um repositório por recurso; nenhuma API paralela |

---

## Parte 11 – Validações do app

Toda validação do app repete uma regra que a API também aplica. O app avisa
cedo; quem decide é a API.

| Onde | Campo ou ação | Regra |
|---|---|---|
| Login | E-mail | Obrigatório, formato válido, sem espaços, até 150 caracteres |
| Login | Senha | Obrigatória |
| Login | Botão Entrar | Bloqueado durante o envio (sem envio duplo) |
| Servidor | Endereço da API | Obrigatório, começa com `http://` ou `https://`, com host; botão Testar |
| Cliente | Nome | Obrigatório, 3 a 120 caracteres, só letras |
| Cliente | CPF | 11 dígitos, dígitos verificadores, não aceita sequência repetida, máscara automática |
| Cliente | CPF duplicado | Conferido no cache antes de enviar e pela API (HTTP 409) |
| Cliente | Telefone | Opcional; DDD + 8 ou 9 dígitos; celular começa com 9; máscara automática |
| Cliente | E-mail | Opcional; formato válido; até 150 caracteres; vazio vai como `null` |
| Cliente | Endereço | Opcional; até 250 caracteres |
| Venda | Cliente | Obrigatório e ativo |
| Venda | Itens | Pelo menos 1; só produtos ativos e com estoque |
| Venda | Quantidade | De 1 até o estoque disponível; produto repetido soma no mesmo item |
| Venda | Total | Maior que zero; confirmação antes de enviar |
| Venda | Envio | Bloqueado durante o envio; estoque conferido de novo pela API |
| Sessão | Token | Expiração lida do JWT; HTTP 401 volta ao login |
| Rede | Qualquer requisição | Tempo limite de 12 s; falha vira modo offline com cache |
| Fila offline | Venda recusada | Fica visível com o motivo; reenviar ou descartar |

Os testes de unidade em `mobile/test/widget_test.dart` cobrem CPF, nome, telefone,
e-mail, endereço da API, quantidade, formatação de moeda e a leitura do JSON
da API.

---

## Parte 12 – Documentação técnica do app

### Telas e endpoints

| Tela | O que faz | Endpoint da API |
|---|---|---|
| Login | Autenticação; configuração do servidor | `POST /api/auth/login` |
| Início | Indicadores, estoque baixo, mais vendidos, vendas recentes | `GET /api/relatorios/dashboard` |
| Produtos | Catálogo com busca e filtros | `GET /api/produtos` |
| Detalhe do produto | Preço, estoque atual e mínimo, descrição | (dados da lista) |
| Nova venda | Cliente, carrinho, forma de pagamento, parcelas e confirmação | `POST /api/vendas` |
| Clientes | Lista com busca; mostrar inativos | `GET /api/clientes` |
| Formulário de cliente | Cadastro e edição | `POST /api/clientes`, `PUT /api/clientes/{id}` |
| Vendas | Histórico e fila de vendas não sincronizadas | `GET /api/vendas` |
| Detalhe da venda | Itens, pagamento, situação e devoluções | `GET /api/vendas/{id}` |
| Devolução | Quantidade por item, motivo e reembolso | `POST /api/vendas/{id}/devolucoes` |
| Financeiro (admin) | Resumo, filtros, baixa, estorno, lançamento avulso | `GET/POST /api/financeiro...` |
| Notas de entrada (admin) | Importar XML, prévia, decisão por item, confirmação | `POST /api/notas-entrada/previa`, `POST /api/notas-entrada` |
| Minha conta | Usuário, conexão, sincronização, sair | — |

### Fluxo de navegação

```
Login ──(token válido)──► Navegação inferior (5 abas)
                            ├── Início ──► Minha conta ──► Sair ──► Login
                            │         ├── Financeiro (admin) ──► Detalhe da conta
                            │         └── Notas XML (admin) ──► Prévia da nota
                            ├── Produtos ──► Detalhe do produto
                            ├── Nova venda ──► Confirmar ──► (aba Vendas)
                            ├── Clientes ──► Formulário (novo / editar)
                            └── Vendas ──► Detalhe da venda ──► Devolução
```

### Autenticação

1. O app envia `{ email, senha }` para `POST /api/auth/login`.
2. A API confere a senha com BCrypt e devolve um JWT válido por 2 horas.
3. O token é guardado com `flutter_secure_storage` (Android Keystore / iOS Keychain).
4. Toda requisição leva `Authorization: Bearer <token>`.
5. Ao abrir o app, a sessão é restaurada se o token ainda não expirou.
6. Uma resposta 401 encerra a sessão e volta ao login.

### Sincronização de dados

- **Consultas:** o app tenta a API; se conseguir, salva uma cópia no
  aparelho. Sem conexão, mostra a cópia com o aviso de quando foi atualizada.
- **Vendas sem conexão:** vão para uma fila local, e o estoque é descontado
  no cache.
- **Reenvio automático:** a cada 30 segundos, ao voltar para o app, no login
  e pelo botão "Enviar agora".
- **Conflitos:** a API confere tudo de novo. Se recusar, a venda fica como
  "Recusada", com o motivo, para reenviar ou descartar.
- **Clientes:** cadastro e edição exigem conexão, por causa do CPF único.
- **Logout:** apaga o cache, mas mantém a fila de vendas.

### Arquitetura (camadas)

```
mobile/lib/
├── main.dart                 Montagem das camadas (injeção de dependência)
├── app.dart                  MaterialApp + portão de autenticação
├── core/                     Infraestrutura compartilhada
│   ├── config/               URL padrão, tempos, chaves de armazenamento
│   ├── network/              ApiClient (HTTP + JWT + erros), status da conexão
│   ├── theme/                Identidade visual (a mesma do sistema web)
│   └── utils/                Formatação (R$, datas, CPF, telefone) e validações
├── data/                     Camada de dados
│   ├── models/               Usuario, Cliente, Produto, Venda, ItemVenda,
│   │                         VendaPendente, Dashboard
│   ├── local/                Armazenamento seguro (token) e cache (JSON)
│   └── repositories/         Um repositório por recurso da API REST
├── services/                 Regras do app e estado compartilhado (Provider)
│   ├── auth_service.dart     Sessão do usuário
│   └── sync_service.dart     Fila offline e sincronização
└── ui/                       Camada de apresentação
    ├── screens/              Telas
    └── widgets/              Componentes reutilizáveis
```

Cada camada só conhece a camada de baixo:
`Telas → Serviços → Repositórios → ApiClient / Armazenamento local → API REST`.

Pacotes: `http`, `provider`, `shared_preferences`, `flutter_secure_storage`, `file_picker` (XML da nota).

### Acessibilidade (Etapa 3)

- Rótulos de leitura de tela em ícones, botões, indicadores e no total da venda.
- Avisos de erro e de sincronização anunciados automaticamente.
- Áreas de toque de pelo menos 48 px e botões principais de 52 px.
- O app respeita o tamanho de fonte definido no celular.
- Tema escuro de alto contraste, com a identidade do sistema web.

### Limitações conhecidas

- **Envio duplicado em rede instável:** se a API gravar a venda e a resposta
  não chegar, a venda volta para a fila e pode ser reenviada. A solução é a
  API aceitar um cabeçalho `Idempotency-Key`.
- **Devolução, notas e financeiro exigem conexão:** só as vendas entram na
  fila offline.
- **HTTP sem criptografia** está liberado para o ambiente de teste. Em
  produção, a API deve ser publicada com HTTPS.
- **APK de teste:** é assinado com a chave de depuração. Para publicar na
  Play Store é preciso criar uma chave própria.

---

## Parte 13 – Módulos do PIM IV: perfis, devolução, notas e financeiro

### Perfis de acesso

| Perfil | Pode |
|---|---|
| **Administrador** | Tudo: usuários, produtos, notas de entrada, financeiro, clientes, vendas e devoluções |
| **Funcionário** | Clientes, consulta de produtos, vendas e devoluções |

- A restrição é feita na **API** (`[Authorize(Roles = "Administrador")]`): um
  funcionário recebe **403** mesmo chamando a rota direto.
- Usuários são cadastrados **só no web** (menu Usuários). Ali o admin define
  o perfil, ativa/desativa e redefine a senha.
- O sistema não deixa o administrador remover o próprio acesso nem ficar sem
  nenhum administrador ativo.

### Forma de pagamento e contas a receber

| Forma na venda | Contas a receber geradas |
|---|---|
| Dinheiro, Pix, Cartão de débito | 1 conta já **recebida** (baixada na hora) |
| Cartão de crédito, Boleto, Crediário | 1 a 12 parcelas **em aberto**, a primeira em 30 dias |
| Não informada (vendas antigas ou app antigo) | 1 conta em aberto vencendo no dia |

### Devolução de venda (web e app)

1. Detalhe da venda → **Registrar devolução**.
2. Informe quanto de cada item volta (parcial ou total) e o motivo.
3. A API:
   - devolve os produtos ao estoque;
   - abate o valor das parcelas **em aberto**, da última para a primeira;
   - se o cliente já tinha pago a parte devolvida, gera um **reembolso**
     (conta a pagar), já pago se você informar a forma, ou em aberto;
   - marca a venda como *Devolução parcial* ou *Devolvida*.
4. O dashboard passa a mostrar o faturamento **líquido** (sem o devolvido).

### Notas de entrada por XML (web e app, admin)

1. **Importar XML** e escolha o arquivo da NF-e (modelo 55). Para testar, use
   `banco\exemplos\nfe_exemplo_moveis.xml`, que é **fictício**.
2. A **prévia** não grava nada. Ela mostra fornecedor, itens e custo de cada
   item, já somando frete, seguro, IPI, ICMS-ST e outras despesas, e
   descontando o desconto.
3. Para cada item, escolha:
   - **Somar a produto existente:** a sugestão vem pelo código do fornecedor
     já vinculado, pelo código de barras (EAN) ou pelo mesmo nome;
   - **Cadastrar produto novo:** o preço é sugerido por
     custo × (1 + markup), e dá para ajustar.
4. Ao **confirmar**:
   - o fornecedor é cadastrado pelo CNPJ, se ainda não existir;
   - o estoque é somado e o **custo médio ponderado** é recalculado;
   - o vínculo código do fornecedor → produto fica salvo para as próximas notas;
   - as **contas a pagar** seguem as duplicatas da nota. Se a nota não tiver
     duplicatas, usam as parcelas e o vencimento informados.
5. A mesma nota (chave de acesso) não pode ser importada duas vezes. O XML é
   lido com DTD bloqueado, o que protege contra XXE.

### Financeiro (web e app, admin)

- Resumo: a receber, a pagar, vencidos, recebido e pago no mês, saldo previsto.
- Filtros por tipo, situação (em aberto, vencidas, pagas, canceladas),
  período de vencimento e busca.
- **Baixar:** forma de pagamento, data (não pode ser futura) e valor pago
  (pode ter juros ou desconto).
- **Estornar:** desfaz a baixa, com motivo obrigatório.
- **Lançar conta avulsa:** aluguel, energia etc., em até 24 parcelas.
  Só essas contas podem ser canceladas.
- Cada conta tem **histórico** (criada, baixada, estornada, ajustada por
  devolução), com data e usuário.

### Novas tabelas (migration `ModulosFinanceiroNotasDevolucao`)

`Fornecedores`, `ProdutosFornecedores`, `NotasEntrada`, `ItensNotaEntrada`,
`Devolucoes`, `ItensDevolucao`, `ContasFinanceiras` e
`HistoricoContasFinanceiras`.

Novas colunas:
- `Vendas`: `FormaPagamento`, `Parcelas`, `ValorDevolvido` e `Status`;
- `ItensVenda`: `QuantidadeDevolvida`;
- `Produtos`: `CustoMedio` e `CodigoBarras`.

A API aplica as migrations pendentes sozinha ao iniciar. O script SQL
completo, gerado pelo EF, está em `banco\03_script_completo_ef.sql`.

---

## Parte 14 – Procedures e triggers (Etapa 7)

Criadas pela migration `20261104120000_ProceduresETriggers` (a API aplica
sozinha ao iniciar). O mesmo código, para estudar ou rodar no MySQL
Workbench, está em `banco\04_procedures_triggers.sql`.

| Objeto | Tipo | O que faz |
|---|---|---|
| `trg_produtos_valida_estoque_insert` | Trigger BEFORE INSERT | Bloqueia produto com estoque negativo |
| `trg_produtos_valida_estoque_update` | Trigger BEFORE UPDATE | Bloqueia venda/ajuste que deixaria o estoque negativo |
| `trg_produtos_auditoria_estoque` | Trigger AFTER UPDATE | Grava cada mudança de estoque em `MovimentacoesEstoque` (ENTRADA/SAÍDA) |
| `trg_contas_valida_valor` | Trigger BEFORE INSERT | Impede conta financeira com valor zero ou negativo |
| `sp_resumo_vendas_periodo(inicio, fim)` | Procedure | Quantidade, faturamento bruto e líquido, devoluções e ticket médio |
| `sp_produtos_estoque_baixo()` | Procedure | Produtos no estoque mínimo ou abaixo |
| `sp_movimentacoes_estoque(produto, limite)` | Procedure | Histórico gravado pela trigger de auditoria |
| `sp_contas_vencidas()` | Procedure | Contas em aberto já vencidas, com dias de atraso |

Endpoints da API que chamam as procedures (precisam de login):

- `GET /api/relatorios/banco/resumo-vendas?inicio=2026-01-01&fim=2026-12-31`
- `GET /api/relatorios/banco/estoque-baixo`
- `GET /api/relatorios/banco/movimentacoes-estoque?produtoId=0&limite=50`
- `GET /api/relatorios/banco/contas-vencidas`

---

## Parte 15 – Docker e CI/CD (Etapa 8)

- `backend\SmartMoveis.API\Dockerfile`: imagem da API em duas etapas (SDK → runtime).
- `docker-compose.yml`: sobe **MySQL 8 + API + Nginx** (sistema web) com um comando.
  1. Copie `.env.exemplo` para `.env` e troque a senha e a chave JWT.
  2. Feche o `2_iniciar_api` e o `6_iniciar_web` (usam as mesmas portas).
  3. `docker compose up -d --build` → web em http://localhost:5500, API em http://localhost:5071.
- `.github\workflows\ci.yml`: a cada push compila a API, analisa e testa o app,
  gera o APK; na branch `main` publica a imagem da API no GitHub Container Registry.
- `GET /health`: responde `Healthy` quando a API alcança o MySQL (usado pelo
  healthcheck do Docker e por qualquer monitor de nuvem).
- Em nuvem, a configuração vem de variáveis de ambiente:
  `ConnectionStrings__DefaultConnection`, `Jwt__Key`, `Cors__Origens__0`.

---

## Parte 16 – Testes, backup e evidências (pasta `ferramentas`)

| Dois cliques em | O que faz | Resultado |
|---|---|---|
| `ferramentas\testar_banco_limpo.cmd` | Cria um banco vazio temporário, roda os scripts 01 e 02, sobe uma API de teste na porta 5072 (aplica migrations, triggers e procedures), testa tudo e apaga o banco de teste. Também gera `banco\05_modelo_logico.md` | `logs\resultado_banco_limpo.txt` |
| `ferramentas\testar_app.cmd` | `flutter analyze` + `flutter test` (os mesmos passos do CI) | `logs\resultado_app.txt` |
| `ferramentas\backup_banco.cmd` | Backup completo (dados, triggers e procedures) em `backups\`, mantém os 7 mais recentes | `backups\smartmoveis_AAAAMMDD_HHMM.sql` |
| `ferramentas\restaurar_backup.cmd` | Restaura o backup mais recente (pede para digitar SIM) | — |

Os scripts usam a conexão gravada pelo `1_preparar_banco` (user-secrets): nenhuma senha é digitada de novo nem gravada em arquivo.

Páginas de evidência (abra com o `6_iniciar_web` rodando e logado no sistema):

- http://localhost:5500/evidencias/api.html – chama a API e mostra status e JSON de cada endpoint (procedures, trigger, 401, 400)
- http://localhost:5500/evidencias/responsivo.html – as telas em largura de celular e tablet, com verificação de rolagem horizontal
- http://localhost:5500/evidencias/resultados.html – resultado dos testes automatizados
- Prints usados no Trello e no documento: `frontend\evidencias\*.jpg`

