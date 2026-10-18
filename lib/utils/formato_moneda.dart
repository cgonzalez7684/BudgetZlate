/// Convierte un monto en céntimos al formato de colones: 150050 -> `₡1 500,50`.
///
/// Solo usa aritmética entera (`~/` y `%`), así que nunca hay errores de
/// redondeo. Los miles se separan con espacio y los decimales con coma.
String formatearColones(int centimos) {
  final signo = centimos < 0 ? '-' : '';
  final absoluto = centimos.abs();
  final colones = absoluto ~/ 100; // división entera
  final resto = absoluto % 100; // los dos decimales

  return '$signo₡${_separarMiles(colones)},${resto.toString().padLeft(2, '0')}';
}

/// 1234567 -> `1 234 567`
String _separarMiles(int numero) {
  final digitos = numero.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    final quedan = digitos.length - i;
    if (i > 0 && quedan % 3 == 0) buffer.write(' ');
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}
