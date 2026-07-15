import {
  IFeedDataSource,
  IStoryDataSource,
  INotificationDataSource,
} from "./data-source.interface";
import { PostModel, ReactionType, Reaction, PostTemplateType, PostMediaType } from "../models/post.model";
import { StoryModel } from "../models/story.model";
import { NotificationModel, NotificationType } from "../models/notification.model";

const FIRST_NAMES = [
  "Mateo", "Valentina", "Sebastian", "Camila", "Martina", "Daniel",
  "Isabella", "Emilia", "Santiago", "Renata", "Joaquin", "Antonella",
  "Gabriel", "Domenica", "Kevin", "Ariana", "Andres", "Nicole", "Diego", "Paula",
];
const LAST_NAMES = [
  "Guilca", "Bravo", "Toapanta", "Vega", "Quinatoa", "Salazar",
  "Cevallos", "Chuquimarca", "Andrade", "Yepez", "Cardenas", "Ortiz",
];

const POST_TEXTS = [
  "Que gran dia para salir a caminar por el centro historico!",
  "Termine el taller de NativeScript, el reciclaje de celdas es una locura de rapido",
  "Alguien mas viendo el partido de esta noche?",
  "Nueva receta de encebollado, quedo espectacular",
  "Recordando ese viaje a Banos hace 2 anios... hermoso lugar",
  "Buscando recomendaciones de series para el fin de semana",
  "Feliz de compartir que empece un nuevo proyecto freelance",
  "El clima en Quito no perdona, a llevar paraguas",
];

const NOTIFICATION_MESSAGES: Record<NotificationType, (name: string) => string> = {
  [NotificationType.FriendRequest]: (n) => `${n} te envio una solicitud de amistad.`,
  [NotificationType.Reaction]: (n) => `A ${n} y 12 personas mas les gusto tu publicacion.`,
  [NotificationType.Comment]: (n) => `${n} comento en tu publicacion: "Que buena foto!"`,
  [NotificationType.Mention]: (n) => `${n} te menciono en un comentario.`,
  [NotificationType.GroupActivity]: (n) => `${n} publico en el grupo "EPN - Ingenieria de Software".`,
  [NotificationType.Birthday]: (n) => `Hoy es el cumpleanios de ${n}. Escribele algo!`,
  [NotificationType.Memory]: (n) => `Tienes un recuerdo con ${n} de hace 3 anios.`,
};

function randomItem<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomFullName(): string {
  return `${randomItem(FIRST_NAMES)} ${randomItem(LAST_NAMES)}`;
}

function avatarUrl(seed: number): string {
  return `https://i.pravatar.cc/150?img=${seed % 70}`;
}

function photoUrl(seed: number): string {
  return `https://picsum.photos/seed/fbpost${seed}/800/500`;
}

function buildReactions(): { reactions: Reaction[]; total: number } {
  const pool: ReactionType[] = [
    ReactionType.Like,
    ReactionType.Love,
    ReactionType.Haha,
    ReactionType.Wow,
    ReactionType.Sad,
    ReactionType.Angry,
  ];
  const used = pool.filter(() => Math.random() > 0.5).slice(0, 3);
  const reactions: Reaction[] = (used.length ? used : [ReactionType.Like]).map((type) => ({
    type,
    count: Math.floor(Math.random() * 500) + 1,
  }));
  const total = reactions.reduce((sum, r) => sum + r.count, 0);
  return { reactions, total };
}

/**
 * Implementacion concreta de las 3 fuentes de datos mock.
 * Cumple ISP: implementa 3 interfaces pequenias y cohesivas en lugar
 * de un unico contrato gigante. Cualquier ViewModel puede depender
 * solo de la porcion que necesita (ej. IStoryDataSource).
 */
export class MockDataService
  implements IFeedDataSource, IStoryDataSource, INotificationDataSource
{
  getPosts(count: number): PostModel[] {
    const posts: PostModel[] = [];
    for (let i = 0; i < count; i++) {
      const { reactions, total } = buildReactions();
      const mediaRoll = Math.random();
      const mediaType: PostMediaType = mediaRoll > 0.6 ? "image" : mediaRoll > 0.5 ? "video" : "none";
      const templateType: PostTemplateType = mediaType === "none" ? "text" : "media";

      posts.push({
        id: `post-${i}`,
        authorName: randomFullName(),
        authorAvatarUrl: avatarUrl(i + 1),
        timestamp: `${Math.floor(Math.random() * 23) + 1} h`,
        privacyIcon: Math.random() > 0.5 ? "Publico" : "Amigos",
        text: randomItem(POST_TEXTS),
        mediaType,
        mediaUrl: mediaType !== "none" ? photoUrl(i + 1) : undefined,
        reactions,
        totalReactions: total,
        totalComments: Math.floor(Math.random() * 120),
        totalShares: Math.floor(Math.random() * 40),
        isLikedByUser: false,
        templateType,
      });
    }
    return posts;
  }

  getStories(count: number): StoryModel[] {
    const stories: StoryModel[] = [];
    stories.push({
      id: "story-own",
      userName: "Tu historia",
      avatarUrl: avatarUrl(99),
      storyPreviewUrl: photoUrl(99),
      isOwnStory: true,
      hasUnseenStory: false,
      isLiveNow: false,
    });
    for (let i = 0; i < count; i++) {
      stories.push({
        id: `story-${i}`,
        userName: randomFullName().split(" ")[0],
        avatarUrl: avatarUrl(i + 10),
        storyPreviewUrl: photoUrl(i + 10),
        isOwnStory: false,
        hasUnseenStory: Math.random() > 0.4,
        isLiveNow: Math.random() > 0.85,
      });
    }
    return stories;
  }

  getNotifications(count: number): NotificationModel[] {
    const types = Object.values(NotificationType);
    const notifications: NotificationModel[] = [];
    for (let i = 0; i < count; i++) {
      const type = randomItem(types);
      const name = randomFullName();
      notifications.push({
        id: `notif-${i}`,
        type,
        icon: iconForType(type),
        iconBackgroundColor: colorForType(type),
        actorAvatarUrl: avatarUrl(i + 30),
        message: NOTIFICATION_MESSAGES[type](name),
        timestamp: `${Math.floor(Math.random() * 6) + 1} d`,
        isRead: Math.random() > 0.5,
        templateType: type === NotificationType.FriendRequest ? "friendRequest" : "standard",
      });
    }
    return notifications;
  }
}

/**
 * Glyph (emoji Unicode estandar) superpuesto como badge sobre el avatar
 * del actor en la celda de notificacion. Se evita depender de una fuente
 * de iconos custom (font-icon) para que el mock funcione sin assets extra.
 */
function iconForType(type: NotificationType): string {
  switch (type) {
    case NotificationType.FriendRequest:
      return "👤";
    case NotificationType.Reaction:
      return "👍";
    case NotificationType.Comment:
      return "💬";
    case NotificationType.Mention:
      return "🔔";
    case NotificationType.GroupActivity:
      return "👥";
    case NotificationType.Birthday:
      return "🎂";
    case NotificationType.Memory:
      return "🕰";
    default:
      return "🔔";
  }
}

function colorForType(type: NotificationType): string {
  switch (type) {
    case NotificationType.FriendRequest:
      return "#1877F2";
    case NotificationType.Reaction:
      return "#F33E58";
    case NotificationType.Comment:
      return "#31A24C";
    case NotificationType.Mention:
      return "#F7B125";
    case NotificationType.GroupActivity:
      return "#1877F2";
    case NotificationType.Birthday:
      return "#F7B125";
    case NotificationType.Memory:
      return "#8B5CF6";
    default:
      return "#65676B";
  }
}
