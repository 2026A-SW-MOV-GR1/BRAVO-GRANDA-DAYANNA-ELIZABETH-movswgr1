import 'package:flutter_test/flutter_test.dart';
import 'package:examen_b1/data/data_repository.dart';

// ── Repositorio en memoria para pruebas ─────────────────────────────────────
class InMemoryRepository implements DataRepository {
  final List<Map<String, dynamic>> _store = [];
  int _nextId = 1;

  @override
  Future<List<Map<String, dynamic>>> getAll() async =>
      List.unmodifiable(_store);

  @override
  Future<void> insert(String titulo, String descripcion) async {
    _store.add({'id': _nextId++, 'titulo': titulo, 'descripcion': descripcion});
  }

  @override
  Future<void> update(int id, String titulo, String descripcion) async {
    final idx = _store.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      _store[idx] = {'id': id, 'titulo': titulo, 'descripcion': descripcion};
    }
  }

  @override
  Future<void> delete(int id) async {
    _store.removeWhere((r) => r['id'] == id);
  }
}

// ── Proveedor mínimo para validar la conmutación de motor ───────────────────
class EngineManager {
  DataRepository _repo;
  bool useSecondary;

  EngineManager({this.useSecondary = false}) : _repo = InMemoryRepository();

  DataRepository get repo => _repo;

  void switchEngine(bool value) {
    useSecondary = value;
    _repo = InMemoryRepository();
  }
}

// ── Suite de pruebas ─────────────────────────────────────────────────────────
void main() {
  // Prueba 1: escritura aislada en la capa lógica
  group('Prueba 1 – Escritura aislada en capas lógicas', () {
    test('insert() persiste correctamente y getAll() lo devuelve', () async {
      final repo = InMemoryRepository();

      await repo.insert('Título A', 'Descripción A');
      await repo.insert('Título B', 'Descripción B');

      final records = await repo.getAll();

      expect(records.length, 2);
      expect(records[0]['titulo'], 'Título A');
      expect(records[1]['titulo'], 'Título B');
    });

    test('update() modifica el registro correcto sin afectar a los demás',
        () async {
      final repo = InMemoryRepository();
      await repo.insert('Original', 'Desc');
      await repo.insert('Otro', 'Desc otro');

      final before = await repo.getAll();
      final id = before[0]['id'] as int;

      await repo.update(id, 'Modificado', 'Nueva desc');

      final after = await repo.getAll();
      expect(after[0]['titulo'], 'Modificado');
      expect(after[1]['titulo'], 'Otro');
    });

    test('delete() elimina solo el registro indicado', () async {
      final repo = InMemoryRepository();
      await repo.insert('Para eliminar', 'x');
      await repo.insert('Para conservar', 'y');

      final before = await repo.getAll();
      final idToDelete = before[0]['id'] as int;

      await repo.delete(idToDelete);

      final after = await repo.getAll();
      expect(after.length, 1);
      expect(after[0]['titulo'], 'Para conservar');
    });

    test('dos repos independientes no comparten datos', () async {
      final repoA = InMemoryRepository();
      final repoB = InMemoryRepository();

      await repoA.insert('Solo en A', 'desc');

      final recordsA = await repoA.getAll();
      final recordsB = await repoB.getAll();

      expect(recordsA.length, 1);
      expect(recordsB.length, 0);
    });
  });

  // Prueba 2: conmutación de motor activo
  group('Prueba 2 – Conmutación del motor de datos activo', () {
    test('switchEngine cambia el indicador de motor correctamente', () {
      final manager = EngineManager(useSecondary: false);

      expect(manager.useSecondary, false);

      manager.switchEngine(true);
      expect(manager.useSecondary, true);

      manager.switchEngine(false);
      expect(manager.useSecondary, false);
    });

    test('al conmutar motor se obtiene un repositorio vacío e independiente',
        () async {
      final manager = EngineManager();

      await manager.repo.insert('Registro en motor A', 'desc');
      expect((await manager.repo.getAll()).length, 1);

      manager.switchEngine(true);
      expect((await manager.repo.getAll()).length, 0,
          reason: 'El nuevo motor debe estar vacío tras la conmutación');
    });

    test('los datos del motor anterior no se mezclan tras volver atrás',
        () async {
      final manager = EngineManager();

      await manager.repo.insert('Motor SQLite', 'desc');
      manager.switchEngine(true);
      await manager.repo.insert('Motor Hive', 'desc');

      manager.switchEngine(false);
      final records = await manager.repo.getAll();

      expect(records.every((r) => r['titulo'] != 'Motor Hive'), true,
          reason: 'Los registros de Hive no deben aparecer en SQLite');
    });
  });
}
