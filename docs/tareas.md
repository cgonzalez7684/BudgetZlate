# Tareas

Una tarea a la vez, en orden. Cada una termina con formato, `flutter analyze` sin problemas, `flutter test` en verde y `docs/progreso.md` actualizado.

Estado: `[ ]` pendiente · `[~]` en curso · `[x]` terminada

---

## [x] T0 — Documentación base

Crear `CLAUDE.md` y `docs/` (alcance, arquitectura, tareas, progreso) sin modificar el código.

---

## [x] T1 — Lista de gastos de ejemplo

**Objetivo:** reemplazar la app contador por una lista de gastos con datos en memoria.

**Conceptos:** clases inmutables y `enum` en Dart, `StatelessWidget` vs `StatefulWidget`, `ListView.builder`, `Future`/`FutureBuilder`, pruebas unitarias y de widget.

**Incluye:** `Gasto`, `Categoria`, `GastosRepository` + implementación en memoria con 4-5 gastos de ejemplo, `formato_moneda.dart`, `ListaGastosScreen`. Sustituir la prueba del contador.

**Criterios de aceptación:**
- La app se titula "BudgetZlate" y abre en la lista de gastos.
- Cada elemento muestra descripción, categoría en español, fecha (dd/mm/aaaa) y monto en CRC (`₡12 500,00`).
- Gastos ordenados por fecha, del más reciente al más antiguo.
- Con el repositorio vacío se muestra "No hay gastos registrados".
- No queda código ni prueba del contador.

**Verificación:**
- Prueba unitaria de `formato_moneda` (0, 5, 150000, 1234567 céntimos).
- Prueba de widget: la lista muestra los gastos de ejemplo; con repositorio vacío muestra el mensaje.
- Manual: `flutter run` en el emulador.

**Resultado (2026-10-11):** completada. 12 pruebas en verde; revisión visual en el emulador con captura de pantalla. `GastosRepository` solo tiene `obtenerGastos()`; los demás métodos se añaden en T2 y T3.

---

## [ ] T2 — Formulario para agregar gastos

**Objetivo:** crear gastos desde un formulario.

**Conceptos:** `Form`, `TextFormField`, validadores, `TextEditingController` y `dispose`, `DropdownButtonFormField`, `showDatePicker`, navegación con `Navigator.push` devolviendo un resultado.

**Criterios de aceptación:**
- Un botón flotante abre `FormularioGastoScreen`.
- Campos: descripción, monto (₡), categoría (las 4) y fecha (por defecto hoy).
- Mensajes en español si la descripción está vacía o el monto está vacío, es 0, negativo, no numérico o tiene más de 2 decimales.
- El monto se convierte de texto a céntimos sin usar `double` (`"1500"` → 150000, `"0,5"` → 50).
- Al guardar se vuelve a la lista y el gasto aparece.

**Verificación:**
- Prueba unitaria de la conversión texto → céntimos (casos válidos e inválidos).
- Prueba de widget: guardar con campos vacíos muestra errores; un gasto válido aparece en la lista.
- Manual en el emulador.

---

## [ ] T3 — Edición y eliminación

**Objetivo:** modificar y borrar gastos existentes.

**Conceptos:** reutilizar un formulario para crear/editar, `copyWith`, `showDialog`, `Dismissible` o menú de acciones, `SnackBar`.

**Criterios de aceptación:**
- Tocar un gasto abre el formulario con sus datos; al guardar se actualiza en la lista (mismo `id`).
- Eliminar pide confirmación; al confirmar el gasto desaparece y se muestra un `SnackBar`; al cancelar no cambia nada.

**Verificación:**
- Pruebas unitarias del repositorio en memoria (agregar, actualizar, eliminar).
- Prueba de widget: editar cambia el texto mostrado; eliminar con confirmación lo quita; cancelar lo conserva.
- Manual en el emulador.

---

## [ ] T4 — Autenticación y persistencia en Supabase con RLS

Se divide en dos partes que se entregan por separado.

### T4a — Autenticación

**Conceptos:** proyecto Supabase, clave pública vs `service_role`, `--dart-define`, `Supabase.initialize`, sesión y `onAuthStateChange`.

**Requisito previo (usuario):** crear el proyecto en Supabase y facilitar URL y clave pública fuera del repositorio.

**Criterios de aceptación:**
- Dependencia `supabase_flutter` justificada y aprobada.
- Credenciales leídas con `String.fromEnvironment`; ninguna en el código ni en git.
- Pantalla de acceso con registro, inicio de sesión y errores en español.
- Sin sesión se muestra la pantalla de acceso; con sesión, la lista (aún en memoria). Botón para cerrar sesión.
- La sesión se mantiene al reabrir la app.

**Verificación:**
- Manual: registrar, cerrar sesión, iniciar sesión, reabrir app.
- `git grep -i -E "service_role|eyJ"` sin resultados en código versionado.
- Prueba de widget de la pantalla de acceso (validación de campos, sin red).

### T4b — Persistencia y RLS

**Conceptos:** SQL en Supabase, RLS y políticas, `fromMap`/`toMap`, manejo de errores de red.

**Criterios de aceptación:**
- Tabla `gastos` y políticas creadas con el SQL de `arquitectura.md`, versionado en el repositorio.
- `GastosRepositorySupabase` implementa el contrato; las pantallas no cambian salvo lo necesario para errores y carga.
- Los gastos persisten tras reabrir la app.
- Con dos usuarios, cada uno ve solo sus gastos.
- Errores de red muestran un mensaje en español sin cerrar la app.

**Verificación:**
- Prueba unitaria de `fromMap`/`toMap`.
- Las pruebas de widget siguen usando el repositorio en memoria.
- Manual con usuarios A y B; en el SQL Editor, comprobar que RLS está activo (`select relrowsecurity from pg_class where relname = 'gastos';`).
- Manual: consulta REST con la clave pública y el token de B no devuelve gastos de A.

---

## [ ] T5 — Filtro y resumen mensual

**Objetivo:** ver los gastos de un mes y sus totales.

**Conceptos:** funciones puras, `fold`/agrupación con `Map`, límites de fechas, pruebas unitarias con casos borde.

**Criterios de aceptación:**
- Selector de mes (anterior / siguiente) con el mes actual por defecto, mostrado en español ("octubre 2026").
- La lista muestra solo gastos del mes elegido, incluidos el día 1 y el último día.
- Resumen: total del mes y total por cada categoría (las que tienen 0 se muestran como ₡0,00).
- La suma de categorías es igual al total.

**Verificación:**
- Pruebas unitarias de `filtrarPorMes` (límites de mes, febrero bisiesto, diciembre → enero) y `resumenPorCategoria`.
- Prueba de widget: cambiar de mes cambia la lista y los totales.
- Manual en el emulador.
