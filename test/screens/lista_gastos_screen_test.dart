import 'package:budget_zlate/data/gastos_repository_memoria.dart';
import 'package:budget_zlate/models/categoria.dart';
import 'package:budget_zlate/models/gasto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoyo/autenticacion_falsa.dart';
import '../apoyo/gastos_repository_que_falla.dart';

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

    await tester.pumpWidget(appConSesion(repository));
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
    await tester.pumpWidget(appConSesion(GastosRepositoryMemoria()));
    await tester.pumpAndSettle();

    expect(find.text('No hay gastos registrados'), findsOneWidget);
  });

  testWidgets('la app abre con los gastos de ejemplo', (tester) async {
    await tester.pumpWidget(
      appConSesion(GastosRepositoryMemoria.conEjemplos()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('₡23 500,75'), findsOneWidget);
  });

  group('editar y eliminar', () {
    late GastosRepositoryMemoria repository;

    // Se ejecuta antes de cada prueba del grupo: cada una parte de cero.
    setUp(() {
      repository = GastosRepositoryMemoria([
        Gasto(
          id: '1',
          descripcion: 'Almuerzo',
          montoCentimos: 125050,
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
    });

    Future<void> abrirApp(WidgetTester tester) async {
      await tester.pumpWidget(appConSesion(repository));
      await tester.pumpAndSettle();
    }

    Future<void> deslizarParaEliminar(WidgetTester tester, String texto) async {
      await tester.drag(find.text(texto), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('tocar un gasto abre el formulario con sus datos', (
      tester,
    ) async {
      await abrirApp(tester);

      await tester.tap(find.text('Almuerzo'));
      await tester.pumpAndSettle();

      expect(find.text('Editar gasto'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget); // en el campo
      expect(find.text('1250,50'), findsOneWidget);
      expect(find.text('Alimentación'), findsOneWidget);
      expect(find.text('05/10/2026'), findsOneWidget);
    });

    testWidgets('editar cambia el gasto en la lista y conserva el id', (
      tester,
    ) async {
      await abrirApp(tester);

      await tester.tap(find.text('Almuerzo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Almuerzo'),
        'Almuerzo de trabajo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '1250,50'),
        '4000',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Almuerzo'), findsNothing);
      expect(find.text('Almuerzo de trabajo'), findsOneWidget);
      expect(find.text('₡4 000,00'), findsOneWidget);
      expect(find.text('Taxi'), findsOneWidget);

      final gastos = await repository.obtenerGastos();
      expect(gastos, hasLength(2));
      expect(gastos.firstWhere((g) => g.id == '1').montoCentimos, 400000);
    });

    testWidgets('eliminar con confirmación quita el gasto y avisa', (
      tester,
    ) async {
      await abrirApp(tester);

      await deslizarParaEliminar(tester, 'Taxi');
      expect(find.text('¿Eliminar gasto?'), findsOneWidget);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Taxi'), findsNothing);
      expect(find.text('Se eliminó "Taxi"'), findsOneWidget); // SnackBar
      expect(find.text('Almuerzo'), findsOneWidget);
      expect(await repository.obtenerGastos(), hasLength(1));
    });

    testWidgets('cancelar la eliminación conserva el gasto', (tester) async {
      await abrirApp(tester);

      await deslizarParaEliminar(tester, 'Taxi');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar gasto?'), findsNothing);
      expect(find.text('Taxi'), findsOneWidget);
      expect(await repository.obtenerGastos(), hasLength(2));
    });
  });

  group('errores de conexión', () {
    late GastosRepositoryQueFalla repository;

    setUp(() {
      repository = GastosRepositoryQueFalla([
        Gasto(
          id: '1',
          descripcion: 'Almuerzo',
          montoCentimos: 125050,
          categoria: Categoria.alimentacion,
          fecha: DateTime(2026, 10, 5),
        ),
      ]);
    });

    testWidgets('si falla la carga, avisa y permite reintentar', (
      tester,
    ) async {
      repository.fallarAlCargar = true;
      await tester.pumpWidget(appConSesion(repository));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudieron cargar'), findsOneWidget);
      expect(find.text('Almuerzo'), findsNothing);

      repository.fallarAlCargar = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Almuerzo'), findsOneWidget);
    });

    testWidgets('si falla eliminar, avisa y el gasto sigue en la lista', (
      tester,
    ) async {
      await tester.pumpWidget(appConSesion(repository));
      await tester.pumpAndSettle();

      repository.fallarAlGuardar = true;
      await tester.drag(find.text('Almuerzo'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo eliminar'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
    });

    testWidgets('si falla guardar una edición, avisa y no cambia nada', (
      tester,
    ) async {
      await tester.pumpWidget(appConSesion(repository));
      await tester.pumpAndSettle();

      repository.fallarAlGuardar = true;
      await tester.tap(find.text('Almuerzo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Almuerzo'),
        'Cena',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo guardar'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
      expect(find.text('Cena'), findsNothing);
    });
  });
}
