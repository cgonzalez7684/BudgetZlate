# Arquitectura

Proyecto educativo: la estructura debe entenderse de un vistazo. Tres piezas: **pantallas**, **modelo** y **repositorio**.

## Estructura propuesta

```
lib/
  main.dart                         # punto de entrada; inicializa Supabase y crea repositorio/autenticación
  app.dart                          # MaterialApp, tema y PuertaAcceso (acceso o lista según la sesión)
  config.dart                       # URL y clave pública de Supabase (--dart-define-from-file)
  models/
    gasto.dart                      # clase Gasto (inmutable)
    categoria.dart                  # enum Categoria
  data/
    gastos_repository.dart          # contrato (clase abstracta)
    gastos_repository_memoria.dart  # implementación en memoria (pruebas; app hasta T4a)
    gastos_repository_supabase.dart # implementación con Supabase (T4b, la que usa la app)
    autenticacion.dart              # contrato de autenticación (T4a)
    autenticacion_supabase.dart     # implementación con Supabase Auth (T4a)
  screens/
    lista_gastos_screen.dart
    formulario_gasto_screen.dart    # sirve para crear y editar
    acceso_screen.dart              # tarea 4
    resumen_screen.dart             # tarea 5 (puede integrarse en la lista)
  utils/
    formato_moneda.dart             # céntimos <-> texto ₡
    formato_fecha.dart              # DateTime -> dd/mm/aaaa
test/                               # refleja la estructura de lib/
  apoyo/                            # versiones falsas para pruebas (autenticación, repositorio que falla)
supabase/
  migrations/                       # SQL versionado de la base de datos (tabla gastos + RLS)
  verificar_rls.sql                 # consultas de comprobación (solo lectura)
config/
  supabase.example.json             # plantilla; la copia real (supabase.json) está en .gitignore
```

Los archivos se crean cuando la tarea los necesita, no antes.

## Modelo `Gasto`

```dart
enum Categoria { alimentacion, transporte, servicios, otros }

class Gasto {
  final String? id;          // null hasta guardarse; lo asigna el repositorio
  final String descripcion;
  final int montoCentimos;   // ₡1 500,00 => 150000
  final Categoria categoria;
  final DateTime fecha;      // solo importa el día
}
```

- Inmutable (`final` + `copyWith`) para que editar sea crear una copia modificada.
- Cada `Categoria` tiene una etiqueta en español para la interfaz ("Alimentación", etc.).
- `id` es opcional porque un gasto recién salido del formulario aún no existe en el almacenamiento. En memoria se genera `memoria-N`; en Supabase lo generará la base de datos (`gen_random_uuid()`).
- `fromMap` / `toMap` se añaden en la tarea 4 para convertir desde y hacia Supabase.

### Montos en unidades menores enteras

`double` no representa exactamente valores como 0,1, así que sumar montos puede dar `0.30000000000000004`. Por eso:

- Se guarda `int montoCentimos` (1 colón = 100 céntimos, según ISO 4217).
- Se convierte a texto solo al mostrar (`formatearColones`), y de texto a entero al leer el formulario (`convertirACentimos`), sin pasar por `double`. Se acepta coma o punto decimal, máximo 2 decimales.
- En la base de datos, columna `bigint`.

## Repositorio

```dart
abstract class GastosRepository {
  Future<List<Gasto>> obtenerGastos();
  Future<void> agregar(Gasto gasto);
  Future<void> actualizar(Gasto gasto);
  Future<void> eliminar(String id);
}
```

- El contrato se completó por tareas: `obtenerGastos()` en T1, `agregar` en T2 y `actualizar`/`eliminar` en T3.
- Tras cada operación, la lista crea un `Future` nuevo que espera la operación y vuelve a leer los gastos (`_recargarTras`); el `FutureBuilder` se encarga del resto.
- Se justifica porque permite **empezar en memoria y cambiar a Supabase sin tocar las pantallas**, y usar la versión en memoria en las pruebas.
- Los métodos son `Future` desde el principio, aunque la versión en memoria no lo necesite, para que el cambio a Supabase no altere la interfaz.
- El filtro mensual y el resumen son **funciones puras** sobre `List<Gasto>` (fáciles de probar sin Supabase). Si el volumen creciera, el filtro podría pasarse a la consulta.

## Estado y navegación

- `StatefulWidget` + `setState` y `Navigator.push`/`pop`. Sin paquetes de gestión de estado ni de rutas en la versión 1.
- El formulario no conoce el repositorio: devuelve el `Gasto` con `Navigator.pop` y la lista lo guarda y recarga. Sirve para crear (`gasto: null`) y editar (recibe el gasto y conserva su `id`).
- Eliminar: deslizar la fila (`Dismissible`) + diálogo de confirmación + `SnackBar`.
- Idioma: `flutter_localizations` (incluido en el SDK) con `locale: es_CR`, para que los textos de Material (selector de fecha, etc.) salgan en español aunque el teléfono esté en otro idioma.
- El repositorio se crea en `main.dart` y se pasa por constructor a `BudgetZlateApp` (`app.dart`) y de ahí a las pantallas. Así las pruebas pueden usar sus propios datos.
- Si el estado compartido se complica, la primera opción a evaluar es `ChangeNotifier` del propio SDK.

## Autenticación (T4a)

```dart
abstract class Autenticacion {
  bool get haySesion;
  String? get correo;
  Stream<bool> get cambiosDeSesion;
  Future<void> iniciarSesion({required String correo, required String contrasena});
  Future<bool> registrarse({required String correo, required String contrasena}); // true = ya con sesión
  Future<void> cerrarSesion();
}
```

- Segunda (y última prevista) abstracción, por el mismo motivo que el repositorio: la app usa `AutenticacionSupabase` y las pruebas `AutenticacionFalsa` (`test/apoyo/`), sin red.
- Los errores de Supabase se traducen a `ErrorAutenticacion` con mensaje en español (`mensajeDeError`, por `code`).
- `PuertaAcceso` (en `app.dart`) escucha `cambiosDeSesion` con un `StreamBuilder` y muestra `AccesoScreen` o `ListaGastosScreen`. Ninguna pantalla navega al iniciar/cerrar sesión.
- La sesión la guarda `supabase_flutter` en el dispositivo; al reabrir la app se usa `haySesion` como valor inicial.
- Se mantiene la confirmación de correo de Supabase: tras registrarse, la app pide revisar el correo. El enlace del correo redirige a la "Site URL" del proyecto (por defecto `localhost`); la página no carga en el teléfono, pero la cuenta queda confirmada.

## Supabase (tarea 4)

Dependencia: `supabase_flutter` ^2.18.3 (cliente oficial: auth, sesión persistente y consultas). Aprobada en T4a. Se inicializa en `main.dart` con `Supabase.initialize(url:, publishableKey:)`.

Configuración: `lib/config.dart` lee `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` con `String.fromEnvironment`, que se pasan con `--dart-define-from-file=config/supabase.json` (archivo ignorado por git; plantilla en `config/supabase.example.json`). Sin ellos, la app muestra un aviso en lugar de fallar.

Tabla y RLS (T4b): el SQL vigente está en `supabase/migrations/20261017000000_crear_gastos.sql` y se aplica pegándolo en el SQL Editor (se puede repetir sin error). Resumen:

- `public.gastos`: `id` uuid (generado), `user_id` (por defecto `auth.uid()`, borra en cascada con el usuario), `descripcion` no vacía, `monto_centimos` bigint > 0, `categoria` en ('alimentacion','transporte','servicios','otros'), `fecha` date, `creado_en`.
- Índice `(user_id, fecha desc)`.
- Permisos: nada para `anon`; `select/insert/update/delete` para `authenticated`.
- RLS activo con 4 políticas (leer, crear, actualizar, eliminar) que exigen `(select auth.uid()) = user_id`.
- Comprobaciones de solo lectura: `supabase/verificar_rls.sql`.

`GastosRepositorySupabase` (`lib/data/`) implementa el contrato con `from('gastos')`:
- `obtenerGastos`: `select()` ordenado por `fecha` y `creado_en` descendentes. No filtra por usuario: lo hace RLS.
- `agregar`: `insert(gasto.toMap())`; `id` y `user_id` los pone la base de datos.
- `actualizar` / `eliminar`: filtran por `id` y piden `.select('id')`; si no afectan ninguna fila lanzan `StateError` (igual que en memoria).
- `Gasto.fromMap` / `toMap` convierten entre la fila (snake_case, fecha `YYYY-MM-DD`) y el modelo.

Errores de red (pantalla de lista): si falla la carga, mensaje + botón "Reintentar"; si falla guardar/eliminar, `SnackBar` en español y se recarga la lista para mostrar lo que hay realmente guardado. El detalle técnico solo se registra en consola en modo debug (`[BudgetZlate] Error de datos: …`).

- La app usa solo la URL y la clave pública (publishable, `sb_publishable_...`, o la `anon` antigua), pasadas con `--dart-define-from-file`. Nunca `service_role` ni `sb_secret_...`.
- La seguridad no depende de filtrar por `user_id` en la app: RLS lo impone en el servidor.

## Decisiones descartadas

- **CQRS, casos de uso, capa de dominio separada, DTOs**: demasiada ceremonia para cuatro operaciones.
- **Paquetes de estado (Provider, Riverpod, Bloc) y de inyección de dependencias**: se aprenden mejor después de entender `setState`.
- **`double` para dinero**: errores de precisión.
- **Generación de código (freezed, json_serializable)**: el modelo es pequeño; se escribe a mano para entenderlo.
