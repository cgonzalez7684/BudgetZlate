import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/gastos_repository.dart';
import '../models/categoria.dart';
import '../models/gasto.dart';
import '../utils/formato_fecha.dart';
import '../utils/formato_moneda.dart';
import '../utils/resumen_mensual.dart';
import 'confirmar_eliminacion.dart';
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
    this.mesInicial,
  });

  final GastosRepository repository;

  /// Mes que se muestra al abrir; por defecto, el actual. Las pruebas lo
  /// fijan para no depender de la fecha del día en que se ejecutan.
  final DateTime? mesInicial;

  /// Se llama al pulsar "Cerrar sesión". La pantalla no sabe cómo se cierra
  /// la sesión; solo avisa.
  final Future<void> Function() onCerrarSesion;

  @override
  State<ListaGastosScreen> createState() => _ListaGastosScreenState();
}

class _ListaGastosScreenState extends State<ListaGastosScreen> {
  /// Todos los gastos del usuario; el filtro por mes se aplica al mostrar.
  late Future<List<Gasto>> _gastos;

  /// Mes elegido (siempre el día 1 a las 00:00).
  late DateTime _mes;

  @override
  void initState() {
    super.initState();
    _gastos = widget.repository.obtenerGastos();
    _mes = inicioDeMes(widget.mesInicial ?? DateTime.now());
  }

  bool get _esMesActual => _mes == inicioDeMes(DateTime.now());

  // Cambiar de mes no vuelve a pedir datos: el FutureBuilder conserva los
  // gastos ya cargados y solo cambia el filtro.
  void _cambiarMes(DateTime mes) => setState(() => _mes = mes);

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
  /// resultado y lo guarda o lo elimina.
  Future<void> _abrirFormulario({Gasto? gasto}) async {
    final resultado = await Navigator.push<ResultadoFormulario>(
      context,
      MaterialPageRoute(builder: (_) => FormularioGastoScreen(gasto: gasto)),
    );
    // `mounted`: tras un `await` la pantalla podría haberse cerrado.
    if (!mounted) return;

    // `switch` con patrones: según qué subclase llegó, se hace una cosa u
    // otra. Como ResultadoFormulario es `sealed`, si mañana se añade un caso
    // nuevo el analizador señala este switch como incompleto.
    switch (resultado) {
      case null:
        return; // el usuario volvió sin guardar
      case EliminarGasto():
        _eliminarGasto(gasto!);
      case GuardarGasto(gasto: final guardado):
        final operacion = gasto == null
            ? widget.repository.agregar(guardado)
            : widget.repository.actualizar(guardado);
        // Un Future nuevo hace que el FutureBuilder vuelva a cargar la lista.
        // Se usa un bloque { } y no una flecha (=>): la flecha devolvería el
        // Future asignado, y setState no admite funciones que devuelvan Future.
        setState(() {
          _gastos = _recargarTras(
            operacion,
            siFalla: 'No se pudo guardar el gasto. Revisa tu conexión.',
          );
          // Se muestra el mes del gasto guardado, para que no "desaparezca"
          // si su fecha es de otro mes.
          _mes = inicioDeMes(guardado.fecha);
        });
    }
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
      body: Column(
        children: [
          _SelectorMes(
            mes: _mes,
            onAnterior: () => _cambiarMes(mesAnterior(_mes)),
            // null desactiva el botón: no se navega a meses futuros.
            onSiguiente: _esMesActual
                ? null
                : () => _cambiarMes(mesSiguiente(_mes)),
          ),
          Expanded(
            child: FutureBuilder<List<Gasto>>(
              future: _gastos,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  _registrar(snapshot.error!);
                  return _ErrorDeCarga(onReintentar: _recargar);
                }

                final delMes = filtrarPorMes(snapshot.data!, _mes);
                return Column(
                  children: [
                    _TarjetaResumen(resumen: resumenPorCategoria(delMes)),
                    Expanded(
                      child: delMes.isEmpty
                          ? Center(
                              child: Text(
                                'No hay gastos en ${formatearMes(_mes)}',
                              ),
                            )
                          : _listaDeGastos(delMes),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        tooltip: 'Agregar gasto',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _listaDeGastos(List<Gasto> gastos) {
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
          confirmDismiss: (_) => confirmarEliminacion(context, gasto),
          onDismissed: (_) => _eliminarGasto(gasto),
          child: _GastoTile(
            gasto: gasto,
            onTap: () => _abrirFormulario(gasto: gasto),
          ),
        );
      },
    );
  }
}

/// "‹  octubre 2026  ›" para cambiar de mes.
class _SelectorMes extends StatelessWidget {
  const _SelectorMes({
    required this.mes,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final DateTime mes;
  final VoidCallback onAnterior;
  final VoidCallback? onSiguiente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: onAnterior,
          ),
          Expanded(
            child: Text(
              formatearMes(mes),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Mes siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: onSiguiente,
          ),
        ],
      ),
    );
  }
}

/// Total del mes y total por categoría.
class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.resumen});

  final ResumenMensual resumen;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      key: const Key('resumen'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 4,
          children: [
            _FilaResumen(
              etiqueta: 'Total del mes',
              centimos: resumen.totalCentimos,
              estilo: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            for (final categoria in Categoria.values)
              _FilaResumen(
                etiqueta: categoria.etiqueta,
                centimos: resumen.porCategoria[categoria]!,
                estilo: textos.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({
    required this.etiqueta,
    required this.centimos,
    required this.estilo,
  });

  final String etiqueta;
  final int centimos;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(etiqueta, style: estilo)),
        Text(formatearColones(centimos), style: estilo),
      ],
    );
  }
}

/// Mensaje cuando no se pudieron cargar los gastos.
class _ErrorDeCarga extends StatelessWidget {
  const _ErrorDeCarga({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
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
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
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
