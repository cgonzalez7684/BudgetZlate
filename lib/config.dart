/// Configuración de Supabase, leída al compilar con
/// `--dart-define-from-file=config/supabase.json`.
///
/// `String.fromEnvironment` se resuelve en tiempo de compilación: los valores
/// no están en el código fuente ni en git, solo en el archivo local.
/// Solo va aquí la clave pública (publishable/anon); nunca la secreta.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

/// Revisa el formato de la configuración (sin conectarse a nada).
/// Devuelve qué está mal, o `null` si parece correcta.
String? problemaDeConfiguracion({
  String url = supabaseUrl,
  String clave = supabasePublishableKey,
}) {
  if (url.isEmpty || clave.isEmpty) {
    return 'Falta la configuración de Supabase.';
  }

  final uri = Uri.tryParse(url);
  final soloDireccion =
      uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty &&
      (uri.path.isEmpty || uri.path == '/') &&
      !uri.hasQuery;
  if (!soloDireccion) {
    return 'SUPABASE_URL debe ser solo la dirección del proyecto, por '
        'ejemplo https://abcdefgh.supabase.co (sin /rest/v1 ni otras rutas).';
  }

  if (clave.startsWith('sb_secret_')) {
    return 'SUPABASE_PUBLISHABLE_KEY contiene la clave secreta. Usa la '
        'publishable (sb_publishable_...) y nunca pongas la secreta en la app.';
  }
  return null;
}
