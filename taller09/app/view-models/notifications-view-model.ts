import { Observable, ObservableArray, EventData } from "@nativescript/core";
import { MockDataService } from "../services/mock-data.service";
import { INotificationDataSource } from "../services/data-source.interface";
import { NotificationModel } from "../models/notification.model";
import { SkeletonRow } from "../common/skeleton-row.model";

export type NotificationListItem = NotificationModel | SkeletonRow;

const SIMULATED_NETWORK_DELAY_MS = 700;
const SKELETON_ROW_COUNT = 5;

/**
 * NotificationsViewModel: orquesta la Lista 3 (Notificaciones).
 * Depende solo de INotificationDataSource (ISP + DIP), igual que FeedViewModel.
 */
export class NotificationsViewModel extends Observable {
  notifications: ObservableArray<NotificationListItem>;

  constructor(source: INotificationDataSource = new MockDataService()) {
    super();

    const skeletons: SkeletonRow[] = Array.from({ length: SKELETON_ROW_COUNT }, (_, i) => ({
      id: `skeleton-${i}`,
      templateType: "skeleton",
    }));
    this.notifications = new ObservableArray<NotificationListItem>(skeletons);

    setTimeout(() => {
      const real = source.getNotifications(25);
      this.notifications.splice(0, this.notifications.length, ...real);
    }, SIMULATED_NETWORK_DELAY_MS);
  }

  /** Usado por el ListView (itemTemplateSelector) para elegir "standard", "friendRequest" o "skeleton". */
  static templateSelector(item: NotificationListItem): string {
    return item.templateType;
  }

  onAcceptRequest(args: EventData): void {
    const button = args.object as any;
    const notification: NotificationModel = button.bindingContext;
    const index = this.notifications.indexOf(notification);
    if (index < 0) return;
    this.notifications.splice(index, 1);
  }

  onDeclineRequest(args: EventData): void {
    this.onAcceptRequest(args);
  }

  onNotificationTap(args: EventData): void {
    const view = args.object as any;
    const item = view.bindingContext as NotificationListItem;
    if (item.templateType === "skeleton") return;

    const notification = item as NotificationModel;
    const index = this.notifications.indexOf(notification);
    if (index < 0 || notification.isRead) return;
    this.notifications.setItem(index, { ...notification, isRead: true });
  }
}
