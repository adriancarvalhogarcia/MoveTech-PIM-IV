import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../core/utils/pagamento.dart';
import '../../data/models/conta_financeira.dart';
import '../../data/repositories/financeiro_repository.dart';
import '../widgets/componentes.dart';

/// Financeiro (somente administrador): contas a pagar e a receber.
/// Resumo, filtros, baixa com forma de pagamento, estorno, cancelamento
/// de lançamento avulso e histórico. Precisa de conexão.
class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  String? _tipo; // null = todas
  String? _status = 'Aberta';
  final _busca = TextEditingController();
  Timer? _debounce;

  ResumoFinanceiro? _resumo;
  List<ContaFinanceira> _contas = [];
  bool _carregando = true;
  String? _erro;

  static const _filtrosStatus = <String?, String>{
    'Aberta': 'Em aberto',
    'Vencida': 'Vencidas',
    'Paga': 'Pagas',
    'Cancelada': 'Canceladas',
    null: 'Todas',
  };

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = _resumo == null;
      _erro = null;
    });
    final repo = context.read<FinanceiroRepository>();
    try {
      final resultados = await Future.wait([
        repo.resumo(),
        repo.listar(tipo: _tipo, status: _status, busca: _busca.text),
      ]);
      if (!mounted) return;
      setState(() {
        _resumo = resultados[0] as ResumoFinanceiro;
        _contas = resultados[1] as List<ContaFinanceira>;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrir(ContaFinanceira conta) async {
    final mudou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ContaDetalheScreen(conta: conta)),
    );
    if (mudou == true) _carregar();
  }

  Future<void> _novaConta() async {
    final lancou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FormNovaConta(),
    );
    if (lancou == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaConta,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lançar conta'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _resumo == null
              ? EstadoErro(mensagem: _erro ?? 'Erro ao carregar.', aoTentar: _carregar)
              : RefreshIndicator(onRefresh: _carregar, child: _lista()),
    );
  }

  Widget _lista() {
    final r = _resumo!;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              CartaoIndicador(
                titulo: 'A receber',
                valor: Formatadores.moeda(r.aReceber),
                icone: Icons.south_west_rounded,
              ),
              CartaoIndicador(
                titulo: 'A pagar',
                valor: Formatadores.moeda(r.aPagar),
                icone: Icons.north_east_rounded,
                cor: Cores.erro,
              ),
              CartaoIndicador(
                titulo: 'Recebido no mês',
                valor: Formatadores.moeda(r.recebidoMes),
                icone: Icons.savings_rounded,
              ),
              CartaoIndicador(
                titulo: 'Saldo previsto',
                valor: Formatadores.moeda(r.saldoPrevisto),
                icone: Icons.account_balance_wallet_rounded,
                cor: r.saldoPrevisto >= 0 ? Cores.verde : Cores.erro,
              ),
            ],
          ),
        ),
        if (r.receberVencido > 0 || r.pagarVencido > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Vencido: ${Formatadores.moeda(r.receberVencido)} a receber · '
              '${Formatadores.moeda(r.pagarVencido)} a pagar',
              style: const TextStyle(color: Cores.alerta),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: SegmentedButton<String?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Todas')),
              ButtonSegment(value: 'Receber', label: Text('Receber')),
              ButtonSegment(value: 'Pagar', label: Text('Pagar')),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) {
              setState(() => _tipo = s.first);
              _carregar();
            },
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            children: [
              for (final f in _filtrosStatus.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.value),
                    selected: _status == f.key,
                    onSelected: (_) {
                      setState(() => _status = f.key);
                      _carregar();
                    },
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: CampoBusca(
            controller: _busca,
            dica: 'Descrição, cliente ou fornecedor',
            aoMudar: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), _carregar);
            },
          ),
        ),
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_erro!, style: const TextStyle(color: Cores.erro)),
          ),
        if (_contas.isEmpty)
          const EstadoVazio(
            icone: Icons.account_balance_wallet_outlined,
            titulo: 'Nenhuma conta com estes filtros',
          )
        else
          for (final c in _contas) _ItemConta(conta: c, aoTocar: () => _abrir(c)),
      ],
    );
  }
}

Color _corSituacao(ContaFinanceira c) {
  if (c.paga) return Cores.verde;
  if (c.cancelada) return Cores.textoSecundario;
  if (c.vencida) return Cores.erro;
  return Colors.lightBlueAccent;
}

class _ItemConta extends StatelessWidget {
  const _ItemConta({required this.conta, required this.aoTocar});

  final ContaFinanceira conta;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = conta;
    return ListTile(
      onTap: aoTocar,
      leading: CircleAvatar(
        backgroundColor: (c.receber ? Cores.verde : Cores.erro).withAlpha(40),
        foregroundColor: c.receber ? Cores.verde : Cores.erro,
        child: Icon(c.receber ? Icons.south_west_rounded : Icons.north_east_rounded, size: 20),
      ),
      title: Text(c.descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        'Vence ${Formatadores.dataSimples(c.vencimento)}'
        '${c.parte != null ? ' · ${c.parte}' : ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Formatadores.moeda(c.valor), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Selo(c.situacao, cor: _corSituacao(c)),
        ],
      ),
    );
  }
}

// =================================================================
// DETALHE DA CONTA
// =================================================================

class ContaDetalheScreen extends StatefulWidget {
  const ContaDetalheScreen({super.key, required this.conta});

  final ContaFinanceira conta;

  @override
  State<ContaDetalheScreen> createState() => _ContaDetalheScreenState();
}

class _ContaDetalheScreenState extends State<ContaDetalheScreen> {
  List<HistoricoConta>? _historico;
  bool _processando = false;

  ContaFinanceira get c => widget.conta;

  @override
  void initState() {
    super.initState();
    context.read<FinanceiroRepository>().historico(c.id).then((h) {
      if (mounted) setState(() => _historico = h);
    }).catchError((_) {
      if (mounted) setState(() => _historico = const []);
    });
  }

  Future<void> _executar(Future<String> Function() acao) async {
    setState(() => _processando = true);
    try {
      final mensagem = await acao();
      if (!mounted) return;
      mostrarMensagem(context, mensagem);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } on SemConexaoException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _baixar() async {
    final dados = await showModalBottomSheet<_DadosBaixa>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormBaixa(conta: c),
    );
    if (dados == null || !mounted) return;
    final repo = context.read<FinanceiroRepository>();
    await _executar(() => repo.baixar(
          c.id,
          formaPagamento: dados.forma,
          data: dados.data,
          valorPago: dados.valor,
          observacao: dados.observacao,
        ));
  }

  Future<void> _pedirMotivo({required bool estorno}) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoMotivo(
        titulo: estorno ? 'Estornar baixa' : 'Cancelar conta',
        texto: estorno
            ? 'A conta volta a ficar em aberto. Baixa atual: '
                '${FormasPagamento.nome(c.formaPagamento)} de '
                '${Formatadores.moeda(c.valorPago)} em ${Formatadores.dataSimples(c.dataPagamento)}.'
            : 'A conta "${c.descricao}" será cancelada.',
        acao: estorno ? 'Estornar' : 'Cancelar conta',
      ),
    );
    if (motivo == null || !mounted) return;
    final repo = context.read<FinanceiroRepository>();
    await _executar(() => estorno ? repo.estornar(c.id, motivo) : repo.cancelar(c.id, motivo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(c.receber ? 'Conta a receber' : 'Conta a pagar')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (c.aberta && c.manual) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processando ? null : () => _pedirMotivo(estorno: false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (c.aberta)
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _processando ? null : _baixar,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(c.receber ? 'Registrar recebimento' : 'Registrar pagamento'),
                  ),
                ),
              if (c.paga)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Cores.erro),
                    onPressed: _processando ? null : () => _pedirMotivo(estorno: true),
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Estornar baixa'),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.descricao,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                      Selo(c.situacao, cor: _corSituacao(c)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    Formatadores.moeda(c.valor),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: c.receber ? Cores.verde : Cores.erro,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _info('Vencimento', Formatadores.dataSimples(c.vencimento)),
                  _info('Origem', c.origemExibicao),
                  if (c.parte != null) _info(c.receber ? 'Cliente' : 'Favorecido', c.parte!),
                  if (c.totalParcelas > 1) _info('Parcela', '${c.numeroParcela} de ${c.totalParcelas}'),
                  if (c.paga) ...[
                    _info('Pago em', Formatadores.dataSimples(c.dataPagamento)),
                    _info('Forma', FormasPagamento.nome(c.formaPagamento)),
                    _info('Valor pago', Formatadores.moeda(c.valorPago)),
                  ],
                  if (c.observacao != null && c.observacao!.isNotEmpty) _info('Observação', c.observacao!),
                ],
              ),
            ),
          ),
          const TituloSecao('Histórico'),
          if (_historico == null)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else
            Card(
              child: Column(
                children: [
                  for (final h in _historico!)
                    ListTile(
                      leading: const Icon(Icons.history_rounded, color: Cores.verde),
                      title: Text(h.acao),
                      subtitle: Text(
                        '${Formatadores.dataHora(h.criadoEm)}'
                        '${h.usuarioNome != null ? ' · ${h.usuarioNome}' : ''}'
                        '${h.detalhe != null ? '\n${h.detalhe}' : ''}',
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _info(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(rotulo, style: const TextStyle(color: Cores.textoSecundario)),
            ),
            Expanded(child: Text(valor)),
          ],
        ),
      );
}

// =================================================================
// FORMULÁRIOS
// =================================================================

class _DadosBaixa {
  const _DadosBaixa(this.forma, this.data, this.valor, this.observacao);

  final String forma;
  final DateTime data;
  final double valor;
  final String? observacao;
}

/// Aceita "1.234,56", "1234,56" e "1234.56".
double? _lerValor(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return null;
  return t.contains(',')
      ? double.tryParse(t.replaceAll('.', '').replaceAll(',', '.'))
      : double.tryParse(t);
}

class _FormBaixa extends StatefulWidget {
  const _FormBaixa({required this.conta});

  final ContaFinanceira conta;

  @override
  State<_FormBaixa> createState() => _FormBaixaState();
}

class _FormBaixaState extends State<_FormBaixa> {
  final _form = GlobalKey<FormState>();
  late final _valor = TextEditingController(
    text: widget.conta.valor.toStringAsFixed(2).replaceAll('.', ','),
  );
  final _obs = TextEditingController();
  String? _forma;
  DateTime _data = DateTime.now();

  @override
  void dispose() {
    _valor.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(hoje.year - 2),
      lastDate: hoje,
      helpText: 'Data do pagamento',
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  void _confirmar() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      _DadosBaixa(_forma!, _data, _lerValor(_valor.text)!, _obs.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.conta.receber ? 'Registrar recebimento' : 'Registrar pagamento',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _forma,
              decoration: const InputDecoration(labelText: 'Como foi pago'),
              items: [
                for (final f in FormasPagamento.baixa)
                  DropdownMenuItem(value: f, child: Text(FormasPagamento.nome(f))),
              ],
              validator: (v) => v == null ? 'Escolha a forma de pagamento.' : null,
              onChanged: (v) => setState(() => _forma = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _escolherData,
              icon: const Icon(Icons.event_rounded),
              label: Text('Data: ${Formatadores.dataSimples(_data)}'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                labelText: 'Valor pago (R\$)',
                helperText: 'Altere se houve juros, multa ou desconto.',
              ),
              validator: (v) {
                final valor = _lerValor(v ?? '');
                if (valor == null || valor <= 0) return 'Informe um valor maior que zero.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _obs,
              maxLength: 250,
              decoration: const InputDecoration(labelText: 'Observação (opcional)'),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _confirmar, child: const Text('Confirmar baixa')),
          ],
        ),
      ),
    );
  }
}

class _DialogoMotivo extends StatefulWidget {
  const _DialogoMotivo({required this.titulo, required this.texto, required this.acao});

  final String titulo;
  final String texto;
  final String acao;

  @override
  State<_DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<_DialogoMotivo> {
  final _motivo = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.texto),
          const SizedBox(height: 12),
          TextField(
            controller: _motivo,
            maxLength: 250,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Motivo', errorText: _erro),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar')),
        FilledButton(
          onPressed: () {
            if (_motivo.text.trim().length < 3) {
              setState(() => _erro = 'Descreva o motivo (mínimo de 3 caracteres).');
              return;
            }
            Navigator.pop(context, _motivo.text.trim());
          },
          child: Text(widget.acao),
        ),
      ],
    );
  }
}

class _FormNovaConta extends StatefulWidget {
  const _FormNovaConta();

  @override
  State<_FormNovaConta> createState() => _FormNovaContaState();
}

class _FormNovaContaState extends State<_FormNovaConta> {
  final _form = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  String _tipo = 'Pagar';
  int _parcelas = 1;
  DateTime _vencimento = DateTime.now();
  bool _enviando = false;

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate() || _enviando) return;
    setState(() => _enviando = true);
    try {
      final msg = await context.read<FinanceiroRepository>().lancar(
            tipo: _tipo,
            descricao: _descricao.text,
            valor: _lerValor(_valor.text)!,
            vencimento: _vencimento,
            parcelas: _parcelas,
          );
      if (!mounted) return;
      mostrarMensagem(context, msg);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } on SemConexaoException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Lançar conta avulsa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Pagar', label: Text('A pagar')),
                  ButtonSegment(value: 'Receber', label: Text('A receber')),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricao,
                maxLength: 140,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Descrição', hintText: 'Ex.: Aluguel da loja'),
                validator: (v) => (v ?? '').trim().length < 3 ? 'Informe a descrição.' : null,
              ),
              TextFormField(
                controller: _valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(labelText: 'Valor total (R\$)'),
                validator: (v) {
                  final valor = _lerValor(v ?? '');
                  if (valor == null || valor <= 0) return 'Informe um valor maior que zero.';
                  if (valor / _parcelas < 0.01) return 'Valor muito baixo para tantas parcelas.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _parcelas,
                decoration: const InputDecoration(labelText: 'Parcelas mensais'),
                items: [for (var n = 1; n <= 24; n++) DropdownMenuItem(value: n, child: Text('${n}x'))],
                onChanged: (v) => setState(() => _parcelas = v ?? 1),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final hoje = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _vencimento,
                    firstDate: DateTime(hoje.year - 1),
                    lastDate: DateTime(hoje.year + 5),
                    helpText: 'Primeiro vencimento',
                  );
                  if (d != null) setState(() => _vencimento = d);
                },
                icon: const Icon(Icons.event_rounded),
                label: Text('Vencimento: ${Formatadores.dataSimples(_vencimento)}'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _enviando ? null : _salvar,
                child: _enviando
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Lançar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
