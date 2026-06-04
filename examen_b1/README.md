# Examen B1 — Persistencia Dual con Patrón Repositorio

Aplicación Flutter desarrollada como examen del primer bimestre. Demuestra el uso de dos bases de datos distintas (SQLite y Hive/NoSQL) que se pueden intercambiar en tiempo real desde la interfaz, sin que la pantalla sepa cuál está activa por detrás.

---

## Tecnología usada

| Capa | Herramienta |
|---|---|
| Framework | Flutter (Dart) |
| Base de datos relacional | SQLite — `sqflite` |
| Base de datos NoSQL | Hive |
| Gestión de estado | Provider (`ChangeNotifier`) |
| Pruebas unitarias | `flutter_test` |

---

## Qué hace la app

La app tiene una sola pantalla con un **Switch en la barra superior** que dice "SQLite ↔ NoSQL". Al moverlo, la lista de registros cambia al instante para mostrar los datos de la base seleccionada — cada una guarda sus propios datos de forma completamente independiente.

Desde la pantalla se puede:

- **Agregar** un registro con título y descripción.
- **Editar** cualquier registro existente (el formulario se pre-llena con los datos actuales).
- **Eliminar** un registro con confirmación.
- **Cambiar de base de datos** con el Switch sin perder los datos de ninguna de las dos.

Un chip de colores debajo de la barra indica siempre cuál base está activa: **azul para SQLite**, **amarillo para Hive**.

---

## Estructura del proyecto

```
examen_b1/
├── lib/
│   ├── main.dart                  # Punto de entrada, inicialización de Hive y Provider
│   ├── data/
│   │   ├── data_repository.dart   # Contrato (interfaz) con las 4 operaciones básicas
│   │   ├── sqlite_repository.dart # Implementación con SQLite (tablas SQL)
│   │   └── hive_repository.dart   # Implementación con Hive (clave-valor NoSQL)
│   ├── providers/
│   │   └── app_provider.dart      # Estado global: maneja el motor activo y la lista
│   └── screens/
│       └── home_screen.dart       # Pantalla principal con formulario y lista
└── test/
    └── persistencia_test.dart     # Suite de pruebas unitarias
```

---

## Cómo abrir y correr el proyecto

**Requisitos previos:** tener Flutter instalado y un emulador Android activo (o dispositivo físico conectado).

```bash
# 1. Ir a la carpeta del proyecto
cd examen_b1

# 2. Instalar dependencias
flutter pub get

# 3. Correr la app
flutter run
```

---

## Cómo correr las pruebas unitarias

```bash
# Desde la carpeta examen_b1
flutter test test/persistencia_test.dart
```

Deben pasar **8 pruebas** en total. La salida esperada es:

```
All tests passed!
```

---

## Rúbrica cubierta

### 40% — Conmutación correcta entre SQL y NoSQL

El Switch de la barra superior cambia el motor de base de datos activo en tiempo real. SQLite e Hive guardan sus datos de forma completamente separada — agregar un registro en uno no afecta al otro. Al cambiar de motor, la lista se actualiza sola gracias a Provider (`notifyListeners()`), sin recargar la app.

### 20% — Abstracción y Arquitectura (Patrón Repositorio)

Se definió una interfaz `DataRepository` con 4 operaciones: `getAll`, `insert`, `update` y `delete`. Tanto `SqliteRepository` como `HiveRepository` implementan esa misma interfaz. La pantalla solo habla con el contrato — nunca sabe si por detrás hay SQL o NoSQL. Esto permite cambiar de base de datos enchufando otro repositorio sin tocar la UI. Cada operación imprime logs en consola con su resultado para trazabilidad.

### 20% — Suite de Pruebas Unitarias

Las pruebas usan un repositorio en memoria (`InMemoryRepository`) que cumple el mismo contrato, sin necesitar SQLite ni Hive reales. Se validan 8 casos:

- `insert()` persiste y `getAll()` lo devuelve correctamente.
- `update()` modifica solo el registro indicado, sin tocar los demás.
- `delete()` elimina únicamente el registro indicado.
- Dos repositorios distintos no comparten datos entre sí.
- El Switch cambia correctamente el indicador de motor activo.
- Al cambiar de motor, la nueva base empieza vacía.
- Los datos del motor anterior no aparecen al volver atrás.
- Al conmutar y regresar, los datos de cada motor se mantienen aislados.

### 20% — Sustentación Oral

El diseño sigue el Patrón Repositorio para separar la lógica de negocio del detalle de persistencia. La decisión de usar Provider como gestor de estado permite que cualquier cambio en el motor o en los datos se propague automáticamente a la UI sin lógica extra en la pantalla. Las pruebas no dependen de ninguna librería externa ni del sistema de archivos, lo que las hace rápidas, confiables y ejecutables en cualquier entorno.
