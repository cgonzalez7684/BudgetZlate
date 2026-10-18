import '../models/categoria.dart';
import '../models/gasto.dart';

// Funciones puras: el resultado depende solo de los argumentos, no leen ni
// cambian nada más (ni la fecha actual, ni la red). Por eso se prueban con
// pruebas unitarias simples, sin pantallas ni Supabase.

/// Primer instante del mes de [fecha]: 17/10/2026 15:30 -> 01/10/2026 00:00.
DateTime inicioDeMes(DateTime fecha) => DateTime(fecha.year, fecha.month);

/// `DateTime` ajusta solo los meses fuera de rango: el mes 0 de 2027 es
/// diciembre de 2026 y el mes 13 de 2026 es enero de 2027.
DateTime mesAnterior(DateTime mes) => DateTime(mes.year, mes.month - 1);

DateTime mesSiguiente(DateTime mes) => DateTime(mes.year, mes.month + 1);

/// Gastos cuya fecha cae en el mes (y año) de [mes].
///
/// Comparar año y mes (en vez de "entre el día 1 y el último día") evita
/// errores en los límites: no hay que calcular cuántos días tiene el mes.
List<Gasto> filtrarPorMes(List<Gasto> gastos, DateTime mes) {
  return gastos
      .where((g) => g.fecha.year == mes.year && g.fecha.month == mes.month)
      .toList();
}

/// Totales de un conjunto de gastos.
class ResumenMensual {
  const ResumenMensual({
    required this.totalCentimos,
    required this.porCategoria,
  });

  final int totalCentimos;

  /// Siempre tiene las 4 categorías; las que no tienen gastos valen 0.
  final Map<Categoria, int> porCategoria;
}

ResumenMensual resumenPorCategoria(List<Gasto> gastos) {
  // Se empieza con todas las categorías en 0 para que aparezcan aunque no
  // tengan gastos.
  final porCategoria = {for (final categoria in Categoria.values) categoria: 0};
  for (final gasto in gastos) {
    porCategoria[gasto.categoria] =
        porCategoria[gasto.categoria]! + gasto.montoCentimos;
  }

  // fold recorre la lista acumulando un valor: empieza en 0 y va sumando.
  final total = gastos.fold(0, (suma, gasto) => suma + gasto.montoCentimos);

  return ResumenMensual(totalCentimos: total, porCategoria: porCategoria);
}
