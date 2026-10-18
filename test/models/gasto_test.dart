import 'package:budget_zlate/models/categoria.dart';
import 'package:budget_zlate/models/gasto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith cambia solo los campos indicados', () {
    final original = Gasto(
      id: '1',
      descripcion: 'Almuerzo',
      montoCentimos: 350000,
      categoria: Categoria.alimentacion,
      fecha: DateTime(2026, 10, 17),
    );

    final copia = original.copyWith(descripcion: 'Cena', montoCentimos: 1);

    expect(copia.descripcion, 'Cena');
    expect(copia.montoCentimos, 1);
    expect(copia.id, '1');
    expect(copia.categoria, Categoria.alimentacion);
    expect(copia.fecha, DateTime(2026, 10, 17));
    // El original no cambia: es inmutable.
    expect(original.descripcion, 'Almuerzo');
  });

  group('fromMap / toMap (filas de Supabase)', () {
    // Así llega una fila de la tabla `gastos` en el JSON de Supabase.
    final fila = <String, dynamic>{
      'id': '7f9c1e2a-0000-4000-8000-000000000001',
      'user_id': '11111111-0000-4000-8000-000000000000',
      'descripcion': 'Supermercado',
      'monto_centimos': 2350075,
      'categoria': 'alimentacion',
      'fecha': '2026-10-08',
      'creado_en': '2026-10-08T15:30:00.000000+00:00',
    };

    test('fromMap convierte cada columna', () {
      final gasto = Gasto.fromMap(fila);

      expect(gasto.id, '7f9c1e2a-0000-4000-8000-000000000001');
      expect(gasto.descripcion, 'Supermercado');
      expect(gasto.montoCentimos, 2350075);
      expect(gasto.categoria, Categoria.alimentacion);
      expect(gasto.fecha, DateTime(2026, 10, 8));
    });

    test('toMap usa los nombres de columna y no incluye id ni user_id', () {
      final gasto = Gasto(
        id: 'no-se-envia',
        descripcion: 'Pasaje',
        montoCentimos: 52000,
        categoria: Categoria.transporte,
        fecha: DateTime(2026, 3, 5),
      );

      expect(gasto.toMap(), {
        'descripcion': 'Pasaje',
        'monto_centimos': 52000,
        'categoria': 'transporte',
        'fecha': '2026-03-05', // con ceros a la izquierda
      });
    });

    test('ida y vuelta conserva los datos', () {
      final original = Gasto.fromMap(fila);
      final copia = Gasto.fromMap({...original.toMap(), 'id': original.id});

      expect(copia.descripcion, original.descripcion);
      expect(copia.montoCentimos, original.montoCentimos);
      expect(copia.categoria, original.categoria);
      expect(copia.fecha, original.fecha);
    });

    test('una categoría desconocida es un error', () {
      expect(
        () => Gasto.fromMap({...fila, 'categoria': 'viajes'}),
        throwsArgumentError,
      );
    });
  });
}
