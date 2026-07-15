import { Page, NavigatedData } from "@nativescript/core";
import { FeedViewModel, FeedListItem } from "../../view-models/feed-view-model";
import { startShimmer, animateEntrance } from "../../common/animations";

export function onNavigatingTo(args: NavigatedData): void {
  const page = args.object as Page;
  page.bindingContext = new FeedViewModel();
}

/**
 * Resuelta por el ListView (itemTemplateSelector="templateSelector") para
 * decidir, por cada fila, cual <template key="..."> renderizar: "skeleton",
 * "stories", "text" o "media". Se delega en FeedViewModel para mantener la
 * logica de seleccion junto al resto del estado del feed (cohesion).
 */
export function templateSelector(item: FeedListItem): string {
  return FeedViewModel.templateSelector(item);
}

// ids que ya recibieron la animacion de entrada, para no repetirla en cada
// reciclaje de celda durante el scroll (solo la 1ra vez que aparece cada item).
const alreadyAnimatedIds = new Set<string>();
const activeShimmers = new WeakMap<object, () => void>();

/** ListView.itemLoading: arranca el shimmer en skeletons y la entrada en el resto. */
export function onItemLoading(args: any): void {
  const view = args.view;
  const item: FeedListItem = args.item;
  if (!view || !item) return;

  if (item.templateType === "skeleton") {
    activeShimmers.get(view)?.(); // por si el binding reusa la vista sin pasar por itemUnloading
    activeShimmers.set(view, startShimmer(view));
    return;
  }

  const id = (item as any).id as string;
  if (id && !alreadyAnimatedIds.has(id)) {
    alreadyAnimatedIds.add(id);
    animateEntrance(view);
  }
}

/** ListView.itemUnloading: detiene el shimmer para no dejar loops de animacion huerfanos (fuga de memoria). */
export function onItemUnloading(args: any): void {
  const stop = activeShimmers.get(args.view);
  if (stop) {
    stop();
    activeShimmers.delete(args.view);
  }
}
