import 'package:flutter/foundation.dart';

/// Guarda se a última comunicação com a API funcionou.
///
/// Em vez de depender de um plugin de conectividade, o app considera
/// "online" quando o próprio servidor responde. Isso cobre também os
/// casos em que existe Wi-Fi, mas a API está desligada ou inacessível.
class ConexaoStatus extends ChangeNotifier {
  bool _online = true;
  DateTime? _ultimaFalha;

  bool get online => _online;
  DateTime? get ultimaFalha => _ultimaFalha;

  void registrarSucesso() {
    if (!_online) {
      _online = true;
      notifyListeners();
    }
  }

  void registrarFalha() {
    _ultimaFalha = DateTime.now();
    if (_online) {
      _online = false;
      notifyListeners();
    }
  }
}
