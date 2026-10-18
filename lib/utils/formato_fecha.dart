/// Formatea una fecha como día/mes/año: `05/10/2026`.
String formatearFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Nombre del mes y año en español: `octubre 2026`.
String formatearMes(DateTime fecha) =>
    '${_meses[fecha.month - 1]} ${fecha.year}';
