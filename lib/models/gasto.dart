import 'categoria.dart';

/// Un gasto registrado por el usuario.
///
/// Es inmutable: todos los campos son `final`. Para "modificar" un gasto se
/// creará una copia con los cambios (tarea T3).
class Gasto {
  const Gasto({
    required this.id,
    required this.descripcion,
    required this.montoCentimos,
    required this.categoria,
    required this.fecha,
  });

  final String id;
  final String descripcion;

  /// Monto en céntimos de colón: ₡1 500,50 se guarda como 150050.
  /// Se usa `int` y no `double` para no perder precisión.
  final int montoCentimos;

  final Categoria categoria;

  /// Fecha del gasto; solo importan día, mes y año.
  final DateTime fecha;
}
