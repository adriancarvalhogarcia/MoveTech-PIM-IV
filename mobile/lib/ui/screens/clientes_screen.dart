import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/conexao_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../data/models/cliente.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/repositories/dados_carregados.dart';
import '../widgets/componentes.dart';
import 'cliente_form_screen.dart';

/// Clientes: GET /api/clientes (+ cadastro e edição no formulário).
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _busca = TextEditingController();
  DadosCarregados<List<Cliente>>? _dados;
  String? _erro;
  bool _carregando = true;
  bool _mostrarInativos = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = _dados == null;
      _erro = null;
    });
    try {
      final dados = await context.read<ClienteRepository>().listar();
      if (mounted) setState(() => _dados = dados);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Cliente> get _filtrados {
    final termo = _busca.text.trim().toLowerCase();
    final termoDigitos = Formatadores.somenteDigitos(termo);
    return (_dados?.dados ?? const <Cliente>[]).where((c) {
      if (!_mostrarInativos && !c.ativo) return false;
      if (termo.isEmpty) return true;
      return c.nome.toLowerCase().contains(termo) ||
          (c.email ?? '').toLowerCase().contains(termo) ||
          (termoDigitos.isNotEmpty &&
              Formatadores.somenteDigitos(c.cpf).contains(termoDigitos));
    }).toList();
  }

  Future<void> _abrirFormulario([Cliente? cliente]) async {
    if (!context.read<ConexaoStatus>().online) {
      // Tenta mesmo assim: o status pode estar desatualizado.
      mostrarMensagem(
        context,
        'Sem conexão no momento. O cadastro precisa do servidor para validar o CPF.',
        erro: true,
      );
    }
    final salvo = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: cliente)),
    );
    if (salvo == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: _mostrarInativos ? 'Ocultar inativos' : 'Mostrar inativos',
            icon: Icon(_mostrarInativos
                ? Icons.person_off_rounded
                : Icons.person_off_outlined),
            onPressed: () => setState(() => _mostrarInativos = !_mostrarInativos),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo cliente'),
      ),
      body: Column(
        children: [
          const BannerSincronizacao(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: CampoBusca(
              controller: _busca,
              dica: 'Buscar por nome, CPF ou e-mail',
              aoMudar: (_) => setState(() {}),
            ),
          ),
          if (_dados?.doCache == true) AvisoCache(atualizadoEm: _dados!.atualizadoEm),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_dados == null) {
      return EstadoErro(mensagem: _erro ?? 'Erro desconhecido.', aoTentar: _carregar);
    }

    final clientes = _filtrados;
    if (clientes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          children: const [
            SizedBox(height: 60),
            EstadoVazio(
              icone: Icons.people_outline_rounded,
              titulo: 'Nenhum cliente encontrado',
              mensagem: 'Cadastre um novo cliente pelo botão abaixo.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96, top: 4),
        itemCount: clientes.length,
        separatorBuilder: (_, __) => const Divider(indent: 16, endIndent: 16),
        itemBuilder: (context, i) {
          final c = clientes[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: c.ativo ? Cores.verde.withAlpha(40) : Cores.superficie2,
              foregroundColor: c.ativo ? Cores.verde : Cores.textoSecundario,
              child: Text(c.nome.isEmpty ? '?' : c.nome[0].toUpperCase()),
            ),
            title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              [
                'CPF ${Formatadores.cpf(c.cpf)}',
                if ((c.telefone ?? '').isNotEmpty) c.telefone!,
              ].join(' · '),
            ),
            trailing: c.ativo
                ? const Icon(Icons.chevron_right_rounded)
                : const Selo('Inativo', cor: Cores.textoSecundario),
            onTap: () => _abrirFormulario(c),
          );
        },
      ),
    );
  }
}
