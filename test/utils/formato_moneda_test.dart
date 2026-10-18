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
}
