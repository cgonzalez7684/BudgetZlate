import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'autenticacion.dart';

/// Autenticación con correo y contraseña usando Supabase Auth.
///
/// `supabase_flutter` guarda la sesión en el teléfono, así que al reabrir la
/// app el usuario sigue dentro sin volver a escribir la contraseña.
class AutenticacionSupabase implements Autenticacion {
  AutenticacionSupabase(this._auth);

  final GoTrueClient _auth;

  @override
  bool get haySesion => _auth.currentSession != null;

  @override
  String? get correo => _auth.currentUser?.email;

  // `late final`: se crea una sola vez, la primera vez que se usa, y así
  // quien lo escuche recibe siempre el mismo stream.
  @override
  late final Stream<bool> cambiosDeSesion = _auth.onAuthStateChange
      .map((estado) => estado.session != null)
      // Si falla la renovación automática del token (p. ej. sin internet),
      // el stream emite un error. Se ignora: la sesión sigue como estaba.
      .handleError((Object _) {});

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _auth.signInWithPassword(email: correo, password: contrasena);
    } on AuthException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<bool> registrarse({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final respuesta = await _auth.signUp(email: correo, password: contrasena);
      // Con la confirmación de correo activada, Supabase crea el usuario
      // pero no devuelve sesión hasta que se confirme.
      return respuesta.session != null;
    } on AuthException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> reenviarConfirmacion({required String correo}) async {
    try {
      await _auth.resend(type: OtpType.signup, email: correo);
    } on AuthException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  /// Registra el error original (solo en modo debug, en la consola de
  /// `flutter run`) y lo convierte en un mensaje en español.
  ErrorAutenticacion _traducir(AuthException error) {
    if (kDebugMode) {
      debugPrint(
        '[BudgetZlate] Error de Supabase Auth: tipo=${error.runtimeType} '
        'code=${error.code} status=${error.statusCode} '
        'mensaje=${error.message}',
      );
    }
    return ErrorAutenticacion(
      mensajeDeError(error),
      correoSinConfirmar: error.code == 'email_not_confirmed',
    );
  }
}

/// Traduce los errores de Supabase Auth a mensajes en español.
///
/// Se usa el `code` del error (estable) y no el `message` (texto en inglés
/// que puede cambiar). Lista de códigos:
/// https://supabase.com/docs/guides/auth/debugging/error-codes
String mensajeDeError(AuthException error) {
  if (error is AuthRetryableFetchException) {
    return 'No se pudo conectar. Revisa tu conexión a internet.';
  }
  return switch (error.code) {
    'invalid_credentials' => 'Correo o contraseña incorrectos',
    'email_not_confirmed' =>
      'Confirma tu correo (revisa tu bandeja de entrada) y vuelve a intentarlo',
    'user_already_exists' ||
    'email_exists' => 'Ya existe una cuenta con ese correo',
    'weak_password' => 'La contraseña es demasiado débil',
    'email_address_invalid' || 'validation_failed' => 'Correo no válido',
    'over_email_send_rate_limit' || 'over_request_rate_limit' =>
      'Demasiados intentos. Espera unos minutos y vuelve a intentarlo',
    'signup_disabled' => 'El registro de cuentas está desactivado',
    _ => 'No se pudo completar la operación. Inténtalo de nuevo',
  };
}
