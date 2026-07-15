# Taller 07 - Ciclo de Vida y Persistencia en NativeScript

Todo lo documentado aqui fue verificado ejecutando el APK real en un emulador Android (logs capturados con `adb logcat`), no es una simulacion.

## 1) Configuracion y codigo fuente

Estructura principal:

- `app/app-root.xml` - UI (contador + boton +1 + boton Reset), registra el evento `loaded`.
- `app/app-root.ts` - code-behind de `app-root.xml`: bindingContext, `onIncrementTap`, `onResetTap`, persistencia con `ApplicationSettings`.
- `app/app.ts` - entry point de la aplicacion: solo logs de ciclo de vida + `Application.run(...)`.
- `app/main-view-model.ts` - `Observable` con la propiedad `count`.
- `app/app.css` - estilos de la pantalla.
- `App_Resources/Android/src/main/AndroidManifest.xml` - `configChanges` de la Activity.
- `App_Resources/Android/src/main/res/values/styles.xml` - temas (deben heredar de AppCompat).

### Por que existen `app.ts` Y `app-root.ts` por separado

En NativeScript (sin Angular/Vue), los manejadores de eventos declarados en un XML (`loaded="..."`, `tap="..."`) se resuelven en el **code-behind con el mismo nombre del XML** (`app-root.xml` -> `app-root.ts`), no en el entry point de la app. Poner la logica de la pagina directamente en `app.ts` hace que esos handlers nunca se ejecuten (bug real que se encontro y corrigio en este taller: el contador no se mostraba en pantalla ni el boton funcionaba porque `onNavigatingTo`/`onIncrementTap` estaban en el archivo equivocado).

### UI minima (contador + boton)

`app/app-root.xml`:
- `Label` con el titulo "Contador".
- `Label` enlazado a `{{ count }}`.
- `Button` con `tap="onIncrementTap"`.

### Logica del contador y persistencia

En `app/app-root.ts`:
- Se crea un `MainViewModel` (Observable) con propiedad `count`.
- En `onPageLoaded` (evento `loaded` de la Page, se dispara siempre, con o sin Frame), se lee el valor guardado con `ApplicationSettings.getNumber(...)` y se asigna `page.bindingContext`.
- En `onIncrementTap`, se incrementa `count` y se guarda inmediatamente con `ApplicationSettings.setNumber(...)`.

### Logs de ciclo de vida (Android equivalente)

En `app/app.ts`, usando eventos Android de NativeScript:

| Evento NativeScript | Equivalente Android |
|---|---|
| `activityCreatedEvent` | `onCreate` |
| `activityStartedEvent` | `onStart` |
| `activityResumedEvent` | `onResume` |
| `activityPausedEvent` | `onPause` |
| `activityStoppedEvent` | `onStop` |
| `activityDestroyedEvent` | `onDestroy` |
| (derivado) | `onRestart` |

`onRestart` no existe como callback directo en la API de NativeScript: se detecta marcando una bandera `appWasStopped` en `onStop` y comprobando esa bandera dentro de `activityStartedEvent`.

## 2) Secuencia de logs verificada (capturada con adb logcat, no simulada)

### Caso A - Apertura + incrementar contador a 5

    [Lifecycle] onCreate
    [Lifecycle] onStart
    [Lifecycle] onResume
    [Lifecycle] Application resume
    [Lifecycle] Counter incremented to 1
    [Lifecycle] Counter incremented to 2
    [Lifecycle] Counter incremented to 3
    [Lifecycle] Counter incremented to 4
    [Lifecycle] Counter incremented to 5

### Caso B - Rotar pantalla (Portrait -> Landscape) con contador en 5

**No se imprime ningun log.** El contador se mantiene en 5 y la pantalla se redibuja en landscape, pero la Activity nunca pasa por `onPause/onStop/onDestroy/onCreate`. Esto se confirmo revisando que el PID del proceso no cambia y que `logcat` queda vacio durante la rotacion.

### Caso C - Presionar Home (multitarea) y volver a abrir la app

Al presionar Home:

    [Lifecycle] Application suspend
    [Lifecycle] onPause
    [Lifecycle] onStop

Al volver a abrir la app (mismo proceso, no fue eliminado por el sistema):

    [Lifecycle] onRestart
    [Lifecycle] onStart
    [Lifecycle] onResume
    [Lifecycle] Application resume

El contador se mantiene en 5 (nunca se destruyo el proceso, sigue en memoria).

### Caso D - El sistema Android mata el proceso en background (`adb shell am kill`) y luego se reabre

    [Lifecycle] onCreate
    [Lifecycle] onStart
    [Lifecycle] onResume
    [Lifecycle] Application resume

Aqui si hay un `onCreate` real (proceso nuevo, PID distinto). El contador **se recupera en 5** porque `ApplicationSettings` lo guarda en disco, no en memoria.

### Caso E - Cerrar la app explicitamente (boton Back)

    [Lifecycle] Application suspend
    [Lifecycle] onPause
    [Lifecycle] onStop
    [Lifecycle] onDestroy

`onDestroy` solo aparece cuando la Activity se cierra de verdad (Back / swipe en recientes / `finish()`), nunca durante una rotacion.

### Boton "Reset"

Se agrego un boton adicional para reiniciar el contador a 0 manualmente (util para repetir la demo sin reinstalar el APK). Se opto por un boton explicito en vez de resetear automaticamente al cerrar la app porque:

- Ligar el reset a `onDestroy` seria inconsistente: como se ve en el Caso D, cuando el sistema mata el proceso por memoria, `onDestroy` **no se ejecuta** (el kill es abrupto), asi que el reset no se aplicaria siempre igual.
- Contradiria el objetivo del taller: la app esta pensada para demostrar que el contador persiste; resetearlo solo al cerrar mezclaria ese mensaje.

## 3) Explicacion tecnica para el informe

### Por que el contador NO se reinicia al rotar (a diferencia de Android Nativo por defecto)

En Android Nativo, sin configuracion adicional, rotar la pantalla **destruye y recrea** la Activity (Configuration Change), por lo que hay que usar `onSaveInstanceState`/`onRestoreInstanceState` (o un `ViewModel` con `ViewModelStore`) para no perder el estado.

En NativeScript la historia es distinta ("pista: no siempre es igual a Android Nativo" del enunciado): **el propio template por defecto de NativeScript ya declara** en su `AndroidManifest.xml`:

    android:configChanges="keyboardHidden|orientation|screenSize"

en la Activity principal (`com.tns.NativeScriptActivity`). Esto le dice a Android: "yo (la app) me encargo de estos cambios, no me destruyas". Como resultado, ante una rotacion la Activity **nunca se destruye ni se recrea**: sigue viva la misma instancia de la maquina virtual de JavaScript, con el mismo `Observable`/`MainViewModel` en memoria. Por eso el contador simplemente no tiene por que reiniciarse - no hubo ningun ciclo de vida que lo reinicie.

En este taller se amplio la lista por defecto a:

    android:configChanges="keyboard|keyboardHidden|orientation|screenSize|screenLayout|smallestScreenSize|uiMode"

(cobertura extra para teclado fisico y cambio de modo claro/oscuro), pero el mecanismo base ya viene incluido en NativeScript sin que el desarrollador tenga que hacer nada.

### Por que ademas se uso `ApplicationSettings`

`configChanges` resuelve la rotacion, pero **no protege contra que Android mate el proceso completo** cuando la app esta en segundo plano por mucho tiempo o el sistema necesita memoria (Caso D de la tabla anterior). En ese escenario si se pierde todo el estado en memoria. Por eso se agrego una segunda capa de persistencia con `ApplicationSettings` (almacenamiento clave-valor en disco, equivalente a `SharedPreferences` de Android Nativo):

- Cada `onIncrementTap` guarda el valor: `ApplicationSettings.setNumber("counter_value", count)`.
- Cada `onPageLoaded` (se ejecuta una vez, cuando la Page/Activity se crea) restaura el valor: `ApplicationSettings.getNumber("counter_value", 0)`.

Con estas dos capas combinadas (`configChanges` + `ApplicationSettings`) el contador sobrevive tanto a la rotacion (sin siquiera notarlo) como a un reinicio completo del proceso por parte del sistema operativo.

## Como probar

1. Instalar dependencias:

       npm install

2. Generar el APK y correr en un emulador/dispositivo con logs en vivo:

       $env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
       $env:Path="$env:JAVA_HOME\bin;$env:Path"
       $env:NoDefaultCurrentDirectoryInExePath=''
       npx ns run android

3. Observar en la terminal las lineas `[Lifecycle]` mientras: subes el contador, rotas la pantalla, presionas Home y vuelves, y cierras con Back.
