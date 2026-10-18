import '../models/gasto.dart';

/// Contrato para obtener y guardar gastos.
///
/// Las pantallas solo conocen este contrato, así que se puede cambiar la
/// implementación en memoria por la de Supabase sin tocarlas.
abstract class GastosRepository {
  /// Devuelve los gastos ordenados por fecha, del más reciente al más antiguo.
  Future<List<Gasto>> obtenerGastos();

  /// Guarda un gasto nuevo. El repositorio le asigna su `id`.
  Future<void> agregar(Gasto gasto);

  /// Reemplaza el gasto guardado que tiene el mismo `id`.
  Future<void> actualizar(Gasto gasto);

  /// Elimina el gasto con ese `id`.
  Future<void> eliminar(String id);
}
