import 'package:flutter/material.dart';

import '../data/gastos_repository.dart';
import '../models/gasto.dart';
import '../utils/formato_fecha.dart';
import '../utils/formato_moneda.dart';

/// Pantalla principal: lista de gastos.
///
/// Es un `StatefulWidget` porque guarda el `Future` de la carga. Si el
/// `Future` se creara dentro de `build`, se volvería a pedir los datos en
/// cada reconstrucción.
class ListaGastosScreen extends StatefulWidget {
  const ListaGastosScreen({super.key, required this.repository});

  final GastosRepository repository;

  @override
  State<ListaGastosScreen> createState() => _ListaGastosScreenState();
}

class _ListaGastosScreenState extends State<ListaGastosScreen> {
  late final Future<List<Gasto>> _gastos;

  @override
  void initState() {
    super.initState();
    _gastos = widget.repository.obtenerGastos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('BudgetZlate'),
      ),
      body: FutureBuilder<List<Gasto>>(
        future: _gastos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los gastos'),
            );
          }

          final gastos = snapshot.data!;
          if (gastos.isEmpty) {
            return const Center(child: Text('No hay gastos registrados'));
          }

          return ListView.builder(
            itemCount: gastos.length,
            itemBuilder: (context, index) => _GastoTile(gasto: gastos[index]),
          );
        },
      ),
    );
  }
}

/// Una fila de la lista. Es `StatelessWidget`: solo muestra datos que recibe.
class _GastoTile extends StatelessWidget {
  const _GastoTile({required this.gasto});

  final Gasto gasto;

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
