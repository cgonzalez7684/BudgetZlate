import '../models/categoria.dart';
import '../models/gasto.dart';
import 'gastos_repository.dart';

/// Implementación que guarda los gastos en una lista en memoria.
///
/// Los datos se pierden al cerrar la app; se sustituirá por Supabase en T4.
class GastosRepositoryMemoria implements GastosRepository {
  GastosRepositoryMemoria([List<Gasto> gastos = const []])
    : _gastos = List.of(gastos);

  /// Repositorio con los gastos de ejemplo que se muestran al abrir la app.
  factory GastosRepositoryMemoria.conEjemplos() =>
      GastosRepositoryMemoria(gastosDeEjemplo);

  final List<Gasto> _gastos;

  @override
  Future<List<Gasto>> obtenerGastos() async {
    final ordenados = List.of(_gastos)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(ordenados);
  }
}

final gastosDeEjemplo = [
  Gasto(
    id: 'ejemplo-1',
    descripcion: 'Supermercado',
    montoCentimos: 2350075, // ₡23 500,75
    categoria: Categoria.alimentacion,
    fecha: DateTime(2026, 10, 8),
  ),
  Gasto(
    id: 'ejemplo-2',
    descripcion: 'Pasaje de bus',
    montoCentimos: 52000, // ₡520,00
    categoria: Categoria.transporte,
    fecha: DateTime(2026, 10, 7),
  ),
  Gasto(
    id: 'ejemplo-3',
    descripcion: 'Recibo de electricidad',
    montoCentimos: 1845050, // ₡18 450,50
    categoria: Categoria.servicios,
    fecha: DateTime(2026, 10, 3),
  ),
  Gasto(
    id: 'ejemplo-4',
    descripcion: 'Café con pan',
    montoCentimos: 185000, // ₡1 850,00
    categoria: Categoria.alimentacion,
    fecha: DateTime(2026, 10, 2),
  ),
  Gasto(
    id: 'ejemplo-5',
    descripcion: 'Corte de cabello',
    montoCentimos: 600000, // ₡6 000,00
    categoria: Categoria.otros,
    fecha: DateTime(2026, 9, 28),
  ),
];
