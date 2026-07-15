/**
 * Modelo de datos para la Pantalla de Notificaciones (Lista 3).
 * "templateType" permite distinguir la celda de "Solicitud de amistad" (con botones
 * Confirmar/Eliminar) del resto de notificaciones estándar, vía itemTemplateSelector.
 */
export enum NotificationType {
  FriendRequest = "FriendRequest",
  Reaction = "Reaction",
  Comment = "Comment",
  Mention = "Mention",
  GroupActivity = "GroupActivity",
  Birthday = "Birthday",
  Memory = "Memory",
}

export type NotificationTemplateType = "standard" | "friendRequest";

export interface NotificationModel {
  id: string;
  type: NotificationType;
  icon: string; // glyph superpuesto (badge) sobre el avatar del actor
  iconBackgroundColor: string;
  actorAvatarUrl: string;
  message: string;
  timestamp: string;
  isRead: boolean;
  templateType: NotificationTemplateType;
}
