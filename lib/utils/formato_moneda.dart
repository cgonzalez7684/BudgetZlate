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

/// Texto para rellenar el campo de monto al editar: 150050 -> `1500,50`,
/// 150000 -> `1500`. Sin símbolo ni separador de miles, y siempre se puede
/// volver a leer con [convertirACentimos].
String montoParaEditar(int centimos) {
  final colones = centimos ~/ 100;
  final resto = centimos % 100;
  if (resto == 0) return '$colones';
  return '$colones,${resto.toString().padLeft(2, '0')}';
}

/// Convierte el texto escrito por el usuario a céntimos, sin usar `double`.
///
/// Acepta coma o punto como separador decimal y espacios entre los miles:
/// `"1500"` -> 150000, `"0,5"` -> 50, `"1 500,25"` -> 150025, `"-5"` -> -500.
/// Devuelve `null` si el texto no es un número con como máximo 2 decimales
/// (o tiene más de 12 cifras enteras, para no desbordar `int`).
int? convertirACentimos(String texto) {
  final limpio = texto.trim().replaceAll(' ', '').replaceAll(',', '.');
  final partes = RegExp(r'^(-?)(\d{1,12})(?:\.(\d{1,2}))?$').firstMatch(limpio);
  if (partes == null) return null;

  final negativo = partes.group(1) == '-';
  final colones = int.parse(partes.group(2)!);
  // "5" -> "50" y "05" -> "05": rellenar a la derecha da los céntimos.
  final centimos = int.parse((partes.group(3) ?? '').padRight(2, '0'));

  final total = colones * 100 + centimos;
  return negativo ? -total : total;
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
