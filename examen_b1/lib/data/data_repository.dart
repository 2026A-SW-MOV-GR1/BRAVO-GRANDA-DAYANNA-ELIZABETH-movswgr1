abstract class DataRepository {
  Future<List<Map<String, dynamic>>> getAll();
  Future<void> insert(String titulo, String descripcion);
  Future<void> update(int id, String titulo, String descripcion);
  Future<void> delete(int id);
}
