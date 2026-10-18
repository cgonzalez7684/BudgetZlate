import 'package:budget_zlate/data/gastos_repository_memoria.dart';
import 'package:budget_zlate/models/categoria.dart';
import 'package:budget_zlate/models/gasto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoyo/autenticacion_falsa.dart';
import '../apoyo/gastos_repository_que_falla.dart';

/// Mes fijo para que las pruebas no dependan de la fecha de hoy.
final octubre = DateTime(2026, 10);

/// Busca solo dentro de la lista de gastos (no en el resumen).
Finder enLista(Finder finder) =>
    find.descendant(of: find.byType(ListView), matching: finder);

/// Busca solo dentro de la tarjeta de resumen.
Finder enResumen(Finder finder) =>
    find.descendant(of: find.byKey(const Key('resumen')), matching: finder);

Gasto gasto(
  String id,
  String descripcion,
  int centimos,
  Categoria categoria,
  DateTime fecha,
) => Gasto(
  id: id,
  descripcion: descripcion,
  montoCentimos: centimos,
  categoria: categoria,
  fecha: fecha,
);

void main() {
  testWidgets('muestra el título y los datos de cada gasto', (tester) async {
    final repository = GastosRepositoryMemoria([
      // ₡1 250,50: incluye céntimos
      gasto(
        '1',
        'Almuerzo',
        125050,
        Categoria.alimentacion,
        DateTime(2026, 10, 5),
      ),
      gasto('2', 'Taxi', 300000, Categoria.transporte, DateTime(2026, 10, 3)),
    ]);

    await tester.pumpWidget(appConSesion(repository, mes: octubre));
    await tester.pumpAndSettle(); // espera a que termine el Future

    expect(find.text('BudgetZlate'), findsOneWidget);

    expect(enLista(find.text('Almuerzo')), findsOneWidget);
    expect(enLista(find.text('Alimentación · 05/10/2026')), findsOneWidget);
    expect(enLista(find.text('₡1 250,50')), findsOneWidget);

    expect(enLista(find.text('Taxi')), findsOneWidget);
    expect(enLista(find.text('Transporte · 03/10/2026')), findsOneWidget);
    expect(enLista(find.text('₡3 000,00')), findsOneWidget);
  });

  testWidgets('sin gastos en el mes muestra un mensaje', (tester) async {
    await tester.pumpWidget(
      appConSesion(GastosRepositoryMemoria(), mes: octubre),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay gastos en octubre 2026'), findsOneWidget);
  });

  testWidgets('los gastos de ejemplo se ven en su mes', (tester) async {
    await tester.pumpWidget(
      appConSesion(GastosRepositoryMemoria.conEjemplos(), mes: octubre),
    );
    await tester.pumpAndSettle();

    expect(enLista(find.text('Supermercado')), findsOneWidget);
    expect(enLista(find.text('₡23 500,75')), findsOneWidget);
  });

  group('mes y resumen', () {
    late GastosRepositoryMemoria repository;

    setUp(() {
      repository = GastosRepositoryMemoria([
        gasto(
          '1',
          'Primer día',
          100000,
          Categoria.alimentacion,
          DateTime(2026, 10, 1),
        ),
        gasto(
          '2',
          'Último día',
          50050,
          Categoria.transporte,
          DateTime(2026, 10, 31),
        ),
        gasto(
          '3',
          'Otro súper',
          25000,
          Categoria.alimentacion,
          DateTime(2026, 10, 15),
        ),
        gasto(
          '4',
          'Septiembre',
          70000,
          Categoria.servicios,
          DateTime(2026, 9, 30),
        ),
        gasto('5', 'Noviembre', 9900, Categoria.otros, DateTime(2026, 11, 1)),
      ]);
    });

    Future<void> abrirApp(WidgetTester tester, {DateTime? mes}) async {
      await tester.pumpWidget(appConSesion(repository, mes: mes ?? octubre));
      await tester.pumpAndSettle();
    }

    String montoEnResumen(WidgetTester tester, String etiqueta) {
      // La fila del resumen es un Row: [Expanded(Text(etiqueta)), Text(monto)].
      final fila = find.ancestor(
        of: enResumen(find.text(etiqueta)),
        matching: find.byType(Row),
      );
      final textos = tester
          .widgetList<Text>(
            find.descendant(of: fila.first, matching: find.byType(Text)),
          )
          .map((t) => t.data)
          .toList();
      return textos.last!;
    }

    testWidgets('solo muestra los gastos del mes, incluidos el día 1 y el 31', (
      tester,
    ) async {
      await abrirApp(tester);

      expect(find.text('octubre 2026'), findsOneWidget);
      expect(enLista(find.text('Primer día')), findsOneWidget);
      expect(enLista(find.text('Último día')), findsOneWidget);
      expect(enLista(find.text('Otro súper')), findsOneWidget);
      expect(find.text('Septiembre'), findsNothing);
      expect(find.text('Noviembre'), findsNothing);
    });

    testWidgets(
      'el resumen muestra el total y cada categoría (también ₡0,00)',
      (tester) async {
        await abrirApp(tester);

        expect(montoEnResumen(tester, 'Total del mes'), '₡1 750,50');
        expect(montoEnResumen(tester, 'Alimentación'), '₡1 250,00');
        expect(montoEnResumen(tester, 'Transporte'), '₡500,50');
        expect(montoEnResumen(tester, 'Servicios'), '₡0,00');
        expect(montoEnResumen(tester, 'Otros'), '₡0,00');
      },
    );

    testWidgets('cambiar de mes cambia la lista y los totales', (tester) async {
      await abrirApp(tester);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();

      expect(find.text('septiembre 2026'), findsOneWidget);
      expect(enLista(find.text('Septiembre')), findsOneWidget);
      expect(find.text('Primer día'), findsNothing);
      expect(montoEnResumen(tester, 'Total del mes'), '₡700,00');
      expect(montoEnResumen(tester, 'Servicios'), '₡700,00');
      expect(montoEnResumen(tester, 'Alimentación'), '₡0,00');

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('octubre 2026'), findsOneWidget);
      expect(montoEnResumen(tester, 'Total del mes'), '₡1 750,50');
    });

    testWidgets('en el mes actual no se puede avanzar a meses futuros', (
      tester,
    ) async {
      final hoy = DateTime.now();
      await abrirApp(tester, mes: DateTime(hoy.year, hoy.month));

      final siguiente = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(siguiente.onPressed, isNull);
    });

    testWidgets('al editar la fecha a otro mes, la lista salta a ese mes', (
      tester,
    ) async {
      await abrirApp(tester);

      await tester.tap(find.text('Otro súper'));
      await tester.pumpAndSettle();
      // Selector de fecha: ir a septiembre y elegir el día 20.
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('septiembre 2026'), findsOneWidget);
      expect(enLista(find.text('Otro súper')), findsOneWidget);
      expect(enLista(find.text('Alimentación · 20/09/2026')), findsOneWidget);
    });
  });

  group('editar y eliminar', () {
    late GastosRepositoryMemoria repository;

    // Se ejecuta antes de cada prueba del grupo: cada una parte de cero.
    setUp(() {
      repository = GastosRepositoryMemoria([
        gasto(
          '1',
          'Almuerzo',
          125050,
          Categoria.alimentacion,
          DateTime(2026, 10, 5),
        ),
        gasto('2', 'Taxi', 300000, Categoria.transporte, DateTime(2026, 10, 3)),
      ]);
    });

    Future<void> abrirApp(WidgetTester tester) async {
      await tester.pumpWidget(appConSesion(repository, mes: octubre));
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

      // La lista queda detrás (fuera de escena): estos textos son del formulario.
      expect(find.text('Editar gasto'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
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
      expect(enLista(find.text('Almuerzo de trabajo')), findsOneWidget);
      expect(enLista(find.text('₡4 000,00')), findsOneWidget);
      expect(enLista(find.text('Taxi')), findsOneWidget);

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
      expect(enLista(find.text('Almuerzo')), findsOneWidget);
      expect(await repository.obtenerGastos(), hasLength(1));
    });

    testWidgets('cancelar la eliminación conserva el gasto', (tester) async {
      await abrirApp(tester);

      await deslizarParaEliminar(tester, 'Taxi');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar gasto?'), findsNothing);
      expect(enLista(find.text('Taxi')), findsOneWidget);
      expect(await repository.obtenerGastos(), hasLength(2));
    });

    testWidgets('eliminar desde "Editar gasto" vuelve a la lista sin él', (
      tester,
    ) async {
      await abrirApp(tester);
      await tester.tap(find.text('Taxi'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Eliminar gasto'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar gasto?'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar gasto'), findsNothing); // volvió a la lista
      expect(find.text('Taxi'), findsNothing);
      expect(find.text('Se eliminó "Taxi"'), findsOneWidget); // SnackBar
      expect(enLista(find.text('Almuerzo')), findsOneWidget);
      expect(await repository.obtenerGastos(), hasLength(1));
    });

    testWidgets('cancelar en "Editar gasto" se queda en el formulario', (
      tester,
    ) async {
      await abrirApp(tester);
      await tester.tap(find.text('Taxi'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Eliminar gasto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar gasto'), findsOneWidget);
      expect(await repository.obtenerGastos(), hasLength(2));
    });
  });

  group('errores de conexión', () {
    late GastosRepositoryQueFalla repository;

    setUp(() {
      repository = GastosRepositoryQueFalla([
        gasto(
          '1',
          'Almuerzo',
          125050,
          Categoria.alimentacion,
          DateTime(2026, 10, 5),
        ),
      ]);
    });

    Future<void> abrirApp(WidgetTester tester) async {
      await tester.pumpWidget(appConSesion(repository, mes: octubre));
      await tester.pumpAndSettle();
    }

    testWidgets('si falla la carga, avisa y permite reintentar', (
      tester,
    ) async {
      repository.fallarAlCargar = true;
      await abrirApp(tester);

      expect(find.textContaining('No se pudieron cargar'), findsOneWidget);
      expect(find.text('Almuerzo'), findsNothing);

      repository.fallarAlCargar = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(enLista(find.text('Almuerzo')), findsOneWidget);
    });

    testWidgets('si falla eliminar, avisa y el gasto sigue en la lista', (
      tester,
    ) async {
      await abrirApp(tester);

      repository.fallarAlGuardar = true;
      await tester.drag(find.text('Almuerzo'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo eliminar'), findsOneWidget);
      expect(enLista(find.text('Almuerzo')), findsOneWidget);
    });

    testWidgets('si falla guardar una edición, avisa y no cambia nada', (
      tester,
    ) async {
      await abrirApp(tester);

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
      expect(enLista(find.text('Almuerzo')), findsOneWidget);
      expect(find.text('Cena'), findsNothing);
    });
  });
}
