/**
 * Paleta cromatica oficial de Facebook (Entregable 1, punto 2).
 * Centralizar los hex aqui evita "magic strings" repetidos en cada CSS
 * y facilita el soporte de tema claro/oscuro (Single Responsibility:
 * este modulo solo se encarga de exponer constantes de diseño).
 */
export const FacebookPalette = {
  // Marca
  primaryBlue: "#1877F2",
  primaryBlueDark: "#2374E1",

  // Fondos
  backgroundLight: "#F0F2F5",
  backgroundDark: "#18191A",
  cardLight: "#FFFFFF",
  cardDark: "#242526",

  // Texto
  textPrimaryLight: "#050505",
  textPrimaryDark: "#E4E6EB",
  textSecondaryLight: "#65676B",
  textSecondaryDark: "#B0B3B8",

  // Divisores
  divider: "#CED0D4",
  dividerDark: "#3E4042",

  // Alertas / notificaciones
  notificationRed: "#F02849",

  // Reacciones
  reactionLike: "#1877F2",
  reactionLove: "#F33E58",
  reactionHahaWow: "#F7B125",
  reactionAngry: "#E9710F",

  // Estados
  onlineGreen: "#31A24C",
};
