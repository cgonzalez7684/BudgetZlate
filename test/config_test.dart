import 'package:budget_zlate/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('problemaDeConfiguracion', () {
    const clave = 'sb_publishable_abc123';

    test('una configuración correcta no tiene problemas', () {
      expect(
        problemaDeConfiguracion(url: 'https://abcd.supabase.co', clave: clave),
        isNull,
      );
      expect(
        problemaDeConfiguracion(url: 'https://abcd.supabase.co/', clave: clave),
        isNull,
      );
    });

    test('valores vacíos', () {
      expect(
        problemaDeConfiguracion(url: '', clave: ''),
        contains('Falta la configuración'),
      );
    });

    test('la URL con rutas o sin https se rechaza', () {
      for (final url in [
        'https://abcd.supabase.co/rest/v1/',
        'https://abcd.supabase.co/auth/v1',
        'https://supabase.com/dashboard/project/abcd',
        'abcd.supabase.co',
        'no es una url',
      ]) {
        expect(
          problemaDeConfiguracion(url: url, clave: clave),
          contains('solo la dirección del proyecto'),
          reason: url,
        );
      }
    });

    test('la clave secreta se rechaza', () {
      expect(
        problemaDeConfiguracion(
          url: 'https://abcd.supabase.co',
          clave: 'sb_secret_xyz',
        ),
        contains('clave secreta'),
      );
    });
  });
}
