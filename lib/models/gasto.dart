import 'categoria.dart';

/// Un gasto registrado por el usuario.
///
/// Es inmutable: todos los campos son `final`. Para "modificar" un gasto se
/// creará una copia con los cambios (tarea T3).
class Gasto {
  const Gasto({
    this.id,
    required this.descripcion,
    required this.montoCentimos,
    required this.categoria,
    required this.fecha,
  });

  /// Crea un `Gasto` a partir de una fila de la tabla `gastos` de Supabase.
  ///
  /// Los nombres de columna van en snake_case (`monto_centimos`), como es
  /// costumbre en SQL; en Dart se usa camelCase (`montoCentimos`).
  factory Gasto.fromMap(Map<String, dynamic> fila) {
    return Gasto(
      id: fila['id'] as String,
      descripcion: fila['descripcion'] as String,
      montoCentimos: fila['monto_centimos'] as int,
      // 'alimentacion' -> Categoria.alimentacion
      categoria: Categoria.values.byName(fila['categoria'] as String),
      // Una columna `date` llega como '2026-10-08'.
      fecha: DateTime.parse(fila['fecha'] as String),
    );
  }

  /// Datos para insertar o actualizar la fila en Supabase.
  ///
  /// No incluye `id` ni `user_id`: la base de datos los genera (`id`) o los
  /// toma de la sesión (`user_id` = `auth.uid()`).
  Map<String, dynamic> toMap() {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return {
      'descripcion': descripcion,
      'monto_centimos': montoCentimos,
      'categoria': categoria.name,
      'fecha': '${fecha.year}-$mes-$dia',
    };
  }

  /// Identificador asignado por el repositorio al guardar.
  /// Es `null` mientras el gasto no se ha guardado (p. ej. al salir del
  /// formulario), igual que en Supabase, donde lo generará la base de datos.
  final String? id;
  final String descripcion;

  /// Monto en céntimos de colón: ₡1 500,50 se guarda como 150050.
  /// Se usa `int` y no `double` para no perder precisión.
  final int montoCentimos;

  final Categoria categoria;

  /// Fecha del gasto; solo importan día, mes y año.
  final DateTime fecha;

  /// Devuelve una copia cambiando solo los campos indicados.
  ///
  /// Como `Gasto` es inmutable, "modificarlo" significa crear otro objeto:
  /// `gasto.copyWith(descripcion: 'Taxi')` conserva todo lo demás.
  Gasto copyWith({
    String? id,
    String? descripcion,
    int? montoCentimos,
    Categoria? categoria,
    DateTime? fecha,
  }) {
    return Gasto(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      montoCentimos: montoCentimos ?? this.montoCentimos,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
    );
  }
}
