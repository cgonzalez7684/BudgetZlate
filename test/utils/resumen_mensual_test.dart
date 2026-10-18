import 'package:budget_zlate/models/categoria.dart';
import 'package:budget_zlate/models/gasto.dart';
import 'package:budget_zlate/utils/resumen_mensual.dart';
import 'package:flutter_test/flutter_test.dart';

Gasto _gasto(DateTime fecha, {int centimos = 100, Categoria? categoria}) =>
    Gasto(
      id: fecha.toIso8601String(),
      descripcion: 'g',
      montoCentimos: centimos,
      categoria: categoria ?? Categoria.otros,
      fecha: fecha,
    );

List<DateTime> _fechas(List<Gasto> gastos) =>
    gastos.map((g) => g.fecha).toList();

void main() {
  group('inicioDeMes / mesAnterior / mesSiguiente', () {
    test('inicioDeMes descarta día y hora', () {
      expect(inicioDeMes(DateTime(2026, 10, 17, 15, 30)), DateTime(2026, 10));
    });

    test('diciembre -> enero del año siguiente', () {
      expect(mesSiguiente(DateTime(2026, 12)), DateTime(2027, 1));
    });

    test('enero -> diciembre del año anterior', () {
      expect(mesAnterior(DateTime(2027, 1)), DateTime(2026, 12));
    });

    test('meses normales', () {
      expect(mesSiguiente(DateTime(2026, 10)), DateTime(2026, 11));
      expect(mesAnterior(DateTime(2026, 10)), DateTime(2026, 9));
    });
  });

  group('filtrarPorMes', () {
    test('incluye el día 1 y el último día; excluye los meses vecinos', () {
      final gastos = [
        _gasto(DateTime(2026, 9, 30)),
        _gasto(DateTime(2026, 10, 1)),
        _gasto(DateTime(2026, 10, 31)),
        _gasto(DateTime(2026, 11, 1)),
      ];

      expect(_fechas(filtrarPorMes(gastos, DateTime(2026, 10))), [
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 31),
      ]);
    });

    test('febrero bisiesto incluye el 29', () {
      final gastos = [
        _gasto(DateTime(2028, 2, 28)),
        _gasto(DateTime(2028, 2, 29)),
        _gasto(DateTime(2028, 3, 1)),
      ];

      expect(_fechas(filtrarPorMes(gastos, DateTime(2028, 2))), [
        DateTime(2028, 2, 28),
        DateTime(2028, 2, 29),
      ]);
    });

    test('febrero no bisiesto termina el 28', () {
      final gastos = [
        _gasto(DateTime(2027, 2, 28)),
        _gasto(DateTime(2027, 3, 1)),
      ];

      expect(_fechas(filtrarPorMes(gastos, DateTime(2027, 2))), [
        DateTime(2027, 2, 28),
      ]);
    });

    test('diciembre no incluye el 1 de enero del año siguiente', () {
      final gastos = [
        _gasto(DateTime(2026, 12, 31)),
        _gasto(DateTime(2027, 1, 1)),
      ];

      expect(_fechas(filtrarPorMes(gastos, DateTime(2026, 12))), [
        DateTime(2026, 12, 31),
      ]);
      expect(_fechas(filtrarPorMes(gastos, DateTime(2027, 1))), [
        DateTime(2027, 1, 1),
      ]);
    });

    test('el mismo mes de otro año no se incluye', () {
      final gastos = [
        _gasto(DateTime(2025, 10, 5)),
        _gasto(DateTime(2026, 10, 5)),
      ];

      expect(_fechas(filtrarPorMes(gastos, DateTime(2026, 10))), [
        DateTime(2026, 10, 5),
      ]);
    });

    test('la hora de la fecha no afecta', () {
      final gastos = [_gasto(DateTime(2026, 10, 31, 23, 59))];

      expect(filtrarPorMes(gastos, DateTime(2026, 10)), hasLength(1));
    });
  });

  group('resumenPorCategoria', () {
    test('suma el total y cada categoría', () {
      final resumen = resumenPorCategoria([
        _gasto(
          DateTime(2026, 10, 1),
          centimos: 100000,
          categoria: Categoria.alimentacion,
        ),
        _gasto(
          DateTime(2026, 10, 2),
          centimos: 25050,
          categoria: Categoria.alimentacion,
        ),
        _gasto(
          DateTime(2026, 10, 3),
          centimos: 52000,
          categoria: Categoria.transporte,
        ),
      ]);

      expect(resumen.totalCentimos, 177050);
      expect(resumen.porCategoria, {
        Categoria.alimentacion: 125050,
        Categoria.transporte: 52000,
        Categoria.servicios: 0,
        Categoria.otros: 0,
      });
    });

    test('la suma de las categorías es igual al total', () {
      final resumen = resumenPorCategoria([
        for (var i = 1; i <= 28; i++)
          _gasto(
            DateTime(2026, 2, i),
            centimos: i * 137,
            categoria: Categoria.values[i % Categoria.values.length],
          ),
      ]);

      final sumaCategorias = resumen.porCategoria.values.fold(
        0,
        (a, b) => a + b,
      );
      expect(sumaCategorias, resumen.totalCentimos);
    });

    test('sin gastos todo es 0 y aparecen las 4 categorías', () {
      final resumen = resumenPorCategoria([]);

      expect(resumen.totalCentimos, 0);
      expect(resumen.porCategoria.keys, Categoria.values);
      expect(resumen.porCategoria.values, everyElement(0));
    });

    test('los céntimos se suman sin errores de redondeo', () {
      final resumen = resumenPorCategoria([
        _gasto(DateTime(2026, 10, 1), centimos: 10),
        _gasto(DateTime(2026, 10, 2), centimos: 20),
      ]);

      expect(resumen.totalCentimos, 30); // 0,10 + 0,20 = 0,30 exacto
    });
  });
}
