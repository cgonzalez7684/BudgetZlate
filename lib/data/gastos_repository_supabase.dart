import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/gasto.dart';
import 'gastos_repository.dart';

/// Implementación que guarda los gastos en la tabla `gastos` de Supabase.
///
/// No filtra por usuario: las políticas RLS de la base de datos hacen que
/// cada usuario solo lea y modifique sus propias filas, aunque la consulta
/// pida "todas".
class GastosRepositorySupabase implements GastosRepository {
  GastosRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const _tabla = 'gastos';

  @override
  Future<List<Gasto>> obtenerGastos() async {
    final filas = await _client
        .from(_tabla)
        .select()
        .order('fecha', ascending: false)
        .order('creado_en', ascending: false);
    return filas.map(Gasto.fromMap).toList();
  }

  @override
  Future<void> agregar(Gasto gasto) async {
    await _client.from(_tabla).insert(gasto.toMap());
  }

  @override
  Future<void> actualizar(Gasto gasto) async {
    // `.select('id')` devuelve las filas afectadas. Si no hay ninguna, el
    // gasto no existe o RLS no lo permite: se trata como error, igual que
    // en el repositorio en memoria.
    final filas = await _client
        .from(_tabla)
        .update(gasto.toMap())
        .eq('id', gasto.id!)
        .select('id');
    if (filas.isEmpty) {
      throw StateError('No existe un gasto con id ${gasto.id}');
    }
  }

  @override
  Future<void> eliminar(String id) async {
    final filas = await _client.from(_tabla).delete().eq('id', id).select('id');
    if (filas.isEmpty) throw StateError('No existe un gasto con id $id');
  }
}
