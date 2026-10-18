import '../models/gasto.dart';

/// Contrato para obtener y guardar gastos.
///
/// Las pantallas solo conocen este contrato, así que se puede cambiar la
/// implementación en memoria por la de Supabase sin tocarlas.
/// Las operaciones de agregar, actualizar y eliminar se añadirán en T2 y T3.
abstract class GastosRepository {
  /// Devuelve los gastos ordenados por fecha, del más reciente al más antiguo.
  Future<List<Gasto>> obtenerGastos();
}
