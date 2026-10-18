import 'package:budget_zlate/data/gastos_repository_memoria.dart';
import 'package:budget_zlate/models/categoria.dart';
import 'package:budget_zlate/utils/formato_fecha.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoyo/autenticacion_falsa.dart';

/// Abre la app con un repositorio vacío y pulsa el botón de agregar.
Future<void> _abrirFormulario(WidgetTester tester) async {
  await tester.pumpWidget(appConSesion(GastosRepositoryMemoria()));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Agregar gasto'));
  await tester.pumpAndSettle();
}

Finder _campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

Future<void> _elegirCategoria(WidgetTester tester, Categoria categoria) async {
  await tester.tap(find.byType(DropdownButtonFormField<Categoria>));
  await tester.pumpAndSettle();
  // El menú abierto muestra las opciones; .last es la del menú, no la del campo.
  await tester.tap(find.text(categoria.etiqueta).last);
  await tester.pumpAndSettle();
}

Future<void> _guardar(WidgetTester tester) async {
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el botón flotante abre el formulario con la fecha de hoy', (
    tester,
  ) async {
    await _abrirFormulario(tester);

    expect(find.text('Nuevo gasto'), findsOneWidget);
    expect(find.text(formatearFecha(DateTime.now())), findsOneWidget);
  });

  testWidgets('guardar con campos vacíos muestra los errores', (tester) async {
    await _abrirFormulario(tester);

    await _guardar(tester);

    expect(find.text('Ingresa una descripción'), findsOneWidget);
    expect(find.text('Ingresa un monto'), findsOneWidget);
    expect(find.text('Elige una categoría'), findsOneWidget);
    expect(find.text('Nuevo gasto'), findsOneWidget); // no se cerró
  });

  for (final (texto, error) in [
    ('0', 'El monto debe ser mayor que cero'),
    ('-5', 'El monto debe ser mayor que cero'),
    ('abc', 'Ingresa un monto válido'),
    ('12,345', 'Usa como máximo 2 decimales'),
  ]) {
    testWidgets('el monto "$texto" muestra "$error"', (tester) async {
      await _abrirFormulario(tester);

      await tester.enterText(_campo('Monto'), texto);
      await _guardar(tester);

      expect(find.text(error), findsOneWidget);
    });
  }

  testWidgets('un gasto válido vuelve a la lista y aparece', (tester) async {
    await _abrirFormulario(tester);

    await tester.enterText(_campo('Descripción'), 'Taxi al aeropuerto');
    await tester.enterText(_campo('Monto'), '8500,5');
    await _elegirCategoria(tester, Categoria.transporte);
    await _guardar(tester);

    expect(find.text('Nuevo gasto'), findsNothing); // volvió a la lista
    expect(find.text('Taxi al aeropuerto'), findsOneWidget);
    expect(find.text('₡8 500,50'), findsOneWidget);
    expect(
      find.text('Transporte · ${formatearFecha(DateTime.now())}'),
      findsOneWidget,
    );
  });

  testWidgets('volver sin guardar no agrega nada', (tester) async {
    await _abrirFormulario(tester);

    await tester.enterText(_campo('Descripción'), 'No se guarda');
    await tester.binding.handlePopRoute(); // botón "atrás" de Android
    await tester.pumpAndSettle();

    expect(find.text('No hay gastos registrados'), findsOneWidget);
  });

  testWidgets('el selector de fecha aparece en español', (tester) async {
    await _abrirFormulario(tester);

    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona una fecha'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
