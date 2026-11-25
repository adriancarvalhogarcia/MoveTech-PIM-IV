// Testes de unidade das regras que não dependem da API.
// Executar com: flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:movetech_mobile/core/utils/formatadores.dart';
import 'package:movetech_mobile/core/utils/pagamento.dart';
import 'package:movetech_mobile/core/utils/validadores.dart';
import 'package:movetech_mobile/data/models/cliente.dart';
import 'package:movetech_mobile/data/models/dashboard.dart';
import 'package:movetech_mobile/data/models/produto.dart';
import 'package:movetech_mobile/data/models/venda.dart';
import 'package:movetech_mobile/data/models/venda_pendente.dart';

void main() {
  group('Formatadores', () {
    test('moeda no padrão brasileiro', () {
      expect(Formatadores.moeda(0), 'R\$ 0,00');
      expect(Formatadores.moeda(1234.5), 'R\$ 1.234,50');
      expect(Formatadores.moeda(1234567.891), 'R\$ 1.234.567,89');
    });

    test('CPF formatado', () {
      expect(Formatadores.cpf('52998224725'), '529.982.247-25');
    });

    test('data da API sem fuso é tratada como UTC', () {
      final data = Formatadores.lerDataApi('2026-08-22T17:06:49.123');
      expect(data, isNotNull);
      expect(data!.toUtc().hour, 17);
    });
  });

  group('Validadores', () {
    test('CPF válido e inválido', () {
      expect(Validadores.cpf('529.982.247-25'), isNull);
      expect(Validadores.cpf('111.111.111-11'), isNotNull);
      expect(Validadores.cpf('529.982.247-26'), isNotNull);
      expect(Validadores.cpf('123'), isNotNull);
    });

    test('nome de pessoa', () {
      expect(Validadores.nomePessoa('Ana Souza'), isNull);
      expect(Validadores.nomePessoa("João D'Ávila-Silva"), isNull);
      expect(Validadores.nomePessoa(''), isNotNull);
      expect(Validadores.nomePessoa('Al'), isNotNull);
      expect(Validadores.nomePessoa('Ana 123'), isNotNull);
    });

    test('telefone opcional, com DDD', () {
      expect(Validadores.telefone(''), isNull);
      expect(Validadores.telefone('(11) 98765-4321'), isNull);
      expect(Validadores.telefone('(11) 3333-4444'), isNull);
      expect(Validadores.telefone('98765-4321'), isNotNull);
      expect(Validadores.telefone('(11) 88765-4321'), isNotNull);
      expect(Formatadores.telefone('11987654321'), '(11) 98765-4321');
      expect(Formatadores.telefone('1133334444'), '(11) 3333-4444');
      expect(Formatadores.telefone('5511987654321'), '(11) 98765-4321');
    });

    test('endereço da API', () {
      expect(Validadores.urlApi('http://192.168.0.10:5071/api'), isNull);
      expect(Validadores.urlApi('https://api.movetech.com.br/api'), isNull);
      expect(Validadores.urlApi(''), isNotNull);
      expect(Validadores.urlApi('192.168.0.10:5071'), isNotNull);
      expect(Validadores.urlApi('ftp://servidor/api'), isNotNull);
    });

    test('quantidade limitada ao estoque', () {
      expect(Validadores.quantidade(1, 5), isNull);
      expect(Validadores.quantidade(5, 5), isNull);
      expect(Validadores.quantidade(0, 5), isNotNull);
      expect(Validadores.quantidade(6, 5), isNotNull);
    });

    test('preço e quantidades do cadastro de produto', () {
      expect(Validadores.preco(1999.9), isNull);
      expect(Validadores.preco(0), isNotNull);
      expect(Validadores.preco(null), isNotNull);
      expect(Validadores.inteiroNaoNegativo('0', campo: 'O estoque'), isNull);
      expect(Validadores.inteiroNaoNegativo('', campo: 'O estoque'), isNotNull);
      expect(Validadores.inteiroNaoNegativo('-1', campo: 'O estoque'), isNotNull);
    });

    test('e-mail opcional aceita vazio', () {
      expect(Validadores.email('', obrigatorio: false), isNull);
      expect(Validadores.email('a@b.com'), isNull);
      expect(Validadores.email('invalido'), isNotNull);
    });
  });

  group('Modelos x JSON da API', () {
    test('Produto e regra de estoque baixo', () {
      final p = Produto.fromJson({
        'id': 3,
        'nome': 'Sofá 3 lugares',
        'categoria': 'Sala',
        'preco': 2499.9,
        'quantidadeEstoque': 2,
        'estoqueMinimo': 3,
        'ativo': true,
      });
      expect(p.estoqueBaixo, isTrue);
      expect(p.disponivelParaVenda, isTrue);
    });

    test('Produto gera o corpo do CriarProdutoDto', () {
      final corpo = Produto.corpoRequisicao(
        nome: ' Poltrona ',
        descricao: '',
        categoria: 'Sala',
        preco: 899.999,
        quantidadeEstoque: 4,
        estoqueMinimo: 1,
      );
      expect(corpo['nome'], 'Poltrona');
      expect(corpo['descricao'], isNull);
      expect(corpo['preco'], 900.0);
      expect(corpo.containsKey('ativo'), isFalse);
    });

    test('Cliente envia campos vazios como null', () {
      final corpo = Cliente.corpoRequisicao(
        nome: ' Ana ',
        cpf: '52998224725',
        email: '',
      );
      expect(corpo['nome'], 'Ana');
      expect(corpo['cpf'], '529.982.247-25');
      expect(corpo['email'], isNull);
      expect(corpo.containsKey('ativo'), isFalse);
    });

    test('Venda do GET (cliente objeto) e do POST (cliente texto)', () {
      final get = Venda.fromJson({
        'id': 10,
        'clienteId': 1,
        'cliente': {'id': 1, 'nome': 'Ana'},
        'valorTotal': 300,
        'criadoEm': '2026-09-01T12:00:00',
        'itens': [
          {
            'id': 1,
            'produtoId': 3,
            'produto': {'id': 3, 'nome': 'Mesa'},
            'quantidade': 2,
            'precoUnitario': 150,
            'subtotal': 300,
          }
        ],
      });
      expect(get.clienteNome, 'Ana');
      expect(get.itens.single.produtoNome, 'Mesa');

      final post = Venda.fromJson({
        'id': 11,
        'clienteId': 1,
        'cliente': 'Ana',
        'valorTotal': 150,
        'itens': [
          {'produtoId': 3, 'quantidade': 1, 'precoUnitario': 150, 'subtotal': 150}
        ],
      });
      expect(post.clienteNome, 'Ana');
      expect(post.quantidadeItens, 1);
    });

    test('Venda pendente gera o corpo do CriarVendaDto', () {
      final v = VendaPendente(
        idLocal: 'local-1',
        clienteId: 7,
        clienteNome: 'Ana',
        criadoEm: DateTime(2026, 9, 28),
        itens: const [
          ItemVenda(
            produtoId: 3,
            produtoNome: 'Mesa',
            quantidade: 2,
            precoUnitario: 150,
            subtotal: 300,
          ),
        ],
      );
      // PIM IV: a venda agora também envia as parcelas (padrão 1).
      expect(v.corpoApi(), {
        'clienteId': 7,
        'itens': [
          {'produtoId': 3, 'quantidade': 2}
        ],
        'parcelas': 1,
      });
      final copia = VendaPendente.fromJson(v.toJson());
      expect(copia.valorEstimado, 300);
      expect(copia.status, StatusPendente.aguardando);
    });

    test('Dashboard', () {
      final d = Dashboard.fromJson({
        'resumo': {
          'totalClientesAtivos': 4,
          'totalProdutosAtivos': 10,
          'totalProdutosEstoqueBaixo': 1,
          'totalVendas': 2,
          'faturamentoTotal': 500.5,
          'ticketMedio': 250.25,
        },
        'produtosEstoqueBaixo': [
          {'id': 1, 'nome': 'Cadeira', 'quantidadeEstoque': 0, 'estoqueMinimo': 2}
        ],
        'produtosMaisVendidos': [],
        'vendasRecentes': [
          {
            'id': 2,
            'cliente': {'id': 1, 'nome': 'Ana'},
            'valorTotal': 200,
            'criadoEm': '2026-09-01T10:00:00',
          }
        ],
      });
      expect(d.totalVendas, 2);
      expect(d.estoqueBaixo.single.nome, 'Cadeira');
      expect(d.vendasRecentes.single.cliente, 'Ana');
    });
  });

  group('Forma de pagamento (PIM IV)', () {
    test('à vista não parcela', () {
      expect(FormasPagamento.permiteParcelar('Pix'), isFalse);
      expect(FormasPagamento.permiteParcelar('Dinheiro'), isFalse);
      expect(FormasPagamento.permiteParcelar('CartaoDebito'), isFalse);
    });

    test('crédito, boleto e crediário parcelam', () {
      expect(FormasPagamento.permiteParcelar('CartaoCredito'), isTrue);
      expect(FormasPagamento.permiteParcelar('Boleto'), isTrue);
      expect(FormasPagamento.permiteParcelar('Crediario'), isTrue);
    });

    test('nome amigável', () {
      expect(FormasPagamento.nome('CartaoCredito'), 'Cartão de crédito');
      expect(FormasPagamento.nome(null), '-');
    });
  });
}
