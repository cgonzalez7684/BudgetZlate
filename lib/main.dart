import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'data/autenticacion_supabase.dart';
import 'data/gastos_repository_supabase.dart';

Future<void> main() async {
  // Necesario antes de usar plugins (Supabase guarda la sesión con uno)
  // cuando main hace trabajo asíncrono antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final problema = problemaDeConfiguracion();
  if (problema != null) {
    runApp(_ConfiguracionIncorrecta(problema));
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(
    BudgetZlateApp(
      repository: GastosRepositorySupabase(Supabase.instance.client),
      autenticacion: AutenticacionSupabase(Supabase.instance.client.auth),
    ),
  );
}

/// Se muestra si falta `--dart-define-from-file` o sus valores están mal.
class _ConfiguracionIncorrecta extends StatelessWidget {
  const _ConfiguracionIncorrecta(this.problema);

  final String problema;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$problema\n\n'
              'Revisa config/supabase.json y ejecuta la app con:\n'
              'flutter run --dart-define-from-file=config/supabase.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
