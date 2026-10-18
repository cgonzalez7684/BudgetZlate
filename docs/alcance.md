# Alcance — versión 1

## Objetivo

Una persona registra sus gastos personales, los consulta por mes y ve cuánto gastó en cada categoría. Sus datos se guardan en Supabase y nadie más puede verlos.

## Incluido

1. **Acceso con Supabase**: registro, inicio y cierre de sesión con correo y contraseña (Supabase Auth).
2. **CRUD de gastos**: crear, listar, editar y eliminar.
3. **Filtro mensual**: ver los gastos de un mes concreto (por defecto, el mes actual).
4. **Resumen por categoría**: total del mes y total por categoría.

### Reglas del dominio

- Interfaz completamente en **español**.
- Moneda única: **colón costarricense (CRC)**, mostrada con el símbolo `₡` (p. ej. `₡12 500,00`).
- Los montos se guardan como **enteros en céntimos** (unidad menor). Ver `arquitectura.md`.
- Un gasto tiene: descripción, monto, categoría y fecha.
- Categorías fijas iniciales: **Alimentación, Transporte, Servicios, Otros**.
- El monto debe ser mayor que cero; la descripción no puede estar vacía.
- **Cada usuario solo puede leer, crear, editar y eliminar sus propios gastos**, garantizado en la base de datos mediante **RLS** (Row Level Security), no solo en la app.

## Criterios de aceptación de la versión

| # | Criterio | Cómo se verifica |
|---|----------|------------------|
| A1 | Sin sesión, la app muestra la pantalla de acceso y no permite ver gastos. | Manual en emulador. |
| A2 | Un usuario puede registrarse, iniciar y cerrar sesión. | Manual en emulador + usuario visible en Supabase Auth. |
| A3 | Se puede crear un gasto válido y aparece en la lista. | Prueba de widget + manual. |
| A4 | El formulario rechaza monto vacío, cero, negativo o no numérico, y descripción vacía, mostrando un mensaje en español. | Prueba de widget. |
| A5 | Se puede editar un gasto y el cambio se refleja en la lista. | Prueba de widget + manual. |
| A6 | Se puede eliminar un gasto tras confirmar, y desaparece de la lista. | Prueba de widget + manual. |
| A7 | Los gastos persisten tras cerrar y reabrir la app. | Manual en emulador. |
| A8 | El usuario B no ve ni puede modificar gastos del usuario A, aunque haga la consulta directamente con la clave pública. | Manual con dos usuarios + consulta SQL/REST documentada. |
| A9 | El filtro mensual muestra solo gastos con fecha dentro del mes elegido (incluye día 1 y último día). | Prueba unitaria. |
| A10 | El resumen muestra el total del mes y el total por categoría, y la suma por categorías es igual al total. | Prueba unitaria. |
| A11 | Los montos se muestran en formato CRC y no hay errores de redondeo (p. ej. 0,10 + 0,20 = 0,30). | Prueba unitaria. |
| A12 | La app no contiene la clave `service_role` ni credenciales en el repositorio. | Búsqueda en el repositorio (`git grep`). |
| A13 | `flutter analyze` sin problemas y `flutter test` en verde. | Comandos. |

## Fuera de alcance (versiones futuras)

- Comprobantes o fotos de recibos.
- Notificaciones y recordatorios.
- Funcionamiento sin conexión y sincronización.
- Otras monedas o conversión de divisas.
- Categorías personalizadas, presupuestos, ingresos, gráficos, exportación.
- Inicio de sesión con proveedores externos (Google, Apple, etc.).
- iOS, web y escritorio (la referencia es Android).
