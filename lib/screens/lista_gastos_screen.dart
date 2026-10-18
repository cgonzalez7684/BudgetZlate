import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/gastos_repository.dart';
import '../models/gasto.dart';
import '../utils/formato_fecha.dart';
import '../utils/formato_moneda.dart';
import 'formulario_gasto_screen.dart';

/// Pantalla principal: lista de gastos.
///
/// Es un `StatefulWidget` porque guarda el `Future` de la carga. Si el
/// `Future` se creara dentro de `build`, se volvería a pedir los datos en
/// cada reconstrucción.
class ListaGastosScreen extends StatefulWidget {
  const ListaGastosScreen({
    super.key,
    required this.repository,
    required this.onCerrarSesion,
  });

  final GastosRepository repository;

  /// Se llama al pulsar "Cerrar sesión". La pantalla no sabe cómo se cierra
  /// la sesión; solo avisa.
  final Future<void> Function() onCerrarSesion;

  @override
  State<ListaGastosScreen> createState() => _ListaGastosScreenState();
}

class _ListaGastosScreenState extends State<ListaGastosScreen> {
  late Future<List<Gasto>> _gastos;

  @override
  void initState() {
    super.initState();
    _gastos = widget.repository.obtenerGastos();
  }

  /// Espera a que termine una operación del repositorio, avisa si salió bien
  /// o mal y vuelve a cargar la lista.
  ///
  /// Si la operación falla (p. ej. sin internet) la app no se cierra: muestra
  /// [siFalla] y recarga, así la lista refleja lo que hay realmente guardado.
  Future<List<Gasto>> _recargarTras(
    Future<void> operacion, {
    String? siFunciona,
    required String siFalla,
  }) async {
    try {
      await operacion;
      if (siFunciona != null) _avisar(siFunciona);
    } catch (error) {
      _registrar(error);
      _avisar(siFalla);
    }
    return widget.repository.obtenerGastos();
  }

  void _recargar() {
    setState(() {
      _gastos = widget.repository.obtenerGastos();
    });
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// El detalle técnico solo se muestra en la consola y en modo debug.
  void _registrar(Object error) {
    if (kDebugMode) debugPrint('[BudgetZlate] Error de datos: $error');
  }

  /// Abre el formulario (vacío, o con [gasto] para editarlo), espera el
  /// resultado y lo guarda.
  Future<void> _abrirFormulario({Gasto? gasto}) async {
    final resultado = await Navigator.push<Gasto>(
      context,
      MaterialPageRoute(builder: (_) => FormularioGastoScreen(gasto: gasto)),
    );
    // null: el usuario volvió sin guardar. `mounted`: tras un `await` la
    // pantalla podría haberse cerrado.
    if (resultado == null || !mounted) return;

    final operacion = gasto == null
        ? widget.repository.agregar(resultado)
        : widget.repository.actualizar(resultado);
    // Un Future nuevo hace que el FutureBuilder vuelva a cargar la lista.
    // Se usa un bloque { } y no una flecha (=>): la flecha devolvería el
    // Future asignado, y setState no admite funciones que devuelvan Future.
    setState(() {
      _gastos = _recargarTras(
        operacion,
        siFalla: 'No se pudo guardar el gasto. Revisa tu conexión.',
      );
    });
  }

  /// Muestra un diálogo y devuelve `true` solo si el usuario confirma.
  Future<bool> _confirmarEliminacion(Gasto gasto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar gasto?'),
        content: Text(
          '"${gasto.descripcion}" (${formatearColones(gasto.montoCentimos)}) '
          'se eliminará. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    // Cerrar el diálogo tocando fuera devuelve null: se trata como "no".
    return confirmado ?? false;
  }

  void _eliminarGasto(Gasto gasto) {
    // El setState va inmediatamente, sin await antes: Dismissible exige que
    // la fila deslizada desaparezca del árbol en cuanto se descarta. Si el
    // borrado falla, la recarga la vuelve a mostrar.
    setState(() {
      _gastos = _recargarTras(
        widget.repository.eliminar(gasto.id!),
        siFunciona: 'Se eliminó "${gasto.descripcion}"',
        siFalla: 'No se pudo eliminar el gasto. Revisa tu conexión.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('BudgetZlate'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: widget.onCerrarSesion,
          ),
        ],
      ),
      body: FutureBuilder<List<Gasto>>(
        future: _gastos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            _registrar(snapshot.error!);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  const Text(
                    'No se pudieron cargar los gastos.\n'
                    'Revisa tu conexión a internet.',
                    textAlign: TextAlign.center,
                  ),
                  FilledButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final gastos = snapshot.data!;
          if (gastos.isEmpty) {
            return const Center(child: Text('No hay gastos registrados'));
          }

          return ListView.builder(
            itemCount: gastos.length,
            itemBuilder: (context, index) {
              final gasto = gastos[index];
              // Dismissible permite deslizar la fila para eliminarla. Su `key`
              // le dice a Flutter qué gasto es cada fila aunque la lista cambie.
              return Dismissible(
                key: ValueKey(gasto.id),
                direction: DismissDirection.endToStart,
                background: const _FondoEliminar(),
                confirmDismiss: (_) => _confirmarEliminacion(gasto),
                onDismissed: (_) => _eliminarGasto(gasto),
                child: _GastoTile(
                  gasto: gasto,
                  onTap: () => _abrirFormulario(gasto: gasto),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        tooltip: 'Agregar gasto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Una fila de la lista. Es `StatelessWidget`: solo muestra datos que recibe.
class _GastoTile extends StatelessWidget {
  const _GastoTile({required this.gasto, required this.onTap});

  final Gasto gasto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(gasto.descripcion),
      subtitle: Text(
        '${gasto.categoria.etiqueta} · ${formatearFecha(gasto.fecha)}',
      ),
      trailing: Text(
        formatearColones(gasto.montoCentimos),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

/// Lo que se ve detrás de la fila mientras se desliza para eliminarla.
class _FondoEliminar extends StatelessWidget {
  const _FondoEliminar();

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      color: colores.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.delete, color: colores.onErrorContainer),
    );
  }
}
