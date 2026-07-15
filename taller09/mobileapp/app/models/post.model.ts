/**
 * Modelo de datos para el Feed Principal (Lista 1).
 * "templateType" habilita el patrón Open/Closed en el ListView:
 * se pueden agregar nuevos tipos de tarjeta sin modificar el itemTemplateSelector existente.
 */
export enum ReactionType {
  Like = "Like",
  Love = "Love",
  Haha = "Haha",
  Wow = "Wow",
  Sad = "Sad",
  Angry = "Angry",
}

export interface Reaction {
  type: ReactionType;
  count: number;
}

export type PostMediaType = "none" | "image" | "video" | "album";
export type PostTemplateType = "text" | "media" | "shared";

export interface PostModel {
  id: string;
  authorName: string;
  authorAvatarUrl: string;
  timestamp: string;
  privacyIcon: string; // glyph: globe (público), grupo, candado (amigos)
  text: string;
  mediaType: PostMediaType;
  mediaUrl?: string;
  reactions: Reaction[];
  totalReactions: number;
  totalComments: number;
  totalShares: number;
  isLikedByUser: boolean;
  templateType: PostTemplateType;
}
