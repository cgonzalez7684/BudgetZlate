# Arquitectura

Proyecto educativo: la estructura debe entenderse de un vistazo. Tres piezas: **pantallas**, **modelo** y **repositorio**.

## Estructura propuesta

```
lib/
  main.dart                         # punto de entrada; crea el repositorio (y Supabase en T4)
  app.dart                          # MaterialApp, tema, pantalla inicial
  models/
    gasto.dart                      # clase Gasto (inmutable)
    categoria.dart                  # enum Categoria
  data/
    gastos_repository.dart          # contrato (clase abstracta)
    gastos_repository_memoria.dart  # implementación en memoria (tareas 1-3)
    gastos_repository_supabase.dart # implementación con Supabase (tarea 4)
  screens/
    lista_gastos_screen.dart
    formulario_gasto_screen.dart    # sirve para crear y editar
    acceso_screen.dart              # tarea 4
    resumen_screen.dart             # tarea 5 (puede integrarse en la lista)
  utils/
    formato_moneda.dart             # céntimos <-> texto ₡
    formato_fecha.dart              # DateTime -> dd/mm/aaaa
test/                               # refleja la estructura de lib/
```

Los archivos se crean cuando la tarea los necesita, no antes.

## Modelo `Gasto`

```dart
enum Categoria { alimentacion, transporte, servicios, otros }

class Gasto {
  final String id;           // uuid; en memoria puede generarse localmente
  final String descripcion;
  final int montoCentimos;   // ₡1 500,00 => 150000
  final Categoria categoria;
  final DateTime fecha;      // solo importa el día
}
```

- Inmutable (`final` + `copyWith`) para que editar sea crear una copia modificada.
- Cada `Categoria` tiene una etiqueta en español para la interfaz ("Alimentación", etc.).
- `fromMap` / `toMap` se añaden en la tarea 4 para convertir desde y hacia Supabase.

### Montos en unidades menores enteras

`double` no representa exactamente valores como 0,1, así que sumar montos puede dar `0.30000000000000004`. Por eso:

- Se guarda `int montoCentimos` (1 colón = 100 céntimos, según ISO 4217).
- Se convierte a texto solo al mostrar, y de texto a entero al leer el formulario, sin pasar por `double`.
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

- El contrato crece por tareas: en T1 solo tiene `obtenerGastos()`; `agregar` llega en T2 y `actualizar`/`eliminar` en T3.
- Es la única abstracción del proyecto. Se justifica porque permite **empezar en memoria y cambiar a Supabase sin tocar las pantallas**, y usar la versión en memoria en las pruebas.
- Los métodos son `Future` desde el principio, aunque la versión en memoria no lo necesite, para que el cambio a Supabase no altere la interfaz.
- El filtro mensual y el resumen son **funciones puras** sobre `List<Gasto>` (fáciles de probar sin Supabase). Si el volumen creciera, el filtro podría pasarse a la consulta.

## Estado y navegación

- `StatefulWidget` + `setState` y `Navigator.push`/`pop`. Sin paquetes de gestión de estado ni de rutas en la versión 1.
- El repositorio se crea en `main.dart` y se pasa por constructor a `BudgetZlateApp` (`app.dart`) y de ahí a las pantallas. Así las pruebas pueden usar sus propios datos.
- Si el estado compartido se complica, la primera opción a evaluar es `ChangeNotifier` del propio SDK.

## Supabase (tarea 4)

Dependencia prevista: `supabase_flutter` (cliente oficial: auth, sesión persistente y consultas). Se justificará y confirmará al llegar a la tarea.

Tabla (el SQL se versionará en `supabase/migrations/` o `docs/`):

```sql
create table public.gastos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  descripcion text not null check (length(trim(descripcion)) > 0),
  monto_centimos bigint not null check (monto_centimos > 0),
  categoria text not null check (categoria in ('alimentacion','transporte','servicios','otros')),
  fecha date not null,
  creado_en timestamptz not null default now()
);

alter table public.gastos enable row level security;

create policy "leer propios"       on public.gastos for select using (auth.uid() = user_id);
create policy "crear propios"      on public.gastos for insert with check (auth.uid() = user_id);
create policy "actualizar propios" on public.gastos for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "eliminar propios"   on public.gastos for delete using (auth.uid() = user_id);
```

- La app usa solo la URL y la clave pública, pasadas con `--dart-define`. Nunca `service_role`.
- La seguridad no depende de filtrar por `user_id` en la app: RLS lo impone en el servidor.

## Decisiones descartadas

- **CQRS, casos de uso, capa de dominio separada, DTOs**: demasiada ceremonia para cuatro operaciones.
- **Paquetes de estado (Provider, Riverpod, Bloc) y de inyección de dependencias**: se aprenden mejor después de entender `setState`.
- **`double` para dinero**: errores de precisión.
- **Generación de código (freezed, json_serializable)**: el modelo es pequeño; se escribe a mano para entenderlo.
