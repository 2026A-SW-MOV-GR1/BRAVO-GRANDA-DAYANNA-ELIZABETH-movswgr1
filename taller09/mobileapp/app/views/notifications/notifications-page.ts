import { Page, NavigatedData } from "@nativescript/core";
import { NotificationsViewModel, NotificationListItem } from "../../view-models/notifications-view-model";
import { startShimmer, animateEntrance } from "../../common/animations";

export function onNavigatingTo(args: NavigatedData): void {
  const page = args.object as Page;
  page.bindingContext = new NotificationsViewModel();
}

export function templateSelector(item: NotificationListItem): string {
  return NotificationsViewModel.templateSelector(item);
}

const alreadyAnimatedIds = new Set<string>();
const activeShimmers = new WeakMap<object, () => void>();

export function onItemLoading(args: any): void {
  const view = args.view;
  const item: NotificationListItem = args.item;
  if (!view || !item) return;

  if (item.templateType === "skeleton") {
    activeShimmers.get(view)?.();
    activeShimmers.set(view, startShimmer(view));
    return;
  }

  const id = (item as any).id as string;
  if (id && !alreadyAnimatedIds.has(id)) {
    alreadyAnimatedIds.add(id);
    animateEntrance(view);
  }
}

export function onItemUnloading(args: any): void {
  const stop = activeShimmers.get(args.view);
  if (stop) {
    stop();
    activeShimmers.delete(args.view);
  }
}
