import 'package:budget_zlate/utils/formato_fecha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatearFecha usa día/mes/año con ceros a la izquierda', () {
    expect(formatearFecha(DateTime(2026, 10, 5)), '05/10/2026');
    expect(formatearFecha(DateTime(2026, 12, 31)), '31/12/2026');
  });
}
