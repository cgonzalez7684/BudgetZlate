import 'package:flutter/material.dart';

import 'data/gastos_repository.dart';
import 'screens/lista_gastos_screen.dart';

/// Widget raíz: configura el tema y la pantalla inicial.
///
/// Recibe el repositorio por constructor para que las pruebas puedan usar
/// sus propios datos.
class BudgetZlateApp extends StatelessWidget {
  const BudgetZlateApp({super.key, required this.repository});

  final GastosRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetZlate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: ListaGastosScreen(repository: repository),
    );
  }
}
