import 'package:budget_zlate/data/gastos_repository_memoria.dart';
import 'package:budget_zlate/models/categoria.dart';
import 'package:budget_zlate/models/gasto.dart';
import 'package:flutter_test/flutter_test.dart';

Gasto _gasto(String id, DateTime fecha) => Gasto(
  id: id,
  descripcion: id,
  montoCentimos: 100,
  categoria: Categoria.otros,
  fecha: fecha,
);

void main() {
  test('obtenerGastos devuelve del más reciente al más antiguo', () async {
    final repository = GastosRepositoryMemoria([
      _gasto('viejo', DateTime(2026, 9, 1)),
      _gasto('nuevo', DateTime(2026, 10, 15)),
      _gasto('medio', DateTime(2026, 10, 1)),
    ]);

    final gastos = await repository.obtenerGastos();

    expect(gastos.map((g) => g.id), ['nuevo', 'medio', 'viejo']);
  });

  test('los gastos de ejemplo tienen montos positivos', () async {
    final gastos = await GastosRepositoryMemoria.conEjemplos().obtenerGastos();

    expect(gastos, isNotEmpty);
    expect(gastos.every((g) => g.montoCentimos > 0), isTrue);
  });
}
