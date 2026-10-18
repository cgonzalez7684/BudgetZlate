# Progreso

Última actualización: 2026-10-11

## Estado actual

T1 completada: la app abre en una lista de gastos de ejemplo en memoria. No hay formulario, autenticación ni Supabase.

### Informado por el usuario (no verificado por el agente)

- Flutter y Android SDK configurados; la app de ejemplo (contador) se ejecutaba en el emulador. Ya verificado indirectamente en T1 (ver abajo).

### Verificado directamente por el agente

**T0 (2026-10-11), estado inicial**

| Comprobación | Resultado |
|--------------|-----------|
| Acceso de lectura y escritura a la carpeta | OK |
| `flutter --version` | Flutter 3.47.7 (stable), Dart 3.13.5 |
| `flutter doctor` | Android toolchain (SDK 36.0.0) OK. Aviso de Visual Studio: solo afecta a escritorio Windows, no aplica |
| `flutter devices` | Emulador `emulator-5554` (Android 17, API 37) |

**T1 (2026-10-11)**

| Comprobación | Resultado |
|--------------|-----------|
| `dart format lib test` | Reformateó 2 archivos; después `--set-exit-if-changed` sin cambios |
| `flutter analyze` | No issues found |
| `flutter test` | 12 pruebas, todas pasan (formato de moneda y fecha, orden del repositorio, pantalla con datos, lista vacía, datos de ejemplo) |
| `flutter build apk --debug` + instalación con `adb` en `emulator-5554` | OK |
| Revisión visual (captura con `adb exec-out screencap`) | Título "BudgetZlate", 5 gastos ordenados por fecha, categoría en español, fechas dd/mm/aaaa, montos como `₡23 500,75` |
| Dependencias nuevas | Ninguna |

No verificado: la app no se ejecutó con `flutter run` (hot reload); se instaló el APK de depuración y se abrió con `adb`.

## Tareas

- [x] T0 — Documentación base
- [x] T1 — Lista de gastos de ejemplo
- [ ] T2 — Formulario para agregar gastos ← **próxima tarea**
- [ ] T3 — Edición y eliminación
- [ ] T4 — Autenticación (T4a) y persistencia con RLS (T4b) en Supabase
- [ ] T5 — Filtro y resumen mensual

## Pendientes

- Decidir si hacer el primer commit (el repositorio no tiene ninguno).
- T2: el selector de fecha (`showDatePicker`) aparecerá en inglés salvo que se añada `flutter_localizations` (paquete del SDK de Flutter); decidirlo al empezar T2.
- El nombre del icono de la app en Android sigue siendo `budget_zlate` (`android/app/src/main/AndroidManifest.xml`). Fuera de T1; cambiarlo cuando se decida.
- Antes de T4: crear el proyecto en Supabase y tener a mano la URL y la clave pública (nunca `service_role`).
- Antes de T4: añadir a `.gitignore` el archivo de credenciales que se use con `--dart-define-from-file`.
