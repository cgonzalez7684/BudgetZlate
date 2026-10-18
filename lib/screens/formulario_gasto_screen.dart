import 'package:flutter/material.dart';

import '../models/categoria.dart';
import '../models/gasto.dart';
import '../utils/formato_fecha.dart';
import '../utils/formato_moneda.dart';

/// Formulario para crear o editar un gasto.
///
/// No guarda nada: al pulsar "Guardar" cierra la pantalla devolviendo el
/// `Gasto` con `Navigator.pop`, y quien la abrió decide qué hacer con él.
/// Así el formulario no depende del repositorio.
class FormularioGastoScreen extends StatefulWidget {
  const FormularioGastoScreen({super.key, this.gasto});

  /// Gasto a editar. Si es `null`, el formulario crea uno nuevo.
  final Gasto? gasto;

  @override
  State<FormularioGastoScreen> createState() => _FormularioGastoScreenState();
}

class _FormularioGastoScreenState extends State<FormularioGastoScreen> {
  // Identifica el Form para poder validar todos sus campos a la vez.
  final _formKey = GlobalKey<FormState>();

  // Los controladores guardan el texto de cada campo. Ocupan recursos, por
  // eso se liberan en dispose().
  late final TextEditingController _descripcionController;
  late final TextEditingController _montoController;

  Categoria? _categoria;
  late DateTime _fecha;

  bool get _editando => widget.gasto != null;

  static DateTime _hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  @override
  void initState() {
    super.initState();
    // Al editar, los campos empiezan con los datos del gasto.
    final gasto = widget.gasto;
    _descripcionController = TextEditingController(text: gasto?.descripcion);
    _montoController = TextEditingController(
      text: gasto == null ? null : montoParaEditar(gasto.montoCentimos),
    );
    _categoria = gasto?.categoria;
    _fecha = gasto?.fecha ?? _hoy();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  String? _validarDescripcion(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return 'Ingresa una descripción';
    }
    return null;
  }

  String? _validarMonto(String? texto) {
    if (texto == null || texto.trim().isEmpty) return 'Ingresa un monto';
    if (RegExp(r'[.,]\d{3,}$').hasMatch(texto.trim())) {
      return 'Usa como máximo 2 decimales';
    }
    final centimos = convertirACentimos(texto);
    if (centimos == null) return 'Ingresa un monto válido';
    if (centimos <= 0) return 'El monto debe ser mayor que cero';
    return null;
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: _hoy(),
    );
    if (elegida != null) {
      setState(() => _fecha = elegida);
    }
  }

  void _guardar() {
    // validate() ejecuta el validador de cada campo y muestra sus mensajes.
    if (!_formKey.currentState!.validate()) return;

    final gasto = Gasto(
      id: widget.gasto?.id, // al editar se conserva el id; al crear es null
      descripcion: _descripcionController.text.trim(),
      montoCentimos: convertirACentimos(_montoController.text)!,
      categoria: _categoria!,
      fecha: _fecha,
    );
    Navigator.pop(context, gasto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_editando ? 'Editar gasto' : 'Nuevo gasto'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: _validarDescripcion,
              ),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '₡ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validarMonto,
              ),
              DropdownButtonFormField<Categoria>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final categoria in Categoria.values)
                    DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.etiqueta),
                    ),
                ],
                onChanged: (categoria) =>
                    setState(() => _categoria = categoria),
                validator: (categoria) =>
                    categoria == null ? 'Elige una categoría' : null,
              ),
              // InputDecorator da a la fecha el mismo aspecto que los campos.
              InkWell(
                onTap: _elegirFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(formatearFecha(_fecha)),
                ),
              ),
              FilledButton(onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
