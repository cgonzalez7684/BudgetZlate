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

  test('agregar guarda el gasto y le asigna un id', () async {
    final repository = GastosRepositoryMemoria();

    await repository.agregar(
      Gasto(
        descripcion: 'Almuerzo',
        montoCentimos: 350000,
        categoria: Categoria.alimentacion,
        fecha: DateTime(2026, 10, 17),
      ),
    );
    final gastos = await repository.obtenerGastos();

    expect(gastos, hasLength(1));
    expect(gastos.single.id, isNotNull);
    expect(gastos.single.descripcion, 'Almuerzo');
    expect(gastos.single.montoCentimos, 350000);
  });

  test('actualizar reemplaza el gasto con el mismo id', () async {
    final original = _gasto('a', DateTime(2026, 10, 1));
    final repository = GastosRepositoryMemoria([
      original,
      _gasto('b', DateTime(2026, 9, 1)),
    ]);

    await repository.actualizar(
      original.copyWith(descripcion: 'Editado', montoCentimos: 999),
    );
    final gastos = await repository.obtenerGastos();

    expect(gastos, hasLength(2));
    final editado = gastos.firstWhere((g) => g.id == 'a');
    expect(editado.descripcion, 'Editado');
    expect(editado.montoCentimos, 999);
    expect(gastos.firstWhere((g) => g.id == 'b').descripcion, 'b');
  });

  test('eliminar quita solo el gasto con ese id', () async {
    final repository = GastosRepositoryMemoria([
      _gasto('a', DateTime(2026, 10, 1)),
      _gasto('b', DateTime(2026, 9, 1)),
    ]);

    await repository.eliminar('a');
    final gastos = await repository.obtenerGastos();

    expect(gastos.map((g) => g.id), ['b']);
  });

  test('actualizar o eliminar un id inexistente lanza StateError', () {
    final repository = GastosRepositoryMemoria([
      _gasto('a', DateTime(2026, 10, 1)),
    ]);

    expect(
      repository.actualizar(_gasto('x', DateTime(2026, 10, 1))),
      throwsStateError,
    );
    expect(repository.eliminar('x'), throwsStateError);
  });

  test('los gastos de ejemplo tienen montos positivos', () async {
    final gastos = await GastosRepositoryMemoria.conEjemplos().obtenerGastos();

    expect(gastos, isNotEmpty);
    expect(gastos.every((g) => g.montoCentimos > 0), isTrue);
  });
}
