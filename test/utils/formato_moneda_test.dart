import 'package:budget_zlate/utils/formato_moneda.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatearColones', () {
    test('cero', () => expect(formatearColones(0), '₡0,00'));

    test('solo céntimos', () => expect(formatearColones(5), '₡0,05'));

    test('miles sin céntimos', () {
      expect(formatearColones(150000), '₡1 500,00');
    });

    test('miles con céntimos', () {
      expect(formatearColones(1234567), '₡12 345,67');
    });

    test('millones', () {
      expect(formatearColones(100000000), '₡1 000 000,00');
    });

    test('sumar céntimos es exacto (0,10 + 0,20 = 0,30)', () {
      expect(formatearColones(10 + 20), '₡0,30');
    });
  });

  group('montoParaEditar', () {
    test('sin céntimos no muestra decimales', () {
      expect(montoParaEditar(150000), '1500');
    });

    test('con céntimos usa coma y dos decimales', () {
      expect(montoParaEditar(850050), '8500,50');
      expect(montoParaEditar(5), '0,05');
    });

    test('el texto se puede volver a convertir al mismo monto', () {
      for (final centimos in [1, 5, 50, 100, 125050, 2350075, 600000]) {
        expect(convertirACentimos(montoParaEditar(centimos)), centimos);
      }
    });
  });

  group('convertirACentimos', () {
    test('textos válidos', () {
      expect(convertirACentimos('1500'), 150000);
      expect(convertirACentimos('0,5'), 50);
      expect(convertirACentimos('0.5'), 50);
      expect(convertirACentimos('0,05'), 5);
      expect(convertirACentimos('12,34'), 1234);
      expect(convertirACentimos('1 500,25'), 150025);
      expect(convertirACentimos('  7 '), 700);
    });

    test('cero y negativos se convierten (el formulario los rechaza)', () {
      expect(convertirACentimos('0'), 0);
      expect(convertirACentimos('-5'), -500);
    });

    test('textos inválidos devuelven null', () {
      expect(convertirACentimos(''), isNull);
      expect(convertirACentimos('abc'), isNull);
      expect(convertirACentimos('1,234'), isNull); // más de 2 decimales
      expect(convertirACentimos('1.500'), isNull); // ídem: no es "mil"
      expect(convertirACentimos('1,2,3'), isNull);
      expect(convertirACentimos(',5'), isNull);
      expect(convertirACentimos('1234567890123'), isNull); // 13 cifras
    });
  });
}
