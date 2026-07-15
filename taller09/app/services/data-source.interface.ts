import { PostModel } from "../models/post.model";
import { StoryModel } from "../models/story.model";
import { NotificationModel } from "../models/notification.model";

/**
 * Interface Segregation Principle: cada ViewModel depende únicamente
 * de la interfaz que necesita, no de un "God Service" monolítico.
 *
 * Dependency Inversion Principle: los ViewModels dependen de estas
 * abstracciones, nunca de MockDataService directamente. Esto permite,
 * a futuro, reemplazar los mocks por un ApiDataService real sin tocar
 * ninguna vista ni view-model.
 */
export interface IFeedDataSource {
  getPosts(count: number): PostModel[];
}

export interface IStoryDataSource {
  getStories(count: number): StoryModel[];
}

export interface INotificationDataSource {
  getNotifications(count: number): NotificationModel[];
}
