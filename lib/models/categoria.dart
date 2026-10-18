/// Categorías fijas de la versión 1.
///
/// Es un "enum mejorado": cada valor guarda su etiqueta en español para la
/// interfaz, mientras que el nombre del valor (`alimentacion`, ...) es el que
/// se guardará en la base de datos.
enum Categoria {
  alimentacion('Alimentación'),
  transporte('Transporte'),
  servicios('Servicios'),
  otros('Otros');

  const Categoria(this.etiqueta);

  final String etiqueta;
}
