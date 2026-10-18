import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/autenticacion.dart';
import 'data/gastos_repository.dart';
import 'screens/acceso_screen.dart';
import 'screens/lista_gastos_screen.dart';

/// Widget raíz: configura el tema y la pantalla inicial.
///
/// Recibe el repositorio y la autenticación por constructor para que las
/// pruebas puedan usar versiones falsas sin red.
class BudgetZlateApp extends StatelessWidget {
  const BudgetZlateApp({
    super.key,
    required this.repository,
    required this.autenticacion,
  });

  final GastosRepository repository;
  final Autenticacion autenticacion;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetZlate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      // Textos de Material (selector de fecha, "Cancelar", ...) en español,
      // aunque el teléfono esté configurado en otro idioma.
      locale: const Locale('es', 'CR'),
      supportedLocales: const [Locale('es', 'CR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: PuertaAcceso(repository: repository, autenticacion: autenticacion),
    );
  }
}

/// Muestra la pantalla de acceso o la lista de gastos según haya sesión.
///
/// `StreamBuilder` se reconstruye cada vez que el stream emite: al iniciar o
/// cerrar sesión, cambia de pantalla sin que nadie tenga que navegar.
class PuertaAcceso extends StatelessWidget {
  const PuertaAcceso({
    super.key,
    required this.repository,
    required this.autenticacion,
  });

  final GastosRepository repository;
  final Autenticacion autenticacion;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: autenticacion.cambiosDeSesion,
      // Mientras el stream no emita, se usa el estado actual (p. ej. la
      // sesión guardada de la última vez).
      initialData: autenticacion.haySesion,
      builder: (context, snapshot) {
        if (snapshot.data ?? false) {
          return ListaGastosScreen(
            repository: repository,
            onCerrarSesion: autenticacion.cerrarSesion,
          );
        }
        return AccesoScreen(autenticacion: autenticacion);
      },
    );
  }
}
