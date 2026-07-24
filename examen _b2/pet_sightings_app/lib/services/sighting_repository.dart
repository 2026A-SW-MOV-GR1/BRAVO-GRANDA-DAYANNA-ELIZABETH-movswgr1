import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/pet_sighting.dart';

/// Persiste los avistamientos localmente usando Hive (cada registro se
/// guarda como JSON), lo que evita generar TypeAdapters y funciona igual
/// en Android, iOS, escritorio y web.
class SightingRepository {
  static const _defaultBoxName = 'pet_sightings_box';
  final String _boxName;
  late Box<String> _box;

  /// [boxName] permite usar un nombre distinto por instancia (los tests lo
  /// usan para no compartir la caché en memoria de Hive entre casos, ya que
  /// [Hive.openBox] devuelve el mismo box ya abierto si el nombre coincide,
  /// sin importar el directorio pasado a [Hive.init]).
  SightingRepository({String? boxName}) : _boxName = boxName ?? _defaultBoxName;

  /// [testPath] permite inicializar Hive con un directorio ya conocido
  /// (usado en tests, donde no hay platform channels de path_provider
  /// disponibles) en lugar de resolverlo con [Hive.initFlutter].
  Future<void> init({String? testPath}) async {
    if (testPath != null) {
      Hive.init(testPath);
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox<String>(_boxName);
  }

  List<PetSighting> getAll() {
    return _box.values
        .map((raw) => PetSighting.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.sightedAt.compareTo(a.sightedAt));
  }

  Future<void> save(PetSighting sighting) async {
    await _box.put(sighting.id, jsonEncode(sighting.toJson()));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
