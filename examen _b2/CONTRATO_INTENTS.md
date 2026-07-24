# Contrato de Intents — Flujo "Mascota Perdida"

Documento de referencia para el equipo. Define cómo se comunican las 4 apps
mediante **Intents implícitos de Android**, sin importar la tecnología de
cada una (Flutter o Kotlin Multiplatform). Cualquier cambio a este contrato
debe acordarse entre todo el equipo, porque rompe la cadena si una sola app
se desincroniza.

## Por qué Intents implícitos (no explícitos)

Se usa **acción implícita + categoría**, en vez de apuntar a un
`packageName`/`Activity` concretos. Así ninguna app necesita conocer el
`applicationId` de las demás (que además puede cambiar), y una app de KMP
puede declarar el mismo `<intent-filter>` que una app Flutter sin depender
del framework del emisor. Es el mecanismo estándar de Android para
interoperabilidad entre apps de distintos equipos/stacks.

## Reglas generales

- Todos los extras van como tipos **primitivos** (`String`, `double`/`Double`,
  `long`/`Long`) — nunca objetos serializados custom, para garantizar que
  cualquier tecnología (Flutter, Kotlin/Java) pueda leerlos con la API nativa
  de `Intent.getStringExtra()`, `getDoubleExtra()`, etc.
- Las fechas viajan como `String` en formato **ISO-8601** (`DateTime.now().toIso8601String()` en Dart / `Instant.toString()` en Kotlin).
- **No se transfieren fotos/binarios por el Intent** (el límite de Binder
  transaction es ~1MB y es frágil entre procesos). Cada app maneja sus
  propias fotos localmente; el contrato solo transporta datos de texto y
  coordenadas. Si a futuro se necesita, se resolvería con una URL remota, no
  con bytes en el extra.
- `pet_id` es el identificador que **amarra todo el flujo**: lo genera la
  App 1 y viaja intacto hasta la App 4. Sin este campo no hay forma de saber
  a qué caso corresponde cada paso.
- Cada app debe manejar el caso en que el Intent llegue **sin extras** (por
  ejemplo, si el usuario abre la app directamente sin pasar por el flujo) —
  no debe crashear, simplemente arranca en su modo normal/standalone.
- La `Activity` receptora debe leer el intent tanto en `onCreate` (cold
  start) como en `onNewIntent` (si la app ya estaba abierta) — con
  `launchMode="singleTop"` en el manifest, Android reutiliza la instancia
  existente y solo dispara `onNewIntent`.

## Paso 1 → 2 : App 1 (Reportar mascota perdida) → App 2 (Avistamientos)

- **Action:** `com.examenb2.petflow.action.LOST_PET_REPORTED`
- **Category:** `android.intent.category.DEFAULT`

| Extra | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `pet_id` | String | Sí | UUID del caso, generado por App 1 |
| `pet_name` | String | Sí | Nombre de la mascota (o "Desconocido") |
| `pet_type` | String | Sí | `"perro"` \| `"gato"` \| `"otro"` |
| `description` | String | Sí | Color, tamaño, señas particulares |
| `last_seen_lat` | Double | Sí | Latitud del último lugar visto |
| `last_seen_lng` | Double | Sí | Longitud del último lugar visto |
| `contact_phone` | String | Sí | Teléfono del dueño |
| `reported_at` | String (ISO-8601) | Sí | Momento del reporte de pérdida |

**Efecto en App 2:** abre el mapa centrado en `(last_seen_lat, last_seen_lng)`,
muestra un banner "Buscando a: {pet_name}" y cualquier avistamiento que la
comunidad reporte mientras ese caso está activo queda enlazado a `pet_id`.

## Paso 2 → 3 : App 2 (Avistamientos) → App 3 (Refugios, KMP)

- **Action:** `com.examenb2.petflow.action.SIGHTING_FOLLOWUP`
- **Category:** `android.intent.category.DEFAULT`

| Extra | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `pet_id` | String | Sí | Mismo id propagado desde el Paso 1 |
| `pet_name` | String | Sí | Nombre de la mascota |
| `pet_type` | String | Sí | `"perro"` \| `"gato"` \| `"otro"` |
| `sighting_lat` | Double | Sí | Latitud del avistamiento más reciente/relevante |
| `sighting_lng` | Double | Sí | Longitud del avistamiento más reciente/relevante |
| `sighting_description` | String | Sí | Descripción del avistamiento elegido |
| `sighting_at` | String (ISO-8601) | Sí | Momento del avistamiento |
| `contact_phone` | String | Sí | Teléfono de contacto (propagado desde el caso) |

**Disparador en App 2:** el usuario, desde el detalle de un avistamiento
vinculado a un caso activo, pulsa **"Buscar refugios cercanos"**. App 2 envía
el Intent con la ubicación de ese avistamiento para que App 3 liste refugios
cercanos a ese punto.

**Efecto esperado en App 3:** listar/buscar refugios cerca de
`(sighting_lat, sighting_lng)` y permitir continuar el flujo hacia App 4.

## Paso 3 → 4 : App 3 (Refugios, KMP) → App 4 (Reencuentro)

*(Implementado por el equipo de App 3/App 4 — se documenta aquí para que la
historia completa sea coherente de punta a punta.)*

- **Action:** `com.examenb2.petflow.action.SHELTER_MATCH`
- **Category:** `android.intent.category.DEFAULT`

| Extra | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `pet_id` | String | Sí | Mismo id propagado desde el Paso 1 |
| `pet_name` | String | Sí | Nombre de la mascota |
| `shelter_name` | String | Sí | Nombre del refugio seleccionado |
| `shelter_address` | String | Sí | Dirección del refugio |
| `shelter_lat` | Double | Sí | Latitud del refugio |
| `shelter_lng` | Double | Sí | Longitud del refugio |
| `shelter_phone` | String | No | Teléfono del refugio, si aplica |
| `contact_phone` | String | Sí | Teléfono del dueño original (propagado) |

## Archivos necesarios por app

Nota clave: el nombre del `MethodChannel`/`EventChannel` que usa Flutter para
pasar datos de su capa nativa (Kotlin) a Dart **es un detalle interno de cada
app** — no necesita coincidir entre apps. Lo único que debe coincidir
carácter por carácter entre apps es lo que va en el `<intent-filter>` y en
los extras: el `action` y las claves de la tabla de cada paso.

### App 1 — Reportar mascota perdida (Flutter) — solo **envía**

No recibe nada de nadie (es el punto de partida del flujo), así que no
necesita tocar `MainActivity`.

| Archivo | Para qué |
|---|---|
| `pubspec.yaml` | agregar dependencia `android_intent_plus` |
| `lib/services/intent_contract.dart` | constantes `actionLostPetReported` + las 8 claves de extras del Paso 1→2 (copiar del mismo archivo en App 2) |
| `lib/services/intent_service.dart` | método `sendLostPetReport({...})` — mismo patrón que `sendSightingFollowup()` en App 2: construir `AndroidIntent(action, category, arguments)`, `canResolveActivity()`, `launch()` |
| `android/app/src/main/AndroidManifest.xml` | bloque `<queries>` declarando `action com.examenb2.petflow.action.LOST_PET_REPORTED` (para poder resolver/lanzar el intent en Android 11+) |
| pantalla que finaliza el reporte | al guardar el reporte localmente, llamar a `sendLostPetReport(...)` con los datos recién guardados |

### App 2 — Avistamientos (Flutter) — ya implementada, referencia

Archivos reales en `pet_sightings_app/` que sirven de plantilla para las
otras 3 apps:

| Archivo | Rol |
|---|---|
| `android/app/src/main/kotlin/.../MainActivity.kt` | puente nativo: lee extras en `onCreate`/`onNewIntent`, los expone por `MethodChannel`+`EventChannel` |
| `android/app/src/main/AndroidManifest.xml` | `<intent-filter>` para recibir `LOST_PET_REPORTED` + `<queries>` para poder lanzar `SIGHTING_FOLLOWUP` |
| `lib/services/intent_contract.dart` | constantes del contrato (ambos pasos, el que recibe y el que envía) |
| `lib/models/lost_pet_case.dart` | parseo de los extras recibidos (Paso 1→2) |
| `lib/services/intent_service.dart` | `getInitialCase()` / `onNewCase()` (recibir) + `sendSightingFollowup()` (enviar) |
| `lib/providers/sighting_provider.dart` | guarda el caso activo (`activeCase`) para que la UI reaccione |

### App 3 — Refugios (KMP) — **recibe** de App 2 y **envía** a App 4

Los Intents solo existen en Android, así que todo esto va en el
source-set `androidMain` del proyecto KMP. Al ser Kotlin puro (sin Flutter
de por medio) es más directo que en App 2/4: la propia `Activity` puede leer
`intent.extras` y pasarlo a la UI de Compose sin ningún canal/bridge.

| Archivo | Para qué |
|---|---|
| `androidMain/.../MainActivity.kt` | leer `intent.extras` en `onCreate` y sobrescribir `onNewIntent` (mismo motivo que en App 2: si la Activity usa `launchMode="singleTop"`); exponer el resultado a un `ViewModel`/`StateFlow` compartido |
| `androidMain/.../AndroidManifest.xml` | `<intent-filter>` para recibir `SIGHTING_FOLLOWUP` (action + category DEFAULT) + `<queries>` declarando `SHELTER_MATCH` |
| `commonMain/.../IntentContract.kt` (o `androidMain` si no se comparte con otros targets) | `object IntentContract` con las mismas constantes de acción/extras que `intent_contract.dart`, **con los mismos valores de texto exactos** |
| `androidMain/.../SightingFollowupCase.kt` | data class + función que arma el caso a partir del `Bundle` de extras (equivalente a `LostPetCase.fromIntentExtras`) |
| donde se elija el refugio | construir `Intent(IntentContract.ACTION_SHELTER_MATCH).apply { putExtra(...); addCategory(...) }` y `startActivity(intent)` — no necesita ninguna librería extra, es Android puro |

### App 4 — Reencuentro (Flutter) — solo **recibe**

Es el último eslabón: recibe de App 3 y no reenvía a nadie. Mismo patrón de
recepción que App 2, sin la parte de envío.

| Archivo | Para qué |
|---|---|
| `android/app/src/main/kotlin/.../MainActivity.kt` | copiar tal cual el de App 2 (es genérico, no depende de los extras concretos) |
| `android/app/src/main/AndroidManifest.xml` | `<intent-filter>` para recibir `SHELTER_MATCH` |
| `lib/services/intent_contract.dart` | constantes del Paso 3→4 |
| `lib/models/shelter_match_case.dart` | parseo de extras (mismo patrón que `LostPetCase.fromIntentExtras`) |
| `lib/services/intent_service.dart` | solo `getInitialCase()` / `onNewCase()` (no necesita `android_intent_plus` porque no envía nada) |

## Cómo probar cada salto de forma aislada (sin tener las 4 apps instaladas)

Con el dispositivo/emulador conectado y `adb` en el PATH, se puede simular
cualquier paso del flujo sin depender de que la app anterior esté instalada:

```bash
adb shell am start -a com.examenb2.petflow.action.LOST_PET_REPORTED \
  -c android.intent.category.DEFAULT \
  --es pet_id "demo-123" \
  --es pet_name "Firulais" \
  --es pet_type "perro" \
  --es description "Labrador color café, collar rojo" \
  --ed last_seen_lat -0.1807 \
  --ed last_seen_lng -78.4678 \
  --es contact_phone "0999999999" \
  --es reported_at "2026-07-23T10:00:00.000"
```

(`--es` = extra string, `--ed` = extra double). Cambiando el `-a` y los
`--es`/`--ed` se prueba igual el salto 2→3.

## Cómo ejecutar el flujo completo con las 4 apps ya terminadas

### Requisito no negociable: un solo dispositivo/emulador

Los Intents se resuelven dentro de **una misma instancia de Android**. Las 4
apps tienen que estar instaladas en el mismo emulador o el mismo teléfono
físico — no hay forma de que un Intent cruce de un emulador a otro. Verifica
cuál está activo antes de instalar nada:

```bash
adb devices
```

Si aparece más de un dispositivo/emulador, fija el destino con `-s <id>` en
todos los comandos siguientes (`adb -s emulator-5554 install ...`).

### 1. Compilar cada app a un APK

**Apps Flutter (1, 2 y 4)** — dentro de la carpeta de cada proyecto:

```bash
flutter build apk --debug
# genera build/app/outputs/flutter-apk/app-debug.apk
```

**App 3 (KMP)** — el nombre exacto de la tarea depende de cómo se llame su
módulo Android (`composeApp`, `androidApp`, etc.), pero el patrón es:

```bash
./gradlew :composeApp:assembleDebug
# genera .../build/outputs/apk/debug/composeApp-debug.apk
```

### 2. Instalar las 4 en el mismo dispositivo

```bash
adb install -r ruta/a/app1-debug.apk
adb install -r ruta/a/app2-debug.apk   # pet_sightings_app: build/app/outputs/flutter-apk/app-debug.apk
adb install -r ruta/a/app3-debug.apk
adb install -r ruta/a/app4-debug.apk
```

`-r` reinstala si ya existía una versión previa (evita el error "app already
exists with a different signature" al iterar).

### 3. Verificar que cada `<intent-filter>` quedó bien declarado

Antes de probar el flujo completo, confirma con `am start` que cada acción
resuelve a **exactamente una** app (si no resuelve a ninguna, el
intent-filter tiene un typo o `exported` no está en `true`; si resuelve a
más de una, aparecerá un selector de apps en pantalla):

```bash
adb shell am start -a com.examenb2.petflow.action.LOST_PET_REPORTED -c android.intent.category.DEFAULT
adb shell am start -a com.examenb2.petflow.action.SIGHTING_FOLLOWUP -c android.intent.category.DEFAULT
adb shell am start -a com.examenb2.petflow.action.SHELTER_MATCH -c android.intent.category.DEFAULT
```

Cada uno debe abrir la app correspondiente (sin extras esta vez, así que
cada app debe arrancar en su modo normal/standalone — por eso la regla de
"manejar el caso sin extras" en la sección de arriba).

### 4. Correr el flujo real de punta a punta

1. Abrir **App 1** desde el launcher del dispositivo (ícono normal, no `adb`).
2. Completar el formulario "mascota perdida" y confirmar el envío — debería
   abrirse **App 2** automáticamente, con el banner "Buscando a: {nombre}".
3. En **App 2**, tocar el mapa para reportar un avistamiento de esa mascota,
   abrir su detalle y pulsar "Buscar refugios cercanos" — debería abrirse
   **App 3**.
4. En **App 3**, elegir un refugio — debería abrirse **App 4** con los datos
   acumulados de todo el recorrido.

### 5. Depurar si algo no llega

```bash
adb logcat | grep -i -E "AndroidRuntime|ActivityNotFound|ClassCastException"
```

Errores típicos y su causa:

| Síntoma | Causa probable |
|---|---|
| `ActivityNotFoundException` al enviar el Intent | La app receptora no está instalada, o el `<intent-filter>` tiene el `action`/`category` mal escrito (revisar carácter por carácter contra este documento) |
| No pasa nada al pulsar el botón de envío, sin crash | `canResolveActivity()` devolvió `false` — mismo diagnóstico que arriba, revisado en código en vez de crashear |
| `ClassCastException` al leer un extra | Un lado puso el extra con un tipo y el otro lo lee como otro (ej. `putExtra("last_seen_lat", "0.18")` como String en vez de Double) — revisar la columna "Tipo" de cada tabla |
| Se abre un selector ("¿Con qué app quieres abrir esto?") en vez de ir directo | Dos apps instaladas declaran el mismo `action` — normalmente indica que alguien copió el intent-filter equivocado a la app que no era |
| El Intent llega pero con los extras vacíos | La `Activity` solo leyó `getIntent()` en `onCreate` y la app ya estaba abierta (por eso hace falta también `onNewIntent`, ver "Reglas generales") |
