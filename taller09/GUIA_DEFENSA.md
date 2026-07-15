# Cómo defender tu clon de Facebook — Taller 09

Guía de apoyo para la defensa oral frente al profesor. Todo lo que necesitas para explicar qué hiciste, por qué lo hiciste así, y demostrar que la app corre de verdad.

---

## 1. Estado del proyecto

| Requisito | Estado |
|---|---|
| Sin WebView (todo nativo) | ✅ Listo |
| 3 listas distintas (Feed, Historias, Notificaciones) | ✅ Listo |
| 60 FPS / reciclaje de celdas | ✅ Listo |
| Transición de entrada | ✅ Listo |
| Efecto al presionar botones | ✅ Listo |
| Estado de carga (skeleton/shimmer) | ✅ Listo |
| Mercado, color, auditoría de listas (Fase A) | ✅ Listo |
| Crítica UX + propuesta implementada (Fase C) | ✅ Listo |
| SOLID / arquitectura de carpetas | ✅ Listo |
| APK generado, instalado y probado en emulador | ✅ Listo |
| **Reservar "Facebook" en el post oficial del curso** | ⚠️ Pendiente — acción manual tuya, no de código |

---

## 2. Cómo probarlo

El APK ya está compilado, no necesitas volver a construir nada para mostrárselo al profesor.

1. El archivo instalable está en:
   `taller09/mobileapp/platforms/android/app/build/outputs/apk/debug/app-debug.apk`
2. Conecta un celular Android (o abre un emulador) y en una terminal ejecuta:
   ```
   adb install -r app-debug.apk
   ```
3. Abre la app instalada — se llama **mobileapp** con el ícono azul de NativeScript.
4. Verás primero bloques grises "parpadeando" (~1 segundo) — es a propósito, simula la carga de red.
5. Luego aparece el feed real: Historias arriba (deslizables), publicaciones abajo, y una barra inferior para cambiar a Notificaciones.

**Si el profesor pide volver a compilar:**
```
cd taller09/mobileapp
ns build android
```
En esta laptop, la primera vez hay que agregar `platforms\android` y `platforms\tempPlugin\core` al PATH antes (detalle en el README) — es un problema de esta máquina con Node.js, no de tu código.

---

## 3. Bugs reales que arreglamos (úsalo a tu favor)

Esto es oro para la defensa: demuestra que **probaste** la app de verdad, no solo escribiste código a ciegas. Si el profesor pregunta "¿probaste esto?", cuenta esta historia.

1. **Sintaxis inválida en XML** — Usé `[height]="180"` (eso es de Angular) en vez de `height="180"` (NativeScript puro). El compilador lo rechazó al instante.
2. **Componente que no existía** — Diseñé la barra inferior con `BottomNavigation`, pero esa versión de NativeScript no lo trae, solo `TabView`. Lo cambié y quedó igual de bien.
3. **Lista horizontal imposible** — Intenté una `ListView` horizontal para las Historias, pero NativeScript no lo soporta. Usé `Repeater` dentro de un `ScrollView` horizontal en su lugar.
4. **Texto que no se traducía** — Un texto como `"· {{ dato }}"` se mostraba literal en pantalla en vez de reemplazarse. Hay que escribir `{{ '· ' + dato }}` completo.
5. **La app instalaba pero no abría** — El manifest de Android tenía un atributo de "namespace" que las versiones nuevas de Android ya no aceptan. Se quita y ya.

---

## 4. Glosario — para explicar cada palabra rara

Si el profesor pregunta "¿qué es X?", aquí tienes la respuesta corta + una comparación fácil de recordar.

**NativeScript sin WebView**
No hay ningún navegador escondido mostrando HTML. Cada elemento (botón, imagen, lista) es un componente real de Android/iOS, tan nativo como si lo hubiera hecho un programador de Android puro.
> *Es como la diferencia entre imprimir una foto de una silla y construir la silla de verdad. Se ve igual desde lejos, pero solo una la puedes usar.*

**ListView y "reciclaje de celdas"**
Si el feed tiene 1000 publicaciones, el teléfono no crea 1000 tarjetas en memoria. Crea unas 8 (las que caben en pantalla) y, al hacer scroll, reutiliza esas mismas 8, solo les cambia el contenido.
> *Es como un salón de clases con 8 sillas para 1000 alumnos que van entrando y saliendo por turnos, en vez de comprar 1000 sillas.*

**itemTemplateSelector**
Le dice a la lista "esta celda dibújala como publicación con foto, esta otra como solo texto, esta otra como el esqueleto de carga". Una sola lista, varios diseños de tarjeta.
> *Es como un mesero que sabe servir el plato en fuente honda si es sopa, y en plato plano si es ensalada — mismo mesero, distinto recipiente según lo que lleva.*

**SOLID (S, I, D que usamos)**
- **S** — cada archivo hace una sola cosa (un modelo solo describe datos, no dibuja nada).
- **I** — hay 3 contratos pequeños (uno por lista) en vez de uno gigante.
- **D** — la lógica de pantalla depende de "una fuente de datos" en abstracto, no del mock específico, así que mañana se puede conectar a un servidor real sin tocar las pantallas.
> *Es como un enchufe universal (D) en vez de soldar el cable del cargador directo a la pared.*

**Shimmer / Skeleton**
Los bloques grises que "parpadean" antes de que cargue el contenido real. Le dicen al usuario "espera, ya casi" en vez de dejar la pantalla en blanco.
> *Es como el mesero que te trae los cubiertos y el vaso de agua mientras la comida se termina de cocinar — sabes que algo ya viene.*

**MVVM (Modelo-Vista-VistaModelo)**
El XML (Vista) solo dibuja. El ViewModel guarda los datos y las acciones ("qué pasa cuando toco Me gusta"). Nunca se mezclan: si mañana cambias el diseño, no tocas la lógica, y viceversa.
> *Es como el guion de una obra (qué pasa) separado del escenario (cómo se ve) — puedes cambiar la escenografía sin reescribir la historia.*

---

## 5. Guión — Fase A (Análisis)

30 segundos por punto. No leas el README en voz alta, resume así:

**¿A quién le sirve Facebook hoy?**
Ya no es la app favorita de los adolescentes, esos se fueron a TikTok/Instagram. Hoy su fuerte es **25 a 54 años en adelante**: gente que usa Marketplace, grupos de barrio y lo ve como "la red social de referencia" más que como entretenimiento.

**¿Por qué el azul `#1877F2`?**
El azul es el color que menos gente confunde por daltonismo (el daltonismo común es rojo-verde) y el que más se asocia con confianza en estudios de psicología del color, clave para una app que guarda tus fotos y mensajes privados.

**¿Por qué esas 3 listas y no otras?**
Elegí Feed, Historias y Notificaciones porque juntas cubren los 3 patrones técnicos distintos que pedía la guía: una lista con celdas de dos diseños (texto/foto), una lista horizontal, y una lista con botones especiales solo en un tipo de celda (solicitud de amistad).

---

## 6. Guión — Fase B (Código)

**¿Cómo garantizas que no haya "lag" con muchos posts?**
Tres cosas: reciclaje de celdas nativo (no se crean 1000 vistas), las imágenes se decodifican ya redimensionadas al tamaño que se van a mostrar (`decodeWidth`/`decodeHeight`), y al dar "Me gusta" solo se actualiza esa tarjeta, no la lista entera.

**Muéstrame las 3 micro-animaciones.**
1. Cada tarjeta entra con un pequeño deslizamiento + aparición gradual la primera vez que se ve.
2. El botón "Me gusta" rebota (85%→118%→100%) al tocarlo, y todos los botones cambian de color al mantenerlos presionados.
3. Los bloques grises "shimmer" mientras carga.

---

## 7. Guión — Fase C (Crítica UX)

**¿Qué le criticas a Facebook real?**
Su barra inferior usa 5 íconos casi idénticos, sin texto, para secciones muy distintas (Inicio, Amigos, Reels, Notificaciones, Menú). Eso obliga a memorizar posición en vez de reconocer significado, un problema medido en estudios de usabilidad, y más grave en el público 45+ que vimos en la Fase A.

**¿Cómo lo arreglaste en tu clon?**
Cada pestaña de mi barra inferior combina ícono + palabra siempre visible ("🏠 Inicio", "🔔 Notificaciones"), y la pestaña activa se pinta del azul de marca. Cero ambigüedad, y no cuesta nada extra en rendimiento.

---

## 8. Si te preguntan algo inesperado

**"¿Por qué NativeScript y no Flutter/React Native?"**
Es una decisión válida de la guía (ambas listadas). NativeScript compila a componentes 100% nativos usando TypeScript + XML, sin motor gráfico propio (a diferencia de Flutter que usa Skia), cada widget que ves es literalmente el widget nativo de Android/iOS.

**"¿Los datos son reales?"**
No, son mocks generados aleatoriamente (nombres, fotos de `picsum.photos`, contadores), así lo pedía la guía ("modelos de datos para poblar de forma masiva"). La arquitectura permite reemplazar el mock por una API real sin tocar las pantallas.

**"¿Qué pasa si agrego una 4ta lista mañana?"**
Creo un modelo nuevo, un método nuevo en el servicio (implementando una interfaz pequeña), un ViewModel, y una vista XML, sin tocar nada de lo que ya existe. Eso es el principio Abierto/Cerrado de SOLID en acción.

---

*Taller 09 — Ingeniería de UI, EPN.*
