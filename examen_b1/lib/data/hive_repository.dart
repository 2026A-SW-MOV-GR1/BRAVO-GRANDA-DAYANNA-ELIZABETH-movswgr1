import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'data_repository.dart';

class HiveRepository implements DataRepository {
  static const _boxName = 'registros_hive';

  Future<Box> get _box async => Hive.box(_boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
      debugPrint('[INFO] Hive: caja "$_boxName" abierta correctamente');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final box = await _box;
      final result = box.keys.map((key) {
        final value = box.get(key) as Map;
        return {
          'id': key as int,
          'titulo': value['titulo'] as String,
          'descripcion': value['descripcion'] as String,
        };
      }).toList();
      debugPrint('[DEBUG] Hive: getAll() devuelve ${result.length} registros');
      return result;
    } catch (e) {
      debugPrint('[ERROR] Hive: getAll() fallo -> $e');
      return [];
    }
  }

  @override
  Future<void> insert(String titulo, String descripcion) async {
    try {
      final box = await _box;
      final key = await box.add({'titulo': titulo, 'descripcion': descripcion});
      debugPrint('[INFO] Hive: insert() registro creado con key=$key titulo="$titulo"');
    } catch (e) {
      debugPrint('[ERROR] Hive: insert() fallo -> $e');
    }
  }

  @override
  Future<void> update(int id, String titulo, String descripcion) async {
    try {
      final box = await _box;
      await box.put(id, {'titulo': titulo, 'descripcion': descripcion});
      debugPrint('[INFO] Hive: update() key=$id actualizado correctamente');
    } catch (e) {
      debugPrint('[ERROR] Hive: update() fallo -> $e');
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      final box = await _box;
      await box.delete(id);
      debugPrint('[INFO] Hive: delete() key=$id eliminado correctamente');
    } catch (e) {
      debugPrint('[ERROR] Hive: delete() fallo -> $e');
    }
  }
}
