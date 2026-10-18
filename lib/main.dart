import 'package:flutter/material.dart';

import 'app.dart';
import 'data/gastos_repository_memoria.dart';

void main() {
  runApp(BudgetZlateApp(repository: GastosRepositoryMemoria.conEjemplos()));
}
