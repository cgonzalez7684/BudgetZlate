import 'package:flutter/material.dart';

import '../data/autenticacion.dart';

/// Pantalla para iniciar sesión o crear una cuenta.
///
/// No navega a ningún sitio al terminar: cuando cambia la sesión, la
/// `PuertaAcceso` (en app.dart) decide qué pantalla mostrar.
class AccesoScreen extends StatefulWidget {
  const AccesoScreen({super.key, required this.autenticacion});

  final Autenticacion autenticacion;

  @override
  State<AccesoScreen> createState() => _AccesoScreenState();
}

class _AccesoScreenState extends State<AccesoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _cargando = false;
  bool _mostrarContrasena = false;
  String? _error;
  String? _aviso;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  String? _validarCorreo(String? texto) {
    final correo = texto?.trim() ?? '';
    if (correo.isEmpty) return 'Ingresa tu correo';
    // Comprobación básica; la definitiva la hace Supabase.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      return 'Correo no válido';
    }
    return null;
  }

  String? _validarContrasena(String? texto) {
    if (texto == null || texto.isEmpty) return 'Ingresa tu contraseña';
    // Supabase exige al menos 6 caracteres por defecto.
    if (texto.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Valida el formulario, ejecuta [accion] mostrando un indicador de carga
  /// y muestra el error en español si falla.
  Future<void> _enviar(Future<void> Function(String, String) accion) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
      _aviso = null;
    });
    try {
      await accion(_correoController.text.trim(), _contrasenaController.text);
    } on ErrorAutenticacion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      // Si inició sesión, esta pantalla ya no está (mounted es false).
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarSesion(String correo, String contrasena) => widget
      .autenticacion
      .iniciarSesion(correo: correo, contrasena: contrasena);

  Future<void> _registrarse(String correo, String contrasena) async {
    final conSesion = await widget.autenticacion.registrarse(
      correo: correo,
      contrasena: contrasena,
    );
    if (!conSesion && mounted) {
      setState(() {
        _aviso =
            'Te enviamos un correo a $correo. Abre el enlace para confirmar '
            'tu cuenta y luego inicia sesión aquí.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colores.inversePrimary,
        title: const Text('BudgetZlate'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Text(
                'Inicia sesión para ver tus gastos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: _validarCorreo,
              ),
              TextFormField(
                controller: _contrasenaController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _mostrarContrasena
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    icon: Icon(
                      _mostrarContrasena
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _mostrarContrasena = !_mostrarContrasena,
                    ),
                  ),
                ),
                obscureText: !_mostrarContrasena,
                autocorrect: false,
                validator: _validarContrasena,
              ),
              if (_error != null)
                Text(_error!, style: TextStyle(color: colores.error)),
              if (_aviso != null) Text(_aviso!),
              if (_cargando)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton(
                  onPressed: () => _enviar(_iniciarSesion),
                  child: const Text('Iniciar sesión'),
                ),
                OutlinedButton(
                  onPressed: () => _enviar(_registrarse),
                  child: const Text('Crear cuenta'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
