# Progreso

Última actualización: 2026-10-17

## Estado actual

**Versión 1 completa y pulida (2026-10-17):** T0–T6 terminadas y confirmadas en `main` (commits `3832082` T2–T4, `3c88ad6` T5 y el de T6), sin push. No hay más tareas definidas; la siguiente decisión es del usuario (ver "Próximos pasos posibles").

### Informado por el usuario (no verificado por el agente)

- Proyecto de Supabase creado (2026-10-17). El agente no ha visto sus claves ni su configuración.

### Verificado directamente por el agente

**T0 (2026-10-11), estado inicial**

| Comprobación | Resultado |
|--------------|-----------|
| Acceso de lectura y escritura a la carpeta | OK |
| `flutter --version` | Flutter 3.47.7 (stable), Dart 3.13.5 |
| `flutter doctor` | Android toolchain (SDK 36.0.0) OK. Aviso de Visual Studio: solo afecta a escritorio Windows, no aplica |
| `flutter devices` | Emulador `emulator-5554` (Android 17, API 37) |

**T1 (2026-10-11)**: formato, `flutter analyze` y 12 pruebas OK; revisión visual en el emulador OK.

**T2 (2026-10-17)**

| Comprobación | Resultado |
|--------------|-----------|
| `flutter pub get` | OK (añade `flutter_localizations` del SDK) |
| `dart format` / `--set-exit-if-changed` | Reformateó 2 archivos; después sin cambios |
| `flutter analyze` | No issues found |
| `flutter test` | 25 pruebas, todas pasan. Nuevas: `convertirACentimos` (válidos e inválidos), `agregar` del repositorio, formulario (errores con campos vacíos, monto 0 / negativo / no numérico / 3 decimales, gasto válido aparece en la lista, volver sin guardar, selector en español) |
| Error encontrado por las pruebas y corregido | `setState(() => _gastos = ...)` devolvía un `Future`; se cambió a bloque `{ }` |
| Emulador (APK debug + `adb`, capturas) | Errores de validación en español; "Taxi al aeropuerto", `8500,5`, Transporte, fecha 15/10/2026 → aparece primero en la lista como `₡8 500,50`. Selector de fecha en español ("Selecciona una fecha", lunes primero, "Cancelar"/"ACEPTAR") con días futuros deshabilitados |

No verificado: no se usó `flutter run` (hot reload); se instaló el APK de depuración. Las tildes no se probaron escribiendo en el emulador (`adb input text` no las admite); sí se muestran bien en etiquetas.

**T3 (2026-10-17)**

| Comprobación | Resultado |
|--------------|-----------|
| `dart format` / `--set-exit-if-changed` | Sin cambios |
| `flutter analyze` | No issues found |
| `flutter test` | 36 pruebas, todas pasan. Nuevas: `copyWith`, `montoParaEditar` (incluido ida y vuelta con `convertirACentimos`), `actualizar`/`eliminar` del repositorio (y `StateError` con id inexistente), formulario precargado al tocar un gasto, editar conserva el id, eliminar con confirmación + SnackBar, cancelar conserva el gasto |
| Emulador (APK debug + `adb`, capturas) | Tocar "Supermercado" abre "Editar gasto" con `23500,75`, Alimentación y 08/10/2026; cambiar a `25000` → lista muestra `₡25 000,00` sin duplicar. Deslizar "Pasaje de bus" muestra el fondo rojo y el diálogo; "Cancelar" lo conserva; "Eliminar" lo quita y muestra `Se eliminó "Pasaje de bus"` |
| `adb logcat` (líneas de Flutter con error/excepción) | 0 |

**Teléfono del usuario (2026-10-17)**

| Comprobación | Resultado |
|--------------|-----------|
| `flutter devices` | Detecta `SM A556E` (android-arm64, Android 16, API 36) junto al emulador |
| Selección por nombre (`flutter logs -d "SM A556E"`) | OK; se usa el nombre en los comandos para no guardar el número de serie en el repositorio |

Informado por el usuario (no verificado por el agente): la app se ejecuta correctamente en su teléfono. A partir de ahora es el dispositivo de referencia (ver `CLAUDE.md`).

**T4a (2026-10-17)**

| Comprobación | Resultado |
|--------------|-----------|
| `flutter pub add --dry-run` y luego `flutter pub add supabase_flutter` | 2.18.3 (55 dependencias indirectas), aprobada por el usuario |
| `dart format` / `--set-exit-if-changed` | Reformateó 3 archivos de prueba; después sin cambios |
| `flutter analyze` | No issues found |
| `flutter test` | 48 pruebas, todas pasan. Nuevas: pantalla de acceso (sin sesión muestra acceso, sesión guardada abre la lista, validaciones sin llamar a Supabase, inicio de sesión, error en español, registro con confirmación, cerrar sesión, mostrar/ocultar contraseña) y `mensajeDeError` |
| `git grep --untracked -nIE "service_role\|sb_secret_\|eyJ"` (sin docs) | Sin resultados |
| `git check-ignore config/supabase.json` | Ignorado; `config/supabase.example.json` no |
| `flutter build apk --debug` + emulador sin configuración | Muestra "Falta la configuración de Supabase" con el comando a usar |

**Incidente en la prueba manual (2026-10-17):** "Crear cuenta" mostraba el mensaje genérico. Se añadió un registro del error original en modo debug (`[BudgetZlate] Error de Supabase Auth: …`); la consola del usuario mostró `AuthApiException code=null status=404 "Invalid path specified in request URL"`, es decir, `SUPABASE_URL` incluía una ruta además de la dirección del proyecto. Se añadió `problemaDeConfiguracion()` (`lib/config.dart`), que al arrancar detecta URL con rutas, valores vacíos o la clave secreta y muestra el problema en pantalla; 4 pruebas nuevas (52 en total, todas pasan). El patrón de búsqueda de claves de `CLAUDE.md` se afinó para no detectar esa propia comprobación.

**Informado por el usuario (2026-10-17), no verificado por el agente:**

- Con la URL corregida, "Crear cuenta" mostró "Te enviamos un correo…" (la consola no registró errores de Supabase; esto sí lo comprobó el agente leyendo la terminal).
- El correo no llegó porque se escribió mal la dirección. Al reintentar, apareció "Demasiados intentos…" (límite de correos del servicio SMTP gratuito de Supabase).
- El usuario borró la cuenta errónea y creó la suya desde el panel (Authentication → Users → Add user, con "Auto Confirm User").
- **Iniciar sesión en el teléfono funciona** con esa cuenta.

Pendiente: el flujo de confirmación por correo de principio a fin (requiere esperar el límite o configurar SMTP propio).

**Resultado de la prueba manual (informado por el usuario, 2026-10-17):** iniciar sesión, sesión guardada al reabrir, cerrar sesión y contraseña incorrecta: todo bien. **T4a completada.**

**T4b (2026-10-17)**

| Comprobación | Resultado |
|--------------|-----------|
| `dart format` / `--set-exit-if-changed` | Sin cambios |
| `flutter analyze` | No issues found |
| `flutter test` | 59 pruebas, todas pasan. Nuevas: `Gasto.fromMap`/`toMap` (columnas, fecha `YYYY-MM-DD`, ida y vuelta, categoría desconocida) y errores de conexión en la lista (fallo al cargar + "Reintentar", fallo al eliminar, fallo al guardar una edición) |
| Búsqueda de claves (`git grep` de `CLAUDE.md`) | Sin resultados |
| `flutter build apk --debug` | Compila |

No verificado por el agente: nada contra el proyecto real (requiere las claves y la cuenta del usuario).

**Informado por el usuario (2026-10-17), no verificado por el agente:** el SQL se ejecutó sin errores y **todas las pruebas manuales siguientes pasaron**. **T4b completada.** El agente volvió a ejecutar formato, `flutter analyze`, `flutter test` (59 OK) y la búsqueda de claves (sin resultados) antes de cerrarla.

**Pruebas manuales realizadas por el usuario:**

1. Supabase → **SQL Editor**: pegar todo `supabase/migrations/20261017000000_crear_gastos.sql` → **Run** → "Success. No rows returned".
2. SQL Editor: ejecutar `supabase/verificar_rls.sql` → `rls_activo = true` y 4 políticas (DELETE, INSERT, SELECT, UPDATE) para `{authenticated}`.
3. Volver a lanzar la app: `flutter run -d "SM A556E" --dart-define-from-file=config/supabase.json`. Con el usuario A, la lista empieza vacía ("No hay gastos registrados"; los de ejemplo ya no aparecen).
4. Agregar 2 gastos, editar uno y eliminar otro → la lista se actualiza.
5. Cerrar la app por completo y reabrirla → los gastos siguen ahí.
6. Panel → **Table Editor → gastos**: aparecen las filas con el `user_id` de A.
7. Crear el usuario B en Authentication → Users → Add user (con "Auto Confirm User"). En la app: cerrar sesión, entrar como B → lista vacía. Agregar "Gasto de B".
8. Cerrar sesión, entrar como A → solo los gastos de A (no aparece "Gasto de B").
9. SQL Editor: la tercera consulta de `verificar_rls.sql` muestra cuántos gastos tiene cada usuario y coincide con lo visto en la app.
10. Sin sesión, la API no devuelve datos. En la terminal del proyecto (PowerShell), sin mostrar la clave:
    ```powershell
    $c = Get-Content config/supabase.json | ConvertFrom-Json
    Invoke-RestMethod "$($c.SUPABASE_URL)/rest/v1/gastos?select=*" -Headers @{ apikey = $c.SUPABASE_PUBLISHABLE_KEY }
    ```
    Esperado: error "permission denied for table gastos" (401/403). Nunca una lista con gastos.
11. Opcional, si el SQL Editor tiene selector de rol: elegir rol `authenticated` + usuario B, ejecutar `select * from gastos;` → solo los de B.
12. Sin conexión: activar el modo avión, agregar un gasto → aviso "No se pudo guardar el gasto…" y la lista muestra "No se pudieron cargar los gastos" con "Reintentar"; desactivar el modo avión → "Reintentar" → vuelve la lista. La app no se cierra.

**T5 (2026-10-17)**

| Comprobación | Resultado |
|--------------|-----------|
| `git commit` (pedido por el usuario) | `3832082` en `main` con T2–T4; `config/supabase.json` no incluido (`git ls-files config/` → solo el ejemplo) |
| `dart format` / `--set-exit-if-changed` | Reformateó 3 archivos; después sin cambios |
| `flutter analyze` | No issues found |
| `flutter test` | 79 pruebas, todas pasan. Nuevas: `filtrarPorMes` (día 1 y último día, meses vecinos, febrero bisiesto y no bisiesto, diciembre → enero, otro año, hora), `resumenPorCategoria` (totales, categorías en 0, suma = total, lista vacía, céntimos exactos), `mesAnterior`/`mesSiguiente`, `formatearMes`; pantalla: filtro del mes, resumen con ₡0,00, cambiar de mes cambia lista y totales, "siguiente" desactivado en el mes actual, editar la fecha a otro mes salta a ese mes. Pruebas existentes adaptadas (mes fijo y montos buscados dentro de la lista) |
| Emulador con datos de ejemplo en memoria (punto de entrada temporal `lib/main_revision.dart`, ya borrado) | octubre 2026: total ₡44 321,25 (Alimentación ₡25 350,75, Transporte ₡520,00, Servicios ₡18 450,50, Otros ₡0,00), "siguiente" desactivado; septiembre: solo "Corte de cabello" ₡6 000,00; agosto: todo ₡0,00 y "No hay gastos en agosto 2026". `logcat`: 0 errores de Flutter |

No verificado por el agente: la pantalla con datos reales de Supabase (requiere la cuenta del usuario).

**Prueba manual en el teléfono (informada por el usuario, 2026-10-17):** mes actual con › desactivado, resumen con las 4 categorías y suma correcta, salto al mes del gasto guardado, ‹ y › cambian lista y totales: confirmado. **T5 completada.** Antes de cerrarla, el agente volvió a ejecutar formato, `flutter analyze`, `flutter test` (79 OK) y la búsqueda de claves (sin resultados).

## Criterios de aceptación de la versión 1 (`docs/alcance.md`)

| # | Criterio (resumen) | Evidencia |
|---|--------------------|-----------|
| A1 | Sin sesión, pantalla de acceso | Prueba de widget (`acceso_screen_test`) + usuario en el teléfono (T4a) |
| A2 | Registro, inicio y cierre de sesión | Pruebas de widget + usuario en el teléfono. El correo de confirmación de principio a fin quedó pendiente (límite del SMTP gratuito) |
| A3 | Crear gasto válido | Prueba de widget + emulador (T2) + usuario con Supabase (T4b) |
| A4 | Validaciones del formulario en español | Pruebas de widget (T2) + emulador |
| A5 | Editar gasto | Pruebas de widget + emulador (T3) + usuario con Supabase (T4b) |
| A6 | Eliminar con confirmación | Pruebas de widget + emulador (T3) + usuario con Supabase (T4b) |
| A7 | Persistencia tras reabrir | Usuario en el teléfono (T4b) |
| A8 | Usuario B no ve ni modifica gastos de A | Usuario: app con A y B, SQL de verificación y REST sin sesión denegado (T4b) |
| A9 | Filtro mensual con día 1 y último día | Pruebas unitarias y de widget (T5) + emulador + usuario |
| A10 | Total y por categoría; suma = total | Pruebas unitarias y de widget (T5) + emulador + usuario |
| A11 | Formato CRC sin errores de redondeo | Pruebas unitarias (`formato_moneda_test`, `resumen_mensual_test`) |
| A12 | Sin `service_role` ni credenciales en el repositorio | `git grep` de `CLAUDE.md` sin resultados; `config/supabase.json` ignorado y fuera del commit `3832082` |
| A13 | `flutter analyze` sin problemas y `flutter test` en verde | Ejecutados por el agente: sin problemas, 79 pruebas OK |

## Tareas

- [x] T0 — Documentación base
- [x] T1 — Lista de gastos de ejemplo
- [x] T2 — Formulario para agregar gastos
- [x] T3 — Edición y eliminación
- [x] T4a — Autenticación
- [x] T4b — Persistencia con RLS
- [x] T5 — Filtro y resumen mensual
- [x] T6 — Pulido de la versión 1

**T6 (2026-10-17)**

| Comprobación | Resultado |
|--------------|-----------|
| `git commit` de T5 (pedido por el usuario) | `3c88ad6` en `main`; `config/supabase.json` fuera |
| `dart format` / `--set-exit-if-changed` | Sin cambios |
| `flutter analyze` | No issues found |
| `flutter test` | 90 pruebas, todas pasan. Nuevas: sin errores antes del primer intento; error que desaparece al corregir (formulario y acceso); "Nuevo gasto" sin papelera; eliminar desde "Editar gasto" (confirmar y cancelar); reenviar correo (oculto al inicio, tras crear cuenta, con correo sin confirmar, error en español, sin necesitar contraseña) |
| Búsqueda de claves | Sin resultados |
| `aapt2 dump badging` del APK | `application-label:'BudgetZlate'` |
| Emulador con datos en memoria (punto de entrada temporal, ya borrado) | Papelera en "Editar gasto" → "¿Eliminar gasto?" → lista sin "Supermercado", total ₡20 820,50 y `Se eliminó "Supermercado"`; en "Nuevo gasto", el error de Descripción desapareció al escribir "Taxi" y los demás siguieron. `logcat`: 0 errores de Flutter |

No verificado por el agente: el nombre bajo el icono en el lanzador del teléfono, eliminar desde edición con Supabase y el reenvío real del correo.

**Pruebas en el teléfono (confirmadas por el usuario, 2026-10-17; no verificadas por el agente):**

1. `flutter run -d "SM A556E" --dart-define-from-file=config/supabase.json`
2. En el cajón de apps, el icono se llama "BudgetZlate".
3. Tocar un gasto → papelera (arriba a la derecha) → "Cancelar" se queda en el formulario; "Eliminar" vuelve a la lista sin el gasto y muestra el aviso.
4. En "Nuevo gasto": "Guardar" vacío → errores; escribir la descripción → su error desaparece al momento.
5. Opcional (gasta el límite de correos): cerrar sesión, "Crear cuenta" con un correo nuevo → aparece "Reenviar correo de confirmación"; pulsarlo → "Te reenviamos el correo…" o, si se alcanzó el límite, "Demasiados intentos…".

## Pendientes

- Push a GitHub cuando el usuario lo decida.

## Próximos pasos posibles (no son tareas aún; el usuario decide)

- Correo de confirmación de principio a fin: configurar un SMTP propio en Supabase (Resend, Brevo…).

Fuera de alcance de la versión 1 (`docs/alcance.md`), candidatos para una versión 2: comprobantes o fotos de recibos, notificaciones, funcionamiento sin conexión, categorías personalizadas, presupuestos, gráficos, exportación.
