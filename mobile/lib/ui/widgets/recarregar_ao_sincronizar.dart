import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../services/sync_service.dart';

/// Faz a tela recarregar seus dados sempre que o SyncService avisar
/// que algo mudou no servidor (venda registrada ou fila sincronizada).
mixin RecarregarAoSincronizar<T extends StatefulWidget> on State<T> {
  int? _versaoConhecida;

  /// Implementado pela tela: busca os dados novamente.
  Future<void> recarregar();

  /// Chamar no início do build().
  void observarSincronizacao(BuildContext context) {
    final versao = context.select<SyncService, int>((s) => s.versaoDados);
    if (_versaoConhecida == null) {
      _versaoConhecida = versao;
      return;
    }
    if (versao != _versaoConhecida) {
      _versaoConhecida = versao;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) recarregar();
      });
    }
  }
}
