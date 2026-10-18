import 'package:budget_zlate/data/autenticacion_supabase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mensajeDeError', () {
    String mensaje(String? code) =>
        mensajeDeError(AuthApiException('mensaje en inglés', code: code));

    test('traduce los códigos más comunes', () {
      expect(mensaje('invalid_credentials'), 'Correo o contraseña incorrectos');
      expect(mensaje('email_not_confirmed'), contains('Confirma tu correo'));
      expect(mensaje('user_already_exists'), contains('Ya existe una cuenta'));
      expect(mensaje('email_exists'), contains('Ya existe una cuenta'));
      expect(mensaje('weak_password'), contains('demasiado débil'));
      expect(mensaje('over_email_send_rate_limit'), contains('Espera'));
    });

    test('un código desconocido da un mensaje genérico en español', () {
      expect(mensaje('codigo_nuevo'), contains('No se pudo completar'));
      expect(mensaje(null), contains('No se pudo completar'));
    });

    test('un fallo de red pide revisar la conexión', () {
      expect(
        mensajeDeError(AuthRetryableFetchException()),
        contains('Revisa tu conexión'),
      );
    });
  });
}
