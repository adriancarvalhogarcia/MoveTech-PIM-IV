# MoveTech - Modelo logico do banco smartmoveis

Gerado por ferramentas\testar_banco_limpo.ps1 em 04/11/2026 14:40 a partir de um banco criado do zero (scripts 01/02 + migrations).
PK = chave primaria, FK = chave estrangeira, UNI/MUL = indice.

## clientes

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| Nome | varchar(120) | NO |  |  |
| CPF | varchar(14) | NO | UNI |  |
| Telefone | varchar(20) | YES |  |  |
| Email | varchar(150) | YES |  |  |
| Endereco | varchar(250) | YES |  |  |
| Ativo | tinyint(1) | NO |  |  |
| CriadoEm | datetime(6) | NO |  |  |

## contasfinanceiras

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| Tipo | varchar(10) | NO | MUL |  |
| Descricao | varchar(150) | NO |  |  |
| Origem | varchar(20) | NO |  |  |
| VendaId | int | YES | FK | vendas.Id |
| NotaEntradaId | int | YES | FK | notasentrada.Id |
| DevolucaoId | int | YES | FK | devolucoes.Id |
| ClienteId | int | YES | FK | clientes.Id |
| FornecedorId | int | YES | FK | fornecedores.Id |
| NumeroParcela | int | NO |  |  |
| TotalParcelas | int | NO |  |  |
| Valor | decimal(12,2) | NO |  |  |
| Vencimento | date | NO |  |  |
| Status | varchar(12) | NO |  |  |
| DataPagamento | date | YES |  |  |
| ValorPago | decimal(12,2) | YES |  |  |
| FormaPagamento | varchar(30) | YES |  |  |
| Observacao | varchar(250) | YES |  |  |
| CriadoEm | datetime(6) | NO |  |  |

## devolucoes

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| VendaId | int | NO | FK | vendas.Id |
| Motivo | varchar(250) | NO |  |  |
| ValorTotal | decimal(10,2) | NO |  |  |
| UsuarioNome | varchar(100) | YES |  |  |
| CriadoEm | datetime(6) | NO |  |  |

## fornecedores

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| RazaoSocial | varchar(150) | NO |  |  |
| NomeFantasia | varchar(150) | YES |  |  |
| Documento | varchar(14) | NO | UNI |  |
| Ativo | tinyint(1) | NO |  |  |
| CriadoEm | datetime(6) | NO |  |  |

## historicocontasfinanceiras

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| ContaFinanceiraId | int | NO | FK | contasfinanceiras.Id |
| Acao | varchar(20) | NO |  |  |
| Detalhe | varchar(250) | YES |  |  |
| UsuarioNome | varchar(100) | YES |  |  |
| CriadoEm | datetime(6) | NO |  |  |

## itensdevolucao

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| DevolucaoId | int | NO | FK | devolucoes.Id |
| ItemVendaId | int | NO | FK | itensvenda.Id |
| ProdutoId | int | NO | FK | produtos.Id |
| Quantidade | int | NO |  |  |
| PrecoUnitario | decimal(10,2) | NO |  |  |
| Subtotal | decimal(10,2) | NO |  |  |

## itensnotaentrada

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| NotaEntradaId | int | NO | FK | notasentrada.Id |
| ProdutoId | int | NO | FK | produtos.Id |
| CodigoFornecedor | varchar(60) | NO |  |  |
| Descricao | varchar(150) | NO |  |  |
| Quantidade | int | NO |  |  |
| CustoUnitario | decimal(12,4) | NO |  |  |
| CustoTotal | decimal(12,2) | NO |  |  |
| ProdutoCriado | tinyint(1) | NO |  |  |

## itensvenda

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| VendaId | int | NO | FK | vendas.Id |
| ProdutoId | int | NO | FK | produtos.Id |
| Quantidade | int | NO |  |  |
| PrecoUnitario | decimal(10,2) | NO |  |  |
| Subtotal | decimal(10,2) | NO |  |  |
| QuantidadeDevolvida | int | NO |  |  |

## movimentacoesestoque

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| ProdutoId | int | NO | FK | produtos.Id |
| QuantidadeAnterior | int | NO |  |  |
| QuantidadeNova | int | NO |  |  |
| Diferenca | int | NO |  |  |
| Tipo | varchar(10) | NO |  |  |
| CriadoEm | datetime | NO |  |  |

## notasentrada

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| FornecedorId | int | NO | FK | fornecedores.Id |
| Numero | varchar(20) | NO |  |  |
| Serie | varchar(5) | NO |  |  |
| ChaveAcesso | varchar(44) | NO | UNI |  |
| DataEmissao | datetime(6) | NO |  |  |
| ValorProdutos | decimal(12,2) | NO |  |  |
| ValorTotal | decimal(12,2) | NO |  |  |
| MarkupPercentual | decimal(6,2) | NO |  |  |
| UsuarioNome | varchar(100) | YES |  |  |
| CriadoEm | datetime(6) | NO |  |  |

## produtos

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| Nome | varchar(120) | NO |  |  |
| Descricao | varchar(500) | YES |  |  |
| Categoria | varchar(100) | NO |  |  |
| Preco | decimal(10,2) | NO |  |  |
| QuantidadeEstoque | int | NO |  |  |
| EstoqueMinimo | int | NO |  |  |
| Ativo | tinyint(1) | NO |  |  |
| CriadoEm | datetime(6) | NO |  |  |
| CodigoBarras | varchar(14) | YES | MUL |  |
| CustoMedio | decimal(12,4) | NO |  |  |

## produtosfornecedores

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| FornecedorId | int | NO | FK | fornecedores.Id |
| CodigoFornecedor | varchar(60) | NO |  |  |
| ProdutoId | int | NO | FK | produtos.Id |

## usuarios

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| Nome | varchar(100) | NO |  |  |
| Email | varchar(150) | NO | UNI |  |
| SenhaHash | varchar(255) | NO |  |  |
| Perfil | varchar(30) | NO |  |  |
| Ativo | tinyint(1) | NO |  |  |
| CriadoEm | datetime(6) | NO |  |  |

## vendas

| Coluna | Tipo | Nulo | Chave | Referencia |
|---|---|---|---|---|
| Id | int | NO | PK |  |
| ClienteId | int | NO | FK | clientes.Id |
| ValorTotal | decimal(10,2) | NO |  |  |
| CriadoEm | datetime(6) | NO |  |  |
| FormaPagamento | varchar(30) | NO |  |  |
| Parcelas | int | NO |  |  |
| Status | varchar(20) | NO |  |  |
| ValorDevolvido | decimal(10,2) | NO |  |  |
