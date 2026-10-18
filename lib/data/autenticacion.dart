/// Contrato para iniciar y cerrar sesión.
///
/// Igual que con `GastosRepository`, las pantallas solo conocen este
/// contrato: la app usa Supabase y las pruebas usan una versión falsa que no
/// necesita red.
abstract class Autenticacion {
  /// Si hay un usuario con sesión iniciada ahora mismo.
  bool get haySesion;

  /// Correo del usuario con sesión, o `null`.
  String? get correo;

  /// Emite `true` al iniciar sesión y `false` al cerrarla.
  Stream<bool> get cambiosDeSesion;

  /// Lanza [ErrorAutenticacion] si no se pudo iniciar sesión.
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  /// Crea la cuenta. Devuelve `true` si ya quedó la sesión iniciada, o
  /// `false` si antes hay que confirmar el correo.
  /// Lanza [ErrorAutenticacion] si no se pudo registrar.
  Future<bool> registrarse({
    required String correo,
    required String contrasena,
  });

  Future<void> cerrarSesion();
}

/// Error con un mensaje en español listo para mostrar al usuario.
class ErrorAutenticacion implements Exception {
  const ErrorAutenticacion(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'ErrorAutenticacion: $mensaje';
}
