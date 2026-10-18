# BudgetZlate — instrucciones para el agente

App educativa de gastos personales con Flutter, Dart y Supabase. El objetivo es **aprender** mientras se construye, así que el proceso importa tanto como el resultado.

## Al iniciar una tarea, leer en este orden

1. `docs/progreso.md`: estado actual y próxima tarea.
2. `docs/tareas.md`: criterios de aceptación y verificación de la tarea.
3. `docs/alcance.md`: qué entra y qué no en la versión 1.
4. `docs/arquitectura.md`: estructura de carpetas, modelo y decisiones técnicas.

Si algo de lo que se pide contradice estos documentos, señalarlo antes de implementar.

## Forma de trabajo

- Explicar siempre en **español**. El código (identificadores) puede ir en español, siguiendo `docs/arquitectura.md`.
- **Enseñar** cada concepto nuevo de Flutter, Dart o Supabase la primera vez que aparece: qué es, por qué se usa aquí y una alternativa descartada si es relevante. Breve, sin tutoriales largos.
- Implementar **una sola tarea a la vez**. No adelantar trabajo de tareas futuras.
- Mantener la **arquitectura sencilla**: pantallas, modelo `Gasto` y repositorio. Nada de CQRS, casos de uso, inyección de dependencias con paquetes ni capas extra sin motivo concreto.
- **Justificar cada dependencia** nueva antes de añadirla (qué resuelve, por qué no basta el SDK) y esperar confirmación.
- **Respetar cambios existentes**: revisar `git status` y leer los archivos antes de editarlos. No sobrescribir ni revertir cambios del usuario. No hacer commits salvo que se pidan.

## Comandos

```bash
flutter pub get                                             # instalar dependencias
dart format lib test                                        # formatear
dart format --output=none --set-exit-if-changed lib test    # comprobar formato sin modificar
flutter analyze                                             # análisis estático (lints)
flutter test                                                # pruebas
flutter run -d "SM A556E" --dart-define-from-file=config/supabase.json      # teléfono del usuario (referencia)
flutter run -d emulator-5554 --dart-define-from-file=config/supabase.json  # emulador (alternativa)
git grep --untracked -nIE "service_role|sb_secret_[A-Za-z0-9_-]{10,}|eyJ[A-Za-z0-9_-]{20,}" -- . ':!docs/*' ':!CLAUDE.md'  # no debe encontrar claves
```

`config/supabase.json` está en `.gitignore`: lo crea el usuario a partir de `config/supabase.example.json`. El agente no lo lee ni pide su contenido.

Antes de dar una tarea por terminada: formato, `flutter analyze` sin problemas y `flutter test` en verde.

### Dispositivo de referencia

- La app se ejecuta en el **teléfono del usuario** (Samsung SM A556E, Android 16), conectado por USB.
- El agente no interactúa con el teléfono (tocar, escribir, deslizar): es un dispositivo personal. Las pruebas manuales en el teléfono las hace el usuario, siguiendo los pasos que el agente le indique.
- El agente puede usar el **emulador** para sus propias revisiones visuales y lo informa como "verificado en emulador", no "en el teléfono".

## Reporte de verificaciones

- Informar **solo** de las comprobaciones que se ejecutaron de verdad, con su resultado.
- Si una comprobación no se pudo ejecutar (p. ej. probar en el emulador o en el panel de Supabase), decirlo y dar los comandos o pasos exactos para que el usuario la haga.
- Distinguir entre lo verificado y lo supuesto.

## Seguridad con Supabase

- La app usa **solo** la URL del proyecto y la clave pública (`anon` / publishable). Su protección real es RLS.
- **Nunca** incluir la clave `service_role` / secret ni ninguna clave administrativa en la app, en el repositorio ni en ejemplos.
- No versionar credenciales: pasarlas con `--dart-define` o `--dart-define-from-file` sobre un archivo listado en `.gitignore`.

## Al terminar cada tarea

1. Marcar la tarea en `docs/tareas.md`.
2. Actualizar `docs/progreso.md`: qué se hizo, qué se verificó (y cómo), pendientes y próxima tarea.
3. Resumir al usuario los cambios y los conceptos aprendidos.
