# Proyecto B1 — Red y Almacenamiento Seguro

Aplicación Flutter desarrollada como proyecto del primer bimestre. Integra consumo de una API REST pública y tres tipos de almacenamiento local con distintos niveles de seguridad, todo controlado desde una interfaz reactiva que bloquea interacciones mientras hay operaciones en curso.

---

## Tecnología usada

| Capa | Herramienta |
|---|---|
| Framework | Flutter (Dart) |
| Peticiones HTTP | `http` |
| Almacenamiento simple | `shared_preferences` |
| Almacenamiento seguro (cifrado) | `flutter_secure_storage` |
| API pública de prueba | JSONPlaceholder (`jsonplaceholder.typicode.com`) |

---

## Qué hace la app

La app tiene **dos pestañas** en la barra de navegación inferior:

### Pestaña 1 — Módulo Red (API REST)

Permite consultar y modificar posts de una API pública. Se escribe un número de post (del 1 al 100), se consulta con GET y los datos aparecen en campos editables. Luego se pueden modificar y enviar de vuelta con PUT.

- Mientras espera la respuesta de internet aparece un spinner y todos los campos y botones se deshabilitan automáticamente para evitar toques dobles.
- Si la operación fue exitosa aparece un texto verde; si hubo error, aparece en rojo.
- El campo de ID solo acepta números — el teclado numérico abre directo.

### Pestaña 2 — Almacenamiento Seguro

Permite guardar y recuperar secretos (pares llave-valor) eligiendo entre tres tipos de almacenamiento:

| Tipo | Qué hace por detrás |
|---|---|
| **SharedPreferences** | Guarda el dato en texto plano en un archivo XML del teléfono. Sin cifrado. |
| **DataStore** | Usa cifrado AES-256 con el Android Keystore del sistema operativo. |
| **EncryptedSharedPreferences** | También usa cifrado AES-256 con Android Keystore. Mayor compatibilidad con la API nativa de Android. |

Al recuperar, si la llave no existe o está vacía, el mensaje de error es intencionalmente vago ("Acceso denegado") para no revelar si la llave existe o no — esto es una práctica de seguridad.

---

## Estructura del proyecto

```
proyecto_b1/
├── lib/
│   └── main.dart   # Toda la app: navegación, módulo de red y módulo de almacenamiento
└── test/
    └── widget_test.dart
```

Al ser un proyecto de tamaño acotado, toda la lógica vive en `main.dart`, dividida en clases bien separadas:

- `HomePage` — navegación con `BottomNavigationBar` e `IndexedStack`
- `NetworkModule` — lógica GET/PUT con control de estados de carga
- `StorageModule` — lógica de guardado y recuperación de secretos

---

## Cómo abrir y correr el proyecto

**Requisitos previos:** tener Flutter instalado y un emulador Android activo (o dispositivo físico conectado).

```bash
# 1. Ir a la carpeta del proyecto
cd proyecto_b1

# 2. Instalar dependencias
flutter pub get

# 3. Correr la app
flutter run
```

La app necesita conexión a internet para el módulo de red.

---

## Rúbrica cubierta

### 30% — Módulo 1 (REST API): GET y PUT con control de estados de carga

Se realizan peticiones HTTP reales a `jsonplaceholder.typicode.com`. Al tocar GET, la app hace una petición asíncrona (`async/await`) y mientras espera: muestra un spinner encima de la pantalla, deshabilita todos los campos de texto y botones (`enabled: false`, `onPressed: null`) y bloquea cualquier acción del usuario. Cuando llega la respuesta, los campos se llenan con los datos del post. El PUT toma lo que hay escrito en ese momento y lo envía al servidor. En ambos casos, el spinner desaparece siempre al terminar, haya habido éxito o error (usando `finally`).

### 30% — Módulo 3 (Seguridad): SharedPreferences, DataStore y EncryptedSharedPreferences

Los tres tipos de almacenamiento están integrados y seleccionables desde la misma pantalla con botones de radio. SharedPreferences usa la librería `shared_preferences` (texto plano). DataStore y EncryptedSharedPreferences usan `flutter_secure_storage`, que por detrás cifra los datos con AES-256 y guarda la clave de cifrado en el Android Keystore del sistema operativo — no en la app. Esto garantiza que aunque alguien acceda al archivo del teléfono, no pueda leer los datos sin la clave del sistema.

### 20% — Gestión de Estado: Reactividad sin caída de procesos

El estado de carga se maneja con una variable booleana `_loading` y `setState()`. Cada operación asíncrona enciende `_loading = true` al inicio y lo apaga en el bloque `finally` al terminar — sin importar si hubo éxito o error. Se usa la guarda `mounted` después de cada `await` para verificar que el widget todavía esté en pantalla antes de llamar a `setState()`, evitando errores si el usuario navegó a otra pestaña mientras esperaba. El `IndexedStack` conserva el estado de cada módulo al cambiar de pestaña — nada se reinicia.

### 20% — Sustentación de la Solución

Flutter corre sobre el motor de Android pero accede a sus capacidades nativas a través de plugins. `http` usa el stack de red de Android por debajo. `shared_preferences` escribe en el mismo lugar donde Android guarda preferencias de apps (archivo XML en almacenamiento privado). `flutter_secure_storage` usa directamente el Android Keystore System — el mismo mecanismo que usan las apps bancarias para proteger credenciales. El campo de ID usa `FilteringTextInputFormatter.digitsOnly` que delega en el sistema de entrada de texto de Android para forzar teclado numérico y rechazar cualquier carácter que no sea dígito. Todo esto demuestra que Flutter no es solo UI: se conecta con las capas de seguridad y red del sistema operativo.
