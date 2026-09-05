# 💰 Finanzas Student

Aplicación móvil de finanzas personales desarrollada en **Flutter** como **Evaluación 1** de la asignatura **Desarrollo Móvil Multiplataforma** del programa de **Ingeniería de Software de la Universidad de Santander**.

La aplicación está orientada a estudiantes y permite gestionar de manera sencilla sus **ingresos, gastos y presupuesto mensual**, incorporando alertas de presupuesto, persistencia local, personalización de la interfaz y registro de movimientos mediante comandos de voz.

---

## 📱 Características principales

### 💵 Gestión de ingresos

* Registro de ingresos.
* Descripción del ingreso.
* Selección de categoría.
* Registro del monto.
* Selección de fecha.
* Validación de campos obligatorios.
* Validación de montos mayores a cero.
* Visualización de ingresos registrados.
* Actualización del saldo disponible en tiempo real.

### 💸 Gestión de gastos

* Registro de gastos.
* Categorías:

  * 🍔 Alimentación
  * 🚌 Transporte
  * 🎮 Entretenimiento
  * 🏥 Salud
  * 📚 Educación
  * 📦 Otro
* Registro de monto y fecha.
* Edición de gastos.
* Eliminación de gastos con confirmación.
* Validación de datos antes de guardar.
* Actualización inmediata del saldo.

### 🛡️ Control del presupuesto

La aplicación incorpora reglas para evitar que el estudiante gaste más dinero del disponible.

**Reglas implementadas:**

* El total de gastos del mes no puede superar el total de ingresos del mismo mes.
* No se permite registrar un gasto que genere un saldo negativo.
* Cuando el saldo disponible alcanza el **30 %** de los ingresos mensuales se muestra una alerta de **"Precaución"**.
* Cuando el saldo disponible alcanza el **10 %** se muestra una alerta de **"Crítico"**.
* El nivel crítico genera además una **notificación local**.

### 🎙️ Registro mediante voz

La aplicación permite registrar movimientos utilizando comandos de voz.

El usuario puede utilizar el botón 🎙️ para hablar y la aplicación interpreta información como:

> "Gasté ocho mil pesos en transporte."

La aplicación identifica:

* Tipo de movimiento.
* Descripción.
* Categoría.
* Monto.

El resultado se presenta en el formulario para que el usuario pueda **revisarlo y modificarlo antes de guardarlo**.

También se incluyen mecanismos para:

* Solicitar permisos de micrófono.
* Mostrar el estado de escucha.
* Mostrar animación durante el reconocimiento.
* Manejar errores de reconocimiento.
* Volver a intentar el reconocimiento.
* Continuar con el registro manual.

### 🎨 Personalización

La aplicación permite personalizar la experiencia del estudiante mediante:

* ☀️ Tema claro.
* 🌙 Tema oscuro.
* 🔵 Paleta azul.
* 🟢 Paleta verde.
* 🟣 Paleta morada.
* 👤 Alias del estudiante.
* 🗓️ Nombre personalizado del mes activo.
* 😀 Emoji personalizado para el mes.

Las preferencias se almacenan localmente para conservar la configuración entre sesiones.

---

## 🏗️ Arquitectura

El proyecto utiliza una arquitectura organizada por responsabilidades para facilitar el mantenimiento y evolución de la aplicación.

```text
lib/
│
├── models/
│   ├── categorias.dart
│   └── movimiento.dart
│
├── providers/
│   ├── finance_provider.dart
│   └── settings_provider.dart
│
├── screens/
│   ├── add_expense_screen.dart
│   ├── add_income_screen.dart
│   ├── dashboard_screen.dart
│   ├── main_navigation.dart
│   ├── settings_screen.dart
│   └── voice_capture_screen.dart
│
├── services/
│   ├── base_datos_service.dart
│   ├── notificacion_service.dart
│   ├── preferencias_service.dart
│   └── voz_service.dart
│
├── theme/
│   └── app_theme.dart
│
├── widgets/
│   └── ...
│
└── main.dart
```

### Capas principales

**Models**

Contienen las estructuras de datos utilizadas por la aplicación.

**Providers**

Gestionan el estado de la aplicación y permiten actualizar la interfaz cuando cambian los datos.

**Screens**

Contienen las diferentes interfaces y funcionalidades de la aplicación.

**Services**

Gestionan funcionalidades como:

* Base de datos local.
* Preferencias del usuario.
* Notificaciones.
* Reconocimiento de voz.

**Theme**

Contiene la configuración visual de los temas y paletas de colores.

---

## 🛠️ Tecnologías utilizadas

| Tecnología             | Uso                               |
| ---------------------- | --------------------------------- |
| 🐦 Flutter             | Desarrollo de la aplicación móvil |
| 🎯 Dart                | Lenguaje de programación          |
| 🗄️ SQLite             | Persistencia local de movimientos |
| ⚙️ SharedPreferences   | Persistencia de preferencias      |
| 🔄 Provider            | Gestión del estado                |
| 🔔 Local Notifications | Alertas de presupuesto            |
| 🎙️ Speech to Text     | Reconocimiento de comandos de voz |
| 🎨 Material Design     | Interfaz gráfica                  |

---

## 💾 Persistencia de datos

La aplicación utiliza almacenamiento local para conservar la información del usuario.

Se utilizan diferentes mecanismos dependiendo del tipo de información:

### SQLite

Utilizado para almacenar información relacionada con los movimientos financieros, como:

* Ingresos.
* Gastos.
* Fechas.
* Categorías.
* Montos.
* Descripciones.

### SharedPreferences

Utilizado para conservar preferencias de configuración como:

* Alias.
* Tema.
* Paleta de colores.
* Nombre del mes.
* Emoji del mes.

La información permanece disponible entre sesiones mientras se mantenga la instalación de la aplicación.

---

## 📊 Flujo general de la aplicación

```text
                    ┌─────────────────┐
                    │     Usuario     │
                    └────────┬────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │     Dashboard       │
                  └─────────┬───────────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
        ┌──────────┐  ┌──────────┐  ┌────────────┐
        │ Ingresos │  │  Gastos  │  │Configuración│
        └─────┬────┘  └─────┬────┘  └────────────┘
              │             │
              └──────┬──────┘
                     ▼
              ┌──────────────┐
              │    Balance   │
              └──────┬───────┘
                     │
              ┌──────┴───────┐
              ▼              ▼
        ┌───────────┐  ┌────────────┐
        │ Precaución│  │   Crítico  │
        │    30 %   │  │    10 %    │
        └───────────┘  └─────┬──────┘
                              │
                              ▼
                    🔔 Notificación local
```

---

## 🎙️ Flujo de registro por voz

```text
Usuario presiona 🎙️
        │
        ▼
Solicitud de permiso
        │
        ▼
Reconocimiento de voz
        │
        ▼
Texto reconocido
        │
        ▼
Interpretación del comando
        │
        ├── Tipo de movimiento
        ├── Descripción
        ├── Categoría
        └── Monto
        │
        ▼
Formulario prellenado
        │
        ▼
Usuario revisa / modifica
        │
        ▼
Guardar movimiento
```

---

## 🚀 Instalación y ejecución

### Requisitos

Antes de ejecutar el proyecto es necesario tener instalado:

* Flutter SDK.
* Dart SDK.
* Android Studio.
* Android SDK.
* Un dispositivo Android físico o un emulador.

Se recomienda utilizar una versión reciente y estable de Flutter.

### Clonar el repositorio

```bash
git clone https://github.com/USUARIO/finanzas-student.git
```

Ingresar al proyecto:

```bash
cd finanzas-student
```

### Instalar dependencias

```bash
flutter pub get
```

### Ejecutar la aplicación

Con un dispositivo o emulador conectado:

```bash
flutter run
```

---

## 📦 Generar APK

Para generar una versión de producción:

```bash
flutter build apk --release
```

El APK generado se encontrará en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔐 Permisos

La aplicación requiere permisos específicos para determinadas funcionalidades.

### 🎙️ Micrófono

Se utiliza para el registro de movimientos mediante comandos de voz.

El permiso se solicita al momento de utilizar la funcionalidad de reconocimiento de voz.

### 🔔 Notificaciones

Se utilizan para informar al usuario cuando su saldo alcanza el nivel crítico de presupuesto.

---

## 📋 Reglas de negocio

| Regla             | Comportamiento                               |
| ----------------- | -------------------------------------------- |
| Gastos ≤ Ingresos | No se permite superar los ingresos mensuales |
| Saldo negativo    | El sistema bloquea el registro del gasto     |
| Saldo ≤ 30 %      | Se muestra alerta de precaución              |
| Saldo ≤ 10 %      | Se muestra alerta crítica                    |
| Nivel crítico     | Se genera una notificación local             |
| Monto inválido    | El movimiento no puede guardarse             |
| Campos vacíos     | Se muestran errores de validación            |

---

## 🎯 Objetivo del proyecto

Desarrollar una aplicación móvil que permita a estudiantes gestionar de manera sencilla sus finanzas personales, proporcionando herramientas para el registro y seguimiento de ingresos y gastos, control del presupuesto mensual y alertas preventivas ante una disminución significativa del saldo disponible.

---

## 📚 Contexto académico

Este proyecto fue desarrollado como parte del examen práctico de la asignatura:

**Desarrollo Móvil Multiplataforma**

**Programa:** Ingeniería de Software
**Universidad:** Universidad de Santander
**Modalidad:** Aplicación móvil multiplataforma

---

## 👨‍💻 Autores

**Ferney Santander**
**Yeritza Palacio**

Proyecto académico desarrollado con Flutter y Dart.

---

## 📄 Licencia

Este proyecto fue desarrollado con fines académicos y educativos.

---

<p align="center">
  💰 <strong>Finanzas Student</strong><br>
  Gestión financiera sencilla para estudiantes.
</p>
