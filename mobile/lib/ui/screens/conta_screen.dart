import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/conexao_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../data/local/armazenamento_local.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';

/// Dados do usuário, situação da sincronização e logout.
class ContaScreen extends StatelessWidget {
  const ContaScreen({super.key});

  Future<void> _sair(BuildContext context) async {
    final sync = context.read<SyncService>();
    final auth = context.read<AuthService>();
    final pendentes = sync.totalAguardando + sync.totalRejeitadas;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do aplicativo?'),
        content: Text(
          pendentes > 0
              ? 'Existem $pendentes venda(s) ainda não sincronizada(s). Elas '
                  'continuam guardadas no aparelho e serão enviadas no próximo login.'
              : 'Você precisará informar e-mail e senha novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar == true) await auth.sair();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuario;
    final sync = context.watch<SyncService>();
    final online = context.watch<ConexaoStatus>().online;
    final url = context.read<ArmazenamentoLocal>().urlApi;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Cores.verde,
                foregroundColor: Cores.verdeEscuro,
                child: Text(
                  usuario?.iniciais ?? '?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario?.nome ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    Text(usuario?.email ?? '',
                        style: const TextStyle(color: Cores.textoSecundario)),
                    const SizedBox(height: 4),
                    Text('Perfil: ${usuario?.perfilExibicao ?? '-'}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: online ? Cores.verde : Cores.alerta,
                  ),
                  title: Text(online ? 'Conectado ao servidor' : 'Sem conexão'),
                  subtitle: Text(url),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: Text('${sync.totalAguardando} venda(s) aguardando envio'),
                  subtitle: Text(
                    sync.totalRejeitadas > 0
                        ? '${sync.totalRejeitadas} recusada(s) · veja em Vendas'
                        : 'Última sincronização: '
                            '${Formatadores.tempoRelativo(sync.ultimaSincronizacao)}',
                  ),
                  trailing: sync.sincronizando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : IconButton(
                          tooltip: 'Sincronizar agora',
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: sync.sincronizar,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Cores.erro,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _sair(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair'),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'MoveTech Mobile · versão 1.3.0',
              style: TextStyle(color: Cores.textoSecundario, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
