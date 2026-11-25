import 'package:flutter/material.dart';

/// Identidade visual do MoveTech, a mesma da aplicação web
/// (frontend/movetech.css): fundo escuro esverdeado e destaque verde.
class Cores {
  Cores._();

  static const verde = Color(0xFF32E05F);
  static const verdeEscuro = Color(0xFF021006);
  static const fundo = Color(0xFF020704);
  static const superficie = Color(0xFF0B120D);
  static const superficie2 = Color(0xFF0E1710);
  static const borda = Color(0xFF1B2A1E);
  static const texto = Color(0xFFF5F7F5);
  static const textoSecundario = Color(0xFFA5AEA7);
  static const alerta = Color(0xFFFFC857);
  static const erro = Color(0xFFFF6262);
}

class AppTheme {
  AppTheme._();

  static ThemeData get escuro {
    const esquema = ColorScheme.dark(
      primary: Cores.verde,
      onPrimary: Cores.verdeEscuro,
      secondary: Cores.verde,
      onSecondary: Cores.verdeEscuro,
      surface: Cores.superficie,
      onSurface: Cores.texto,
      error: Cores.erro,
      onError: Colors.black,
      outline: Cores.borda,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Cores.fundo,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Cores.fundo,
        foregroundColor: Cores.texto,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Cores.texto,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Cores.superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Cores.borda),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Cores.superficie2,
        labelStyle: const TextStyle(color: Cores.textoSecundario),
        hintStyle: const TextStyle(color: Cores.textoSecundario),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Cores.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Cores.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Cores.verde, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: Cores.borda),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Cores.superficie,
        indicatorColor: Cores.verde.withAlpha(46),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Cores.borda, space: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Cores.superficie2,
        contentTextStyle: TextStyle(color: Cores.texto),
      ),
    );
  }
}
