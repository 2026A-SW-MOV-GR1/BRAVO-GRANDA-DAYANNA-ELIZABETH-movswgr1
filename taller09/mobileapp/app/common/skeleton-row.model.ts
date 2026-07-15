/**
 * Fila placeholder compartida por Feed y Notificaciones mientras se
 * simula la latencia de red (estado de carga con shimmer). Vive en
 * common/ porque no pertenece al dominio de ninguna de las 2 listas,
 * evitando duplicar el mismo tipo en cada view-model.
 */
export interface SkeletonRow {
  id: string;
  templateType: "skeleton";
}
