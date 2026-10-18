import 'dart:async';

import 'package:budget_zlate/app.dart';
import 'package:budget_zlate/data/autenticacion.dart';
import 'package:budget_zlate/data/gastos_repository.dart';

/// Autenticación en memoria para pruebas: no usa red ni Supabase.
class AutenticacionFalsa implements Autenticacion {
  AutenticacionFalsa({this.haySesion = false});

  final _cambios = StreamController<bool>.broadcast();

  @override
  bool haySesion;

  @override
  String? correo;

  /// Si no es null, iniciarSesion y registrarse lanzan este error.
  ErrorAutenticacion? error;

  /// Lo que devuelve registrarse: si la cuenta queda con sesión o no.
  bool registroConSesion = false;

  /// Cuántas veces se llamó a iniciarSesion o registrarse.
  int llamadas = 0;

  @override
  Stream<bool> get cambiosDeSesion => _cambios.stream;

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    llamadas++;
    if (error != null) throw error!;
    this.correo = correo;
    _cambiar(true);
  }

  @override
  Future<bool> registrarse({
    required String correo,
    required String contrasena,
  }) async {
    llamadas++;
    if (error != null) throw error!;
    if (registroConSesion) _cambiar(true);
    return registroConSesion;
  }

  @override
  Future<void> cerrarSesion() async => _cambiar(false);

  void _cambiar(bool sesion) {
    haySesion = sesion;
    _cambios.add(sesion);
  }
}

/// La app con una sesión ya iniciada, para probar las pantallas de gastos.
/// [mes] fija el mes que muestra la lista (por defecto, el actual).
BudgetZlateApp appConSesion(GastosRepository repository, {DateTime? mes}) =>
    BudgetZlateApp(
      repository: repository,
      autenticacion: AutenticacionFalsa(haySesion: true),
      mesInicial: mes,
    );
