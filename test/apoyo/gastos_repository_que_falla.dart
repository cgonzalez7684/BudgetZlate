import 'package:budget_zlate/data/gastos_repository_memoria.dart';
import 'package:budget_zlate/models/gasto.dart';

/// Repositorio en memoria que puede simular fallos de red en las pruebas.
class GastosRepositoryQueFalla extends GastosRepositoryMemoria {
  GastosRepositoryQueFalla([super.gastos]);

  bool fallarAlCargar = false;
  bool fallarAlGuardar = false;

  Never _fallar() => throw Exception('Sin conexión (simulado)');

  @override
  Future<List<Gasto>> obtenerGastos() async {
    if (fallarAlCargar) _fallar();
    return super.obtenerGastos();
  }

  @override
  Future<void> agregar(Gasto gasto) async {
    if (fallarAlGuardar) _fallar();
    return super.agregar(gasto);
  }

  @override
  Future<void> actualizar(Gasto gasto) async {
    if (fallarAlGuardar) _fallar();
    return super.actualizar(gasto);
  }

  @override
  Future<void> eliminar(String id) async {
    if (fallarAlGuardar) _fallar();
    return super.eliminar(id);
  }
}
