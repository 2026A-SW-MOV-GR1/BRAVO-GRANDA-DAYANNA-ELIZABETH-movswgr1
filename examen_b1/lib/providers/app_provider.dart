import 'package:flutter/foundation.dart';
import '../data/data_repository.dart';
import '../data/sqlite_repository.dart';
import '../data/hive_repository.dart';

class AppProvider extends ChangeNotifier {
  bool _useHive = false;
  List<Map<String, dynamic>> _records = [];

  int? _editingId;
  String editingTitulo = '';
  String editingDescripcion = '';

  late DataRepository _repo;

  bool get useHive => _useHive;
  List<Map<String, dynamic>> get records => _records;
  int? get editingId => _editingId;
  bool get isEditing => _editingId != null;

  String get activeOriginLabel =>
      _useHive ? 'Origen activo: NoSQL' : 'Origen activo: SQLite';

  AppProvider() {
    _repo = SqliteRepository();
    debugPrint('[INFO] AppProvider: motor inicial -> SQLite');
    loadRecords();
  }

  Future<void> toggleEngine(bool value) async {
    _useHive = value;
    _repo = value ? HiveRepository() : SqliteRepository();
    debugPrint('[INFO] AppProvider: motor conmutado -> ${value ? "NoSQL (Hive)" : "SQLite"}');
    cancelEdit();
    await loadRecords();
  }

  Future<void> loadRecords() async {
    _records = await _repo.getAll();
    notifyListeners();
  }

  Future<void> addRecord(String titulo, String descripcion) async {
    if (titulo.trim().isEmpty) return;
    await _repo.insert(titulo.trim(), descripcion.trim());
    await loadRecords();
  }

  Future<void> saveEdit(String titulo, String descripcion) async {
    if (_editingId == null || titulo.trim().isEmpty) return;
    await _repo.update(_editingId!, titulo.trim(), descripcion.trim());
    cancelEdit();
    await loadRecords();
  }

  Future<void> deleteRecord(int id) async {
    await _repo.delete(id);
    if (_editingId == id) cancelEdit();
    await loadRecords();
  }

  void startEdit(int id, String titulo, String descripcion) {
    _editingId = id;
    editingTitulo = titulo;
    editingDescripcion = descripcion;
    notifyListeners();
  }

  void cancelEdit() {
    _editingId = null;
    editingTitulo = '';
    editingDescripcion = '';
    notifyListeners();
  }
}
