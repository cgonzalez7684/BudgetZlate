import 'package:flutter/material.dart';

import '../models/gasto.dart';
import '../utils/formato_moneda.dart';

/// Pregunta si se elimina [gasto]. Devuelve `true` solo si el usuario
/// confirma. Lo usan la lista (al deslizar) y "Editar gasto" (botón).
Future<bool> confirmarEliminacion(BuildContext context, Gasto gasto) async {
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
