import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/conexao_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../services/sync_service.dart';

/// Faixa exibida no topo das telas quando o app está sem conexão com a
/// API ou quando existem vendas aguardando sincronização.
class BannerSincronizacao extends StatelessWidget {
  const BannerSincronizacao({super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConexaoStatus>().online;
    final sync = context.watch<SyncService>();
    final aguardando = sync.totalAguardando;
    final rejeitadas = sync.totalRejeitadas;

    if (online && aguardando == 0 && rejeitadas == 0) {
      return const SizedBox.shrink();
    }

    final String texto;
    final IconData icone;
    final Color cor;

    if (!online) {
      icone = Icons.cloud_off_rounded;
      cor = Cores.alerta;
      texto = aguardando > 0
          ? 'Sem conexão · $aguardando venda(s) aguardando envio'
          : 'Sem conexão · mostrando dados salvos no aparelho';
    } else if (aguardando > 0) {
      icone = Icons.cloud_upload_rounded;
      cor = Cores.alerta;
      texto = sync.sincronizando
          ? 'Sincronizando vendas...'
          : '$aguardando venda(s) aguardando envio · toque para sincronizar';
    } else {
      icone = Icons.error_outline_rounded;
      cor = Cores.erro;
      texto = '$rejeitadas venda(s) recusada(s) pelo servidor · veja em Vendas';
    }

    return Semantics(
      liveRegion: true,
      button: true,
      label: texto,
      child: Material(
        color: cor.withAlpha(36),
        child: InkWell(
          onTap: sync.sincronizando ? null : () => sync.sincronizar(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (sync.sincronizando)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cor),
                  )
                else
                  Icon(icone, color: cor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(texto, style: TextStyle(color: cor, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de que a lista veio do cache local.
class AvisoCache extends StatelessWidget {
  const AvisoCache({super.key, required this.atualizadoEm});

  final DateTime? atualizadoEm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 16, color: Cores.textoSecundario),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Dados salvos no aparelho, atualizados ${Formatadores.tempoRelativo(atualizadoEm)}',
              style: const TextStyle(color: Cores.textoSecundario, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String? mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: Cores.textoSecundario),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (mensagem != null) ...[
              const SizedBox(height: 6),
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Cores.textoSecundario),
              ),
            ],
            if (acao != null) ...[const SizedBox(height: 16), acao!],
          ],
        ),
      ),
    );
  }
}

/// Erro com botão "Tentar novamente".
class EstadoErro extends StatelessWidget {
  const EstadoErro({super.key, required this.mensagem, required this.aoTentar});

  final String mensagem;
  final VoidCallback aoTentar;

  @override
  Widget build(BuildContext context) {
    return EstadoVazio(
      icone: Icons.wifi_off_rounded,
      titulo: 'Não foi possível carregar',
      mensagem: mensagem,
      acao: OutlinedButton.icon(
        onPressed: aoTentar,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Tentar novamente'),
      ),
    );
  }
}

class CampoBusca extends StatelessWidget {
  const CampoBusca({
    super.key,
    required this.controller,
    required this.dica,
    required this.aoMudar,
  });

  final TextEditingController controller;
  final String dica;
  final ValueChanged<String> aoMudar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: aoMudar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: dica,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  aoMudar('');
                },
              ),
        isDense: true,
      ),
    );
  }
}

/// Selo colorido (estoque baixo, inativo, pendente...).
class Selo extends StatelessWidget {
  const Selo(this.texto, {super.key, this.cor = Cores.verde, this.icone});

  final String texto;
  final Color cor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 13, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class CartaoIndicador extends StatelessWidget {
  const CartaoIndicador({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    this.cor = Cores.verde,
  });

  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$titulo: $valor',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor, size: 22),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Cores.textoSecundario, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.acao});

  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                texto,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

/// Mensagens rápidas padronizadas.
void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? const Color(0xFF3A1414) : null,
      ),
    );
}
