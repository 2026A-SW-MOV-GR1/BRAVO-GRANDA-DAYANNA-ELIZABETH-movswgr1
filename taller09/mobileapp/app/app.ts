import { Application } from "@nativescript/core";

// Import explicito: Repeater (fila de Historias) solo se usa desde XML,
// nunca desde TS, asi que sin esto webpack lo excluye del bundle por
// tree-shaking y el parser de XML no puede resolver el elemento.
import "@nativescript/core/ui/repeater";

// Punto de entrada nativo (sin Angular/Vue): arranca directo sobre el
// TabView que aloja las 3 listas del taller (Feed, Historias, Notificaciones).
Application.run({ moduleName: "views/main/main-page" });
