import { Observable, ObservableArray, EventData } from "@nativescript/core";
import { MockDataService } from "../services/mock-data.service";
import { IFeedDataSource, IStoryDataSource } from "../services/data-source.interface";
import { PostModel } from "../models/post.model";
import { StoryModel } from "../models/story.model";
import { pulseLike } from "../common/animations";
import { SkeletonRow } from "../common/skeleton-row.model";

/**
 * "stories" es una fila sintetica (view-type propio) inyectada como
 * primer elemento del mismo ListView que renderiza los posts. Asi el
 * feed completo (historias + publicaciones) usa un UNICO recycler
 * nativo -tal como lo hace la app real de Facebook con un solo
 * RecyclerView multi-viewType- en vez de anidar un ListView dentro
 * de un ScrollView (lo cual rompe el reciclaje de celdas).
 */
export interface StoriesRow {
  id: "stories-row";
  templateType: "stories";
  stories: StoryModel[];
}

export type FeedListItem = StoriesRow | PostModel | SkeletonRow;

const SIMULATED_NETWORK_DELAY_MS = 900;
const SKELETON_ROW_COUNT = 4;

export class FeedViewModel extends Observable {
  items: ObservableArray<FeedListItem>;

  constructor(
    private feedSource: IFeedDataSource = new MockDataService(),
    storySource: IStoryDataSource = new MockDataService()
  ) {
    super();

    // 1) Estado de carga: se muestran N celdas "skeleton" (shimmer) de inmediato,
    //    igual que Facebook, mientras se simula la latencia de red.
    const skeletons: SkeletonRow[] = Array.from({ length: SKELETON_ROW_COUNT }, (_, i) => ({
      id: `skeleton-${i}`,
      templateType: "skeleton",
    }));
    this.items = new ObservableArray<FeedListItem>(skeletons);

    // 2) Tras la "latencia de red", se reemplazan los skeletons por el contenido real
    //    en una sola operacion (splice) para disparar un unico change-notify.
    setTimeout(() => {
      const storiesRow: StoriesRow = {
        id: "stories-row",
        templateType: "stories",
        stories: storySource.getStories(15),
      };
      const posts = feedSource.getPosts(30);
      this.items.splice(0, this.items.length, storiesRow, ...posts);
    }, SIMULATED_NETWORK_DELAY_MS);
  }

  /**
   * Selector de plantilla usado por el ListView (XML: itemTemplateSelector).
   * Anadir un nuevo tipo de tarjeta (ej. "poll" o "shared") solo implica
   * sumar un caso aqui y un nuevo <template> en el XML: Open/Closed Principle,
   * el ListView y el resto del ViewModel no se modifican.
   */
  static templateSelector(item: FeedListItem): string {
    return item.templateType;
  }

  /**
   * Micro-interaccion del boton "Me gusta": alterna el estado optimistamente
   * (sin esperar respuesta de red) para que la UI responda en el mismo frame,
   * clave para mantener la sensacion de 60 FPS.
   */
  onToggleLike(args: EventData): void {
    const tappedButton = args.object as any;
    const post: PostModel = tappedButton.bindingContext;
    const index = this.items.indexOf(post);
    if (index < 0) return;

    const updated: PostModel = {
      ...post,
      isLikedByUser: !post.isLikedByUser,
      totalReactions: post.isLikedByUser ? post.totalReactions - 1 : post.totalReactions + 1,
    };

    // ObservableArray.setItem notifica solo a la celda afectada;
    // el ListView reutiliza la misma vista reciclada sin reconstruir la lista completa.
    this.items.setItem(index, updated);

    if (!post.isLikedByUser) {
      pulseLike(tappedButton);
    }
  }

  onLoadMorePosts(): void {
    const morePosts = this.feedSource.getPosts(10);
    morePosts.forEach((p) => this.items.push(p));
  }
}
