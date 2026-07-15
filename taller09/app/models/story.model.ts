/**
 * Modelo de datos para la Barra Horizontal de Historias / Amigos Activos (Lista 2).
 */
export interface StoryModel {
  id: string;
  userName: string;
  avatarUrl: string;
  storyPreviewUrl: string;
  isOwnStory: boolean;
  hasUnseenStory: boolean;
  isLiveNow: boolean;
}
