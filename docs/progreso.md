# Progreso

Última actualización: 2026-10-17

## Estado actual

T4 completada (T4a y T4b): autenticación con Supabase y gastos guardados en la tabla `gastos` con RLS; cada usuario solo ve los suyos. Próxima tarea: T5 (filtro y resumen mensual).

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

## Tareas

- [x] T0 — Documentación base
- [x] T1 — Lista de gastos de ejemplo
- [x] T2 — Formulario para agregar gastos
- [x] T3 — Edición y eliminación
- [x] T4a — Autenticación
- [x] T4b — Persistencia con RLS
- [ ] T5 — Filtro y resumen mensual ← **próxima tarea**

## Pendientes

- Hacer commit de T2, T3, T4a y T4b (están sin confirmar en el árbol de trabajo).
- Probar de principio a fin el correo de confirmación (límite del SMTP gratuito; o configurar SMTP propio).
- Eliminar solo se descubre deslizando la fila; si resulta poco evidente, añadir también un botón "Eliminar" en "Editar gasto".
- Mejora opcional observada en el emulador: los mensajes de error no desaparecen al corregir el campo hasta pulsar "Guardar" otra vez. Se puede cambiar con `autovalidateMode: AutovalidateMode.onUserInteraction` en el `Form`.
- El nombre del icono de la app en Android sigue siendo `budget_zlate` (`android/app/src/main/AndroidManifest.xml`).
