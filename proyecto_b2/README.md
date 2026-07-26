# Proyecto Grupal — Gestión de Mascotas Perdidas

Ecosistema de 4 aplicaciones móviles independientes, cada una en una
tecnología distinta, que se comunican entre sí mediante **Intents
implícitos de Android** siguiendo un flujo secuencial App1 → App2 → App3 →
App4. El contrato de datos completo está documentado en
[`../examen _b2/CONTRATO_INTENTS.md`](../examen%20_b2/CONTRATO_INTENTS.md).

| # | App | Autor/a | Tecnología |
|---|---|---|---|
| 1 | Reportar mascota perdida | Esteban Gómez | Flutter |
| 2 | Avistamientos | Dayanna Bravo | Flutter |
| 3 | Refugios | Melany Lema | Kotlin Multiplatform (KMP) |
| 4 | Reencuentro | Dilan Real | Flutter |

## App 1 — Reportar mascota perdida (Flutter)

Permite al dueño registrar que su mascota se perdió: foto, especie,
descripción, datos de contacto y la **última ubicación conocida** marcada
sobre un mapa interactivo (OpenStreetMap). Al publicar el reporte, envía un
Intent con esos datos para iniciar el flujo en App 2.

## App 2 — Avistamientos (Flutter)

Recibe el caso de mascota perdida vía Intent y centra su mapa interactivo
(OpenStreetMap) en la última ubicación conocida. La comunidad reporta
**avistamientos ciudadanos** tocando el mapa, con marcadores personalizados
según tipo de mascota y estado (visto/encontrado). Desde el detalle de un
avistamiento vinculado al caso, envía un Intent con la ubicación de ese
avistamiento para continuar el flujo en App 3.

## App 3 — Refugios (Kotlin Multiplatform)

Recibe la ubicación del avistamiento vía Intent y muestra en un mapa
interactivo los **refugios de mascotas cercanos** a ese punto. Al
seleccionar un refugio, envía un Intent con los datos del refugio elegido
para continuar el flujo en App 4.

## App 4 — Reencuentro (Flutter)

Recibe los datos del refugio vía Intent y muestra la pantalla final de
reencuentro, con un mapa señalando el **lugar donde la mascota fue
encontrada** (el refugio), cerrando el flujo completo de las 4 apps.

## Archivos de este directorio

Los 4 APKs de depuración (`.apk`) listos para instalar y probar el flujo
completo en un mismo dispositivo/emulador — ver la sección "Cómo ejecutar
el flujo completo" en `CONTRATO_INTENTS.md` para el paso a paso.
