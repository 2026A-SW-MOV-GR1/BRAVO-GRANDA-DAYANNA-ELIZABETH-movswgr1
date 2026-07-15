# Taller 09 — Reverse Engineering de UI: Facebook (NativeScript)

**Escuela Politécnica Nacional — Ingeniería de UI**
Clon de alta fidelidad de la interfaz móvil de Facebook usando **NativeScript** (renderizado 100% nativo, sin WebViews), con foco en fidelidad visual, 60 FPS y análisis UX.

## Checklist de cumplimiento (guía oficial del taller)

| Requisito de la guía | Estado | Dónde |
|---|---|---|
| Prohibido WebView | ✅ | Todo el árbol usa componentes nativos (`ListView`, `Image`, `GridLayout`, `BottomNavigation`) |
| Al menos 3 listas | ✅ | Feed (1), Historias (2), Notificaciones (3) — ver auditoría abajo |
| Performance / 60 FPS | ✅ | `ListView` único con reciclaje nativo, `decodeWidth/Height`, `ObservableArray.setItem`, `loadMoreItems` (paginación) |
| Transiciones de entrada | ✅ | `animateEntrance()` en `common/animations.ts`, disparada 1 vez por item vía `itemLoading` |
| Efecto al presionar botones | ✅ | `pulseLike()` (rebote nativo en "Me gusta") + pseudo-clase CSS `:highlighted` en todos los botones |
| Estado de carga (skeleton/shimmer) | ✅ | `startShimmer()` + fila `templateType: "skeleton"` real en Feed y Notificaciones (900ms/700ms simulados) |
| Definición de mercado | ✅ | Fase A, punto 1 |
| Psicología del color (paleta + teoría) | ✅ | Fase A, punto 2 |
| Auditoría de 3 iterables | ✅ | Fase A, punto 3 |
| Modelos de datos | ✅ | `app/models/` |
| Estilización (fuentes, paddings, bordes) | ✅ | `*.css` de cada vista |
| Crítica UX + propuesta implementada | ✅ | Fase C |
| Código limpio / SOLID / arquitectura de carpetas | ✅ | Ver estructura + comentarios ISP/DIP/OCP en el código |
| **Reserva de app en el post oficial del curso** | ⚠️ **Pendiente — acción manual tuya**, no de código: comenta "Facebook" en el post de reserva del curso antes de entregar, para que no quede duplicada con otro compañero. |

## Estructura del proyecto

```
taller09/
├── README.md                          ← Este documento (Fase A y Fase C)
└── app/
    ├── app.ts                         ← Entry point
    ├── app.css                        ← Reset y tipografía global
    ├── common/
    │   ├── theme.ts                   ← Paleta de colores (Entregable 1.2)
    │   └── animations.ts              ← Micro-interacciones nativas (like bounce, shimmer)
    ├── models/                        ← Entregable 2.1 (mocks / estructuras de datos)
    │   ├── post.model.ts
    │   ├── story.model.ts
    │   └── notification.model.ts
    ├── services/                      ← Capa de datos (SOLID: ISP + DIP)
    │   ├── data-source.interface.ts
    │   └── mock-data.service.ts
    ├── view-models/                   ← Lógica de presentación (MVVM)
    │   ├── feed-view-model.ts
    │   └── notifications-view-model.ts
    └── views/
        ├── main/                      ← Shell de navegación (BottomNavigation)
        │   ├── main-page.xml
        │   └── main-page.css
        ├── feed/                      ← Lista 1 (Feed) + Lista 2 (Historias)
        │   ├── feed-page.xml
        │   ├── feed-page.css
        │   └── feed-page.ts
        └── notifications/             ← Lista 3 (Notificaciones)
            ├── notifications-page.xml
            ├── notifications-page.css
            └── notifications-page.ts
```

**Cómo ejecutar / probar:**

El proyecto NativeScript ejecutable ya está generado en `taller09/mobileapp/` (scaffold
`@nativescript/template-blank-ts` con la carpeta `app/` de este taller copiada dentro).

- **Ya hay un APK debug compilado y probado** en:
  `taller09/mobileapp/platforms/android/app/build/outputs/apk/debug/app-debug.apk`
- Para instalarlo en un emulador o celular con `adb` conectado:
  ```
  adb install -r taller09/mobileapp/platforms/android/app/build/outputs/apk/debug/app-debug.apk
  ```
- Para recompilar desde cero tras un cambio en `app/` (copiar los cambios a `mobileapp/app/` y luego):
  ```
  cd taller09/mobileapp
  ns build android
  ```

> **Nota de entorno (Windows + Node.js muy nuevo):** en esta máquina, `ns build android` falla
> la primera vez con `"gradlew.bat" no se reconoce...` porque el CLI de NativeScript no encuentra
> `gradlew.bat` en el PATH del proceso hijo que lanza (un problema conocido de compatibilidad con
> versiones recientes de Node.js en Windows, no un error del código del taller). Solución: agregar
> las carpetas de `gradlew.bat` al PATH antes de compilar:
> ```
> $env:PATH = "<ruta>\mobileapp\platforms\android;<ruta>\mobileapp\platforms\tempPlugin\core;" + $env:PATH
> ns build android
> ```

---

## ENTREGABLE 1 — FASE A: Selección y Análisis Estratégico

### 1. Definición de mercado para Facebook

| Dimensión | Descripción |
|---|---|
| **Edad predominante** | El núcleo duro de usuarios activos diarios se ha desplazado a **25–54 años** (Meta Q3 2025 / eMarketer). La Gen Z (18–24) mantiene cuenta pero migró su atención primaria a Instagram/TikTok; Facebook retiene fuertemente a **millennials y Gen X**, y crece en el segmento **45+** que lo usa como red social "de referencia familiar". |
| **Intereses transversales** | Marketplace (compra/venta local), Grupos de interés (barrio, oficio, afición), eventos locales, noticias curadas, contenido de video corto (Reels) y comunicación con negocios locales vía Messenger/Páginas. |
| **Nivel socioeconómico** | A nivel global es la red más **socioeconómicamente horizontal**: fuerte penetración en mercados emergentes (Latinoamérica, Sudeste Asiático, África) donde a menudo es sinónimo de "internet" (planes de datos zero-rating), y en mercados desarrollados se percibe como red "madura"/legado frente a apps más jóvenes. En **Ecuador/LatAm** sigue siendo la app social con mayor alcance total, especialmente para Marketplace y grupos comunitarios/barriales. |

### 2. Psicología del color en Facebook

**Paleta principal (hex reales):**

| Elemento | Hex | Uso |
|---|---|---|
| Azul corporativo (marca) | `#1877F2` | ActionBar, botones primarios, links, ícono "Me gusta" activo |
| Azul marca (variante presionado) | `#2374E1` | Estado *pressed* de botones azules |
| Fondo general (modo claro) | `#F0F2F5` | Fondo del feed/listas |
| Fondo tarjeta (modo claro) | `#FFFFFF` | Post cards, celdas de notificación |
| Fondo general (modo oscuro) | `#18191A` | Fondo del feed en dark mode |
| Fondo tarjeta (modo oscuro) | `#242526` | Post cards en dark mode |
| Texto primario (claro/oscuro) | `#050505` / `#E4E6EB` | Nombres de autor, cuerpo de texto |
| Texto secundario (claro/oscuro) | `#65676B` / `#B0B3B8` | Timestamps, contadores, metadatos |
| Divisor | `#CED0D4` / `#3E4042` | Líneas separadoras entre secciones |
| Alerta / notificación | `#F02849` | Badge rojo de contador de notificaciones |
| Reacción "Me encanta" | `#F33E58` | Corazón |
| Reacción "Me divierte" / "Me asombra" | `#F7B125` | Amarillo (emoji) |
| Estado en línea | `#31A24C` | Punto verde de disponibilidad |

**Fundamento técnico (psicología del color):**

- **Confianza y permanencia — Azul `#1877F2`**: el azul es, según estudios de psicología del color (Elliot & Maier, 2014), el tono asociado de forma más consistente entre culturas con **confianza, estabilidad y seguridad**. Para una red social que maneja datos personales, mensajes privados y transacciones (Marketplace, pagos), reducir la ansiedad del usuario ante la exposición de información es una decisión de diseño deliberada, no estética. Además, el azul es el color con **menor tasa de daltonismo perceptivo** (la deficiencia más común es rojo-verde, no azul-amarillo), lo que maximiza el alcance accesible del color de marca en una audiencia masiva y global.
- **Reducción de fricción en scroll prolongado — Gris neutro `#F0F2F5` / blanco `#FFFFFF`**: el fondo gris muy claro (no blanco puro) reduce el contraste de luminancia entre el fondo y las tarjetas blancas, disminuyendo la **fatiga visual** durante sesiones de scroll largo (el mecanismo de "infinite scroll" es intencionalmente de bajo estímulo cromático para no competir con el contenido —fotos, videos— que sí debe atraer la atención). Es el mismo principio detrás del "eye strain reduction" que llevó a Meta a introducir el dark mode (`#18191A`), que además reduce el consumo de energía en pantallas OLED.
- **Elementos de alerta — Rojo `#F02849`**: el rojo se reserva exclusivamente para notificaciones/alertas porque psicológicamente actúa como **disruptor de atención** (asociado a urgencia/peligro en la cognición humana). Al limitarlo a un solo uso (badges), Facebook evita la "ceguera por sobreexposición" que ocurriría si el rojo se usara en múltiples elementos, preservando su efectividad como disparador de retorno a la app (mecanismo de enganche/retención).
- **Neutralidad del texto — Casi-negro `#050505` en vez de negro puro `#000000`**: reduce el contraste extremo texto-fondo, suavizando la lectura en sesiones prolongadas sin sacrificar legibilidad (principio de diseño tipográfico usado también por iOS/Material Design).

### 3. Auditoría de componentes (las 3 listas a clonar)

| # | Lista | Tipo de iterable | Complejidad de celda |
|---|---|---|---|
| **1** | **Feed principal** | `ListView` vertical, `itemTemplateSelector` con 3 variantes (`skeleton`, `text`, `media`) | Alta: avatar circular, header (nombre + timestamp + ícono de privacidad), cuerpo de texto, media opcional (imagen/video simulado), contador de reacciones, fila de 3 botones de acción (Me gusta / Comentar / Compartir) |
| **2** | **Barra de Historias** (Stories / amigos activos) | `Repeater` horizontal (dentro de un `ScrollView`) anidado como **fila 0** del mismo feed (mismo *view-type* pattern que usa la app real; `Repeater` se usa porque el `ListView` nativo de NativeScript no soporta orientación horizontal) | Media: preview de imagen, avatar superpuesto, nombre, indicador de "en vivo" |
| **3** | **Notificaciones** | `ListView` vertical, `itemTemplateSelector` con 2 variantes (`standard`, `friendRequest`) | Media-Alta: avatar + badge de tipo superpuesto, mensaje, timestamp, estado leído/no-leído, y (solo en solicitudes de amistad) par de botones Confirmar/Eliminar |

> Se optó por **Notificaciones** (en vez de Menú Lateral) como Lista 3 porque exhibe el patrón de `itemTemplateSelector` más rico (dos layouts de celda claramente distintos), reforzando el mismo concepto técnico ya introducido en el Feed.

---

## ENTREGABLE 2 — FASE B: Desarrollo Técnico (resumen de decisiones)

Todo el código vive en `app/` (ver árbol arriba). Puntos clave de la implementación:

- **Modelos (`app/models/`)**: interfaces TypeScript puras, sin lógica — Single Responsibility.
- **Servicios (`app/services/`)**: `IFeedDataSource`, `IStoryDataSource`, `INotificationDataSource` son interfaces pequeñas y cohesivas (**ISP**). `MockDataService` las implementa todas, pero cada ViewModel depende únicamente de la interfaz que necesita, nunca de la clase concreta (**DIP**) — sustituir el mock por una API real no exige tocar vistas ni view-models.
- **Rendimiento nativo (60 FPS)**:
  - Un **único `ListView`** (recycler nativo — `RecyclerView` en Android / `UITableView` en iOS) renderiza *tanto* la fila de Historias como los posts, usando `itemTemplateSelector` con 3 claves (`stories`, `text`, `media`). Esto evita el anti-patrón de anidar un `ListView` dentro de un `ScrollView`, que rompe el reciclaje de celdas del contenedor principal.
  - `Image` usa `decodeWidth`/`decodeHeight` para no decodificar bitmaps a resolución completa en memoria — crítico para listas largas de fotos.
  - `ObservableArray.setItem(index, item)` en vez de reemplazar el arreglo completo: solo la celda afectada se re-renderiza al dar "Me gusta".
  - `loadMoreItems` del `ListView` implementa paginación nativa (carga incremental de 10 posts) en vez de cargar todo el dataset de una vez.
- **Open/Closed**: agregar un nuevo tipo de tarjeta (ej. "encuesta") solo requiere un nuevo `case` en `templateSelector` + un nuevo `<template>` en el XML; el resto del código no se modifica.
- **Micro-interacciones nativas (`app/common/animations.ts`)** — las 3 exigidas por la guía:
  1. **Transición de entrada** — `animateEntrance()`: fade-in + deslizamiento de 16px hacia arriba, disparado una sola vez por celda (nunca en cada reciclaje de scroll) vía el evento `itemLoading` del `ListView` (`feed-page.ts` / `notifications-page.ts`).
  2. **Efecto al presionar** — `pulseLike()`: rebote de escala (85% → 118% → 100%, ~240ms) en el botón "Me gusta"; además, todos los botones (`action-btn`, `btn-confirm`, `btn-decline`, `notif-row`) usan la pseudo-clase nativa `:highlighted` en CSS para feedback táctil inmediato.
  3. **Estado de carga (skeleton/shimmer)** — `startShimmer()`: al entrar a Feed o Notificaciones se muestran de inmediato filas `templateType: "skeleton"` (bloques grises con loop de opacidad) mientras se simula la latencia de red (900ms / 700ms); `onItemUnloading` detiene el loop para no dejar animaciones huérfanas (fuga de memoria) al reciclar la celda.

---

## ENTREGABLE 3 — FASE C: Crítica y Propuesta de Mejora de UX

### 1. Análisis crítico

**Falla identificada: ambigüedad de la barra de navegación inferior.**
La app real de Facebook usa 5 íconos casi idénticos en forma y color (todos monocromos, mismo tamaño, sin etiqueta de texto visible por defecto) para secciones con significados muy distintos: *Inicio*, *Amigos*, *Reels/Video*, *Notificaciones* y *Menú*. Estudios de usabilidad (Nielsen Norman Group) muestran que los **íconos sin etiqueta textual** obligan al usuario a memorizar posición en vez de reconocer significado, generando errores de navegación medibles sobre todo en usuarios de mayor edad (segmento 45+ que, como vimos en la Fase A, es un núcleo demográfico creciente de Facebook) y en usuarios nuevos. Adicionalmente, el ícono de "Notificaciones" (una campana) es visualmente muy similar al de "Menú" en tamaños de pantalla pequeños, lo que aumenta el costo cognitivo de cada interacción de navegación repetida decenas de veces por sesión.

### 2. Propuesta de solución

**Propuesta:** combinar siempre ícono + etiqueta de texto corta en la barra de navegación inferior, apoyado en un color de acento (azul de marca) para el estado activo, en vez de depender solo de la forma del glyph.

**Implementación en el clon (`app/views/main/main-page.xml` + `main-page.css`):**
- Se usó el componente nativo `TabView` (`UITabBarController` en iOS / equivalente a `BottomNavigationView` en Android vía `androidTabsPosition="bottom"`) con el `title` de cada `TabViewItem` combinando siempre ícono + texto, en vez de un ícono solo:
  ```xml
  <TabView selectedIndex="0" androidTabsPosition="bottom" class="bottom-nav">
    <TabViewItem title="🏠 Inicio">
      <Frame defaultPage="views/feed/feed-page"></Frame>
    </TabViewItem>
    <TabViewItem title="🔔 Notificaciones">
      <Frame defaultPage="views/notifications/notifications-page"></Frame>
    </TabViewItem>
  </TabView>
  ```
- El estado activo se resuelve con `selected-tab-text-color` en CSS, tiñendo la pestaña activa con el azul de marca `#1877F2` (`main-page.css`), reforzando *dónde estoy* sin ambigüedad.

**Beneficio técnico y de UX:**
- Técnicamente, no añade overhead: `BottomNavigation` sigue siendo el controlador de pestañas nativo (cero coste extra de renderizado vs. usar solo íconos).
- En UX, reduce el tiempo de decisión de navegación (Ley de Hick) al eliminar la ambigüedad símbolo→significado, y mejora la accesibilidad para lectores de pantalla (el `Label` de texto es leído nativamente por TalkBack/VoiceOver, mientras que un ícono-glyph solo depende de que el desarrollador haya seteado `accessibilityLabel` manualmente — algo frecuentemente olvidado).
