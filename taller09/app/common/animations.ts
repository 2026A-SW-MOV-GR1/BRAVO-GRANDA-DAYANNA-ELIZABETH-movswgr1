import { View } from "@nativescript/core";

/**
 * Micro-interaccion nativa del boton "Me gusta": un rebote corto de escala
 * (85% -> 118% -> 100%) usando el motor de animaciones nativo de la
 * plataforma (Core Animation en iOS / Property Animator en Android),
 * no CSS/JS emulado como en una WebView. Duracion corta (180ms) para no
 * bloquear el hilo de UI ni afectar el scroll del ListView.
 */
export async function pulseLike(target: View): Promise<void> {
  await target.animate({ scale: { x: 0.85, y: 0.85 }, duration: 60 });
  await target.animate({ scale: { x: 1.18, y: 1.18 }, duration: 90 });
  await target.animate({ scale: { x: 1, y: 1 }, duration: 90 });
}

/**
 * Transicion de entrada: cada celda aparece con un pequenio deslizamiento
 * hacia arriba + fade-in (16px -> 0, opacidad 0 -> 1). Se dispara una sola
 * vez por item (ver itemLoading en feed-page.ts / notifications-page.ts),
 * nunca en cada reciclaje de celda al hacer scroll, para no penalizar los 60 FPS.
 */
export async function animateEntrance(target: View): Promise<void> {
  target.opacity = 0;
  target.translateY = 16;
  await target.animate({
    opacity: 1,
    translate: { x: 0, y: 0 },
    duration: 220,
    curve: "easeOut",
  });
}

/**
 * Efecto "shimmer" de esqueleto de carga: alterna la opacidad de una serie
 * de bloques grises (placeholders del tamanio exacto del avatar/texto/imagen
 * reales) mientras los datos aun no llegan. Se detiene limpiando el loop
 * con la bandera "cancelled" para no dejar animaciones huerfanas al
 * reciclar la celda (fuga de memoria comun en listas largas).
 */
export function startShimmer(target: View): () => void {
  let cancelled = false;

  const loop = async () => {
    while (!cancelled) {
      await target.animate({ opacity: 0.4, duration: 500 });
      if (cancelled) break;
      await target.animate({ opacity: 1, duration: 500 });
    }
  };
  loop();

  return () => {
    cancelled = true;
  };
}
