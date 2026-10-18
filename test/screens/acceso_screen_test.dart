import 'package:budget_zlate/app.dart';
import 'package:budget_zlate/data/autenticacion.dart';
import 'package:budget_zlate/data/gastos_repository_memoria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoyo/autenticacion_falsa.dart';

void main() {
  late AutenticacionFalsa autenticacion;

  setUp(() => autenticacion = AutenticacionFalsa());

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(
      BudgetZlateApp(
        repository: GastosRepositoryMemoria.conEjemplos(),
        autenticacion: autenticacion,
        mesInicial: DateTime(2026, 10), // mes de los gastos de ejemplo
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

  Future<void> escribirDatosValidos(WidgetTester tester) async {
    await tester.enterText(campo('Correo'), 'ana@ejemplo.com');
    await tester.enterText(campo('Contraseña'), 'secreta123');
  }

  Future<void> pulsar(WidgetTester tester, String boton) async {
    await tester.tap(find.text(boton));
    await tester.pumpAndSettle();
  }

  testWidgets('sin sesión muestra el acceso y no los gastos', (tester) async {
    await abrirApp(tester);

    expect(find.text('Inicia sesión para ver tus gastos'), findsOneWidget);
    expect(find.text('Supermercado'), findsNothing);
  });

  testWidgets('con sesión guardada abre directamente la lista', (tester) async {
    autenticacion.haySesion = true;
    await abrirApp(tester);

    expect(find.text('Supermercado'), findsOneWidget);
  });

  testWidgets('campos vacíos muestran errores y no llaman a Supabase', (
    tester,
  ) async {
    await abrirApp(tester);

    await pulsar(tester, 'Iniciar sesión');

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(autenticacion.llamadas, 0);
  });

  testWidgets('correo inválido y contraseña corta muestran errores', (
    tester,
  ) async {
    await abrirApp(tester);

    await tester.enterText(campo('Correo'), 'ana@');
    await tester.enterText(campo('Contraseña'), '123');
    await pulsar(tester, 'Crear cuenta');

    expect(find.text('Correo no válido'), findsOneWidget);
    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    expect(autenticacion.llamadas, 0);
  });

  testWidgets('iniciar sesión muestra la lista de gastos', (tester) async {
    await abrirApp(tester);

    await escribirDatosValidos(tester);
    await pulsar(tester, 'Iniciar sesión');

    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('un error de Supabase se muestra en español', (tester) async {
    autenticacion.error = const ErrorAutenticacion(
      'Correo o contraseña incorrectos',
    );
    await abrirApp(tester);

    await escribirDatosValidos(tester);
    await pulsar(tester, 'Iniciar sesión');

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    expect(find.text('Supermercado'), findsNothing);
  });

  testWidgets('crear cuenta que requiere confirmación pide revisar el correo', (
    tester,
  ) async {
    await abrirApp(tester);

    await escribirDatosValidos(tester);
    await pulsar(tester, 'Crear cuenta');

    expect(find.textContaining('Te enviamos un correo a'), findsOneWidget);
    expect(find.text('Supermercado'), findsNothing);
  });

  testWidgets('cerrar sesión vuelve a la pantalla de acceso', (tester) async {
    autenticacion.haySesion = true;
    await abrirApp(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión para ver tus gastos'), findsOneWidget);
    expect(autenticacion.haySesion, isFalse);
  });

  testWidgets('el botón del ojo muestra y oculta la contraseña', (
    tester,
  ) async {
    await abrirApp(tester);
    bool oculta() => tester
        .widget<TextField>(
          find.descendant(
            of: campo('Contraseña'),
            matching: find.byType(TextField),
          ),
        )
        .obscureText;

    expect(oculta(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(oculta(), isFalse);
  });
}
