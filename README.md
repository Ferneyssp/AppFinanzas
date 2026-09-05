# Finanzas Student 💰

Aplicación móvil de control financiero mensual para estudiantes universitarios,
desarrollada en **Flutter + Dart** para el examen práctico de Ingeniería de
Software de la Universidad de Santander.

Permite registrar ingresos y egresos, consultar el saldo disponible, recibir
alertas cuando el presupuesto se agota, registrar movimientos por comando de
voz y personalizar tema, paleta de colores, alias y el mes activo — todo con
persistencia 100% local (no requiere internet ni backend).

> ⚠️ **Nota honesta sobre este entregable**: este código se escribió en un
> entorno sin el SDK de Flutter instalado y sin acceso de red a `pub.dev`
> (el registro de paquetes de Flutter), por lo que **no pudo compilarse ni
> ejecutarse dentro de ese entorno**. El código fue escrito completo,
> revisado manualmente (balance de llaves/paréntesis, imports, coherencia de
> tipos) y sigue las APIs reales de cada paquete en las versiones indicadas
> en `pubspec.yaml`, pero **debes ejecutar `flutter pub get` y `flutter run`
> en tu propia máquina** para compilarlo, probarlo y corregir cualquier
> detalle menor que surja (por ejemplo, pequeñas diferencias de API entre
> versiones de Flutter). La sección "Puesta en marcha" abajo te guía paso a
> paso, incluyendo un paso necesario que no venía en el prompt original:
> generar las carpetas `android/` e `ios/` con `flutter create`.

---

## 1. Tecnologías utilizadas

| Capa | Tecnología |
|---|---|
| Framework | Flutter (Dart 3, Material 3) |
| Estado | `provider` (ChangeNotifier) |
| Persistencia de movimientos | `sqflite` (SQLite) |
| Persistencia de preferencias | `shared_preferences` |
| Notificaciones locales | `flutter_local_notifications` |
| Reconocimiento de voz | `speech_to_text` + `permission_handler` |
| Formato de moneda/fecha | `intl` |

Se eligió **SQLite** para los movimientos porque el modelo es relacional
(filtros por tipo/categoría/fecha, agregaciones de totales) y **
SharedPreferences** para las preferencias simples (tema, paleta, alias, mes),
que son pares clave-valor sin necesidad de consultas.

---

## 2. Puesta en marcha (léelo con atención)

### Requisitos previos
* Flutter SDK estable instalado (`flutter --version`).
* Android Studio o VS Code con el plugin de Flutter.
* Un emulador Android o dispositivo físico con depuración USB.

### Paso 1 — Generar el proyecto base con las carpetas de plataforma

Este repositorio contiene el **código Dart de la aplicación** (`lib/`,
`pubspec.yaml`) pero no las carpetas `android/` e `ios/`, ya que esas se
generan automáticamente a partir de la versión de Flutter instalada en tu
máquina (contienen Gradle wrappers, `AndroidManifest.xml`, etc. que dependen
de tu SDK local). Para generarlas:

```bash
# Crea un proyecto Flutter nuevo con las carpetas de plataforma
flutter create --org com.udes.finanzas_student finanzas_student_scaffold
```

Luego copia dentro de ese proyecto recién creado:

```bash
cp -r finanzas_student/lib/*        finanzas_student_scaffold/lib/
cp    finanzas_student/pubspec.yaml finanzas_student_scaffold/pubspec.yaml
cp    finanzas_student/analysis_options.yaml finanzas_student_scaffold/
```

(reemplaza el `lib/main.dart` y `pubspec.yaml` generados por los nuestros).

### Paso 2 — Configurar permisos de Android

Edita `android/app/src/main/AndroidManifest.xml` del proyecto generado y
agrega, **dentro de `<manifest>` pero fuera de `<application>`**:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />

<!-- Requerido por el plugin speech_to_text en Android 11+ para poder
     detectar el servicio de reconocimiento de voz del sistema -->
<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

### Paso 3 — Ajustar `minSdkVersion`

En `android/app/build.gradle` (o `build.gradle.kts`), asegúrate de que:

```
minSdkVersion 23   // requerido por sqflite / flutter_local_notifications
```

### Paso 4 — Instalar dependencias y ejecutar

```bash
cd finanzas_student_scaffold
flutter pub get
flutter run
```

### Paso 5 — Generar el APK

```bash
flutter build apk --release
# El archivo queda en build/app/outputs/flutter-apk/app-release.apk
```

### Paso 6 — Subir a un repositorio Git

```bash
git init
git add .
git commit -m "Finanzas Student: primera versión funcional"
git branch -M main
git remote add origin <URL_DE_TU_REPOSITORIO>
git push -u origin main
```

---

## 3. Arquitectura del proyecto

```
lib/
├── main.dart                     # Punto de entrada, providers, tema
├── models/
│   ├── movimiento.dart           # Modelo de datos + enum TipoMovimiento
│   └── categorias.dart           # Catálogos de categorías
├── services/                     # Lógica desacoplada de la UI
│   ├── database_service.dart     # Persistencia SQLite (CRUD)
│   ├── preferencias_service.dart # Persistencia SharedPreferences
│   ├── finance_calculator.dart   # Reglas de negocio puras (saldo, alertas)
│   ├── notificacion_service.dart # Notificaciones locales
│   └── voz_service.dart          # Reconocimiento de voz + intérprete NLP
├── providers/                    # Estado de la app (ChangeNotifier)
│   ├── finance_provider.dart     # Movimientos, totales, CRUD, alertas
│   └── settings_provider.dart    # Tema, paleta, alias, mes activo
├── theme/
│   ├── app_theme.dart            # ThemeData claro/oscuro
│   └── color_palettes.dart       # 3 paletas + colores de estado
├── utils/
│   ├── currency_formatter.dart
│   └── validators.dart
├── screens/                       # 9 pantallas (ver sección 5)
└── widgets/                       # Componentes reutilizables
```

La lógica de cálculo financiero (`FinanceCalculator`) es una clase de
funciones estáticas puras, sin ninguna dependencia de Flutter, para que
pueda probarse de forma aislada (unit tests) y para que la interfaz nunca
decida por su cuenta si un egreso es válido: siempre pregunta al mismo
servicio, ya sea desde un formulario o desde el flujo de voz.

---

## 4. Reglas de negocio implementadas

1. **Los egresos no pueden superar los ingresos.** `FinanceCalculator.validarEgreso`
   recalcula el saldo antes de guardar y bloquea el registro si el saldo
   resultante sería negativo, mostrando el mensaje exacto solicitado
   ("No puedes registrar este gasto...", "Monto máximo permitido: ...").
   Esta validación se aplica tanto al crear como al editar un egreso
   (excluyendo el monto original del cálculo al editar).
2. **Alertas de presupuesto**: normal (>30%), precaución (≤30%), crítico
   (≤10%), calculadas en `FinanceCalculator.calcularNivelAlerta`.
3. **Caso sin ingresos**: si `totalIngresos == 0`, no se calcula porcentaje
   ni se disparan alertas; el dashboard invita a registrar el primer ingreso.
4. **Notificación local en estado crítico**: se dispara una sola vez por mes
   (bandera persistida en `SharedPreferences` con clave `YYYY-MM`) para no
   repetirse en cada reconstrucción de pantalla; si el estado mejora y luego
   vuelve a ser crítico, se notifica de nuevo.
5. **Validaciones de formulario**: descripción obligatoria, monto > 0,
   mensajes de error específicos por campo.

---

## 5. Pantallas implementadas

1. **Dashboard** (`dashboard_screen.dart`) — saludo, alias, mes activo con
   emoji, tarjetas de saldo/ingresos/egresos, estado del presupuesto con
   barra de progreso, accesos a agregar ingreso/egreso, botón de
   micrófono, movimientos recientes.
2. **Registrar ingreso** (`add_income_screen.dart`).
3. **Registrar egreso** (`add_expense_screen.dart`) — con validación de
   saldo en vivo (el botón "Guardar" se deshabilita si el monto excede el
   saldo disponible) y validación de respaldo antes de persistir.
4. **Editar egreso** (`edit_expense_screen.dart`) — re-valida el límite de
   saldo excluyendo el monto original.
5. **Ingresos del mes** (`income_list_screen.dart`) — listado ordenable por
   fecha con total acumulado.
6. **Movimientos / historial** (`movements_screen.dart`) — todos los
   movimientos, filtros por tipo/categoría/fecha, más reciente primero,
   confirmación antes de eliminar.
7. **Registrar por voz** (`voice_capture_screen.dart`) — animación de
   escucha, texto reconocido en vivo, manejo de errores/permiso denegado,
   navega al formulario prellenado para confirmación manual.
8. **Ajustes** (`settings_screen.dart`) — alias, nombre/emoji del mes, tema
   claro/oscuro, paleta (azul/verde/morado), cargar datos demo, eliminar
   todos los movimientos.
9. **Navegación principal** (`main_navigation.dart`) — barra inferior:
   Inicio, Movimientos, Agregar (hoja modal), Ajustes.

---

## 6. Comando de voz: ejemplos soportados

El intérprete (`VozService.interpretarTexto`) reconoce montos en dígitos
(`20000`, `20.000`) y en palabras comunes en español colombiano (`ocho mil`,
`quinientos mil`, `un millón`), detecta si es ingreso o egreso por palabras
clave (`recibí`, `me pagaron`, `gasté`, `pagué`...) y sugiere categoría según
palabras relacionadas (`transporte`, `beca`, `almuerzo`, etc.). El usuario
**siempre** revisa y confirma en el formulario antes de guardar; nunca se
guarda automáticamente.

---

## 7. Cómo probar la aplicación (checklist)

| # | Caso | Resultado esperado |
|---|---|---|
| 1 | Registrar ingreso de $1.000.000 | Saldo = $1.000.000 |
| 2 | Registrar egreso de $300.000 | Saldo = $700.000 |
| 3 | Egresos hasta llegar al 30% | Aparece ⚠️ Precaución |
| 4 | Egresos hasta llegar al 10% | Aparece 🚨 Crítico + notificación |
| 5 | Egreso superior al saldo | Se bloquea con mensaje |
| 6 | Monto = 0 | Error de validación |
| 7 | Monto negativo | Error de validación |
| 8 | Eliminar un egreso | Pide confirmación, actualiza saldo |
| 9 | Editar un egreso | Recalcula saldo y valida límite |
| 10 | Cerrar y reabrir la app | Los datos persisten (SQLite) |
| 11 | Cambiar tema claro/oscuro | Cambia y persiste |
| 12 | Cambiar paleta | Cambia y persiste |
| 13 | Cambiar alias | Aparece en el dashboard tras reiniciar |
| 14 | Comando de voz | Prellena el formulario, exige confirmación |

Puedes usar el botón **"Cargar datos de demostración"** en Ajustes para
poblar rápidamente la app con los datos de prueba sugeridos en el
enunciado (Beca $800.000, Mesada $400.000, Trabajo $300.000, y varios
egresos), sin que esto impida borrar todo después con **"Eliminar todos
los movimientos"**.

---

## 8. Solución de problemas comunes

* **Error de compilación con `CardThemeData`**: si tu versión de Flutter es
  anterior a la que renombró `CardTheme` → `CardThemeData`, reemplaza
  `CardThemeData` por `CardTheme` en `lib/theme/app_theme.dart` (el resto del
  archivo no necesita cambios).
* **`MissingPluginException` en `speech_to_text` o `flutter_local_notifications`**:
  ejecuta `flutter clean && flutter pub get` y vuelve a compilar; estos
  plugins requieren un *hot restart* completo (no *hot reload*) tras
  instalarse.
- **El reconocimiento de voz no detecta nada en el emulador**: los
  emuladores de Android no siempre tienen un motor de reconocimiento de voz
  instalado; prueba en un dispositivo físico, o usa "Ingresar manualmente"
  cuando aparezca el error.

---

## 9. Prioridades respetadas

Se implementaron completas las funcionalidades de **Prioridad 1
(obligatorias)**: dashboard, registro de ingresos/egresos, persistencia,
cálculo de saldo, restricción de egresos, alertas 30%/10%, notificación
local, editar/eliminar egresos, validaciones y navegación. También se
implementaron completas las de **Prioridad 2 (plus)**: voz, tema, paletas,
alias, nombre/emoji del mes, y persistencia de preferencias. De
**Prioridad 3** se incluyeron animaciones básicas y filtros del historial.
