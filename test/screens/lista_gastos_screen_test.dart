import 'package:budget_zlate/app.dart';
import 'package:budget_zlate/data/gastos_repository_memoria.dart';
import 'package:budget_zlate/models/categoria.dart';
import 'package:budget_zlate/models/gasto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el título y los datos de cada gasto', (tester) async {
    final repository = GastosRepositoryMemoria([
      Gasto(
        id: '1',
        descripcion: 'Almuerzo',
        montoCentimos: 125050, // ₡1 250,50: incluye céntimos
        categoria: Categoria.alimentacion,
        fecha: DateTime(2026, 10, 5),
      ),
      Gasto(
        id: '2',
        descripcion: 'Taxi',
        montoCentimos: 300000,
        categoria: Categoria.transporte,
        fecha: DateTime(2026, 9, 30),
      ),
    ]);

    await tester.pumpWidget(BudgetZlateApp(repository: repository));
    await tester.pumpAndSettle(); // espera a que termine el Future

    expect(find.text('BudgetZlate'), findsOneWidget);

    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Alimentación · 05/10/2026'), findsOneWidget);
    expect(find.text('₡1 250,50'), findsOneWidget);

    expect(find.text('Taxi'), findsOneWidget);
    expect(find.text('Transporte · 30/09/2026'), findsOneWidget);
    expect(find.text('₡3 000,00'), findsOneWidget);
  });

  testWidgets('sin gastos muestra un mensaje', (tester) async {
    await tester.pumpWidget(
      BudgetZlateApp(repository: GastosRepositoryMemoria()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay gastos registrados'), findsOneWidget);
  });

  testWidgets('la app abre con los gastos de ejemplo', (tester) async {
    await tester.pumpWidget(
      BudgetZlateApp(repository: GastosRepositoryMemoria.conEjemplos()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('₡23 500,75'), findsOneWidget);
  });
}
