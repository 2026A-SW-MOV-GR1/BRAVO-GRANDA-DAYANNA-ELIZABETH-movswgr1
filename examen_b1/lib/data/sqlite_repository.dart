import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'data_repository.dart';

class SqliteRepository implements DataRepository {
  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'examen_b1.db');
    debugPrint('[INFO] SQLite: inicializando base de datos en $path');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE registros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            descripcion TEXT NOT NULL
          )
        ''');
        debugPrint('[INFO] SQLite: tabla "registros" creada correctamente');
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final db = await _database;
      final result = await db.query('registros');
      debugPrint('[DEBUG] SQLite: getAll() devuelve ${result.length} registros');
      return result;
    } catch (e) {
      debugPrint('[ERROR] SQLite: getAll() fallo -> $e');
      return [];
    }
  }

  @override
  Future<void> insert(String titulo, String descripcion) async {
    try {
      final db = await _database;
      final id = await db.insert('registros', {
        'titulo': titulo,
        'descripcion': descripcion,
      });
      debugPrint('[INFO] SQLite: insert() registro creado con id=$id titulo="$titulo"');
    } catch (e) {
      debugPrint('[ERROR] SQLite: insert() fallo -> $e');
    }
  }

  @override
  Future<void> update(int id, String titulo, String descripcion) async {
    try {
      final db = await _database;
      final rows = await db.update(
        'registros',
        {'titulo': titulo, 'descripcion': descripcion},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('[INFO] SQLite: update() id=$id filas_afectadas=$rows');
    } catch (e) {
      debugPrint('[ERROR] SQLite: update() fallo -> $e');
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      final db = await _database;
      final rows = await db.delete(
        'registros',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('[INFO] SQLite: delete() id=$id filas_afectadas=$rows');
    } catch (e) {
      debugPrint('[ERROR] SQLite: delete() fallo -> $e');
    }
  }
}
