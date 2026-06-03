import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(AppProvider prov) {
    if (prov.isEditing) {
      if (_tituloCtrl.text != prov.editingTitulo) {
        _tituloCtrl.text = prov.editingTitulo;
      }
      if (_descCtrl.text != prov.editingDescripcion) {
        _descCtrl.text = prov.editingDescripcion;
      }
    }
  }

  void _clearForm(AppProvider prov) {
    _tituloCtrl.clear();
    _descCtrl.clear();
    prov.cancelEdit();
  }

  Future<void> _submit(AppProvider prov) async {
    final titulo = _tituloCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título no puede estar vacío')),
      );
      return;
    }
    if (prov.isEditing) {
      await prov.saveEdit(titulo, desc);
    } else {
      await prov.addRecord(titulo, desc);
    }
    _tituloCtrl.clear();
    _descCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, prov, _) {
        _syncControllers(prov);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Persistencia dual'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              const Text('SQLite', style: TextStyle(color: Colors.white70)),
              Switch(
                value: prov.useHive,
                onChanged: (val) => prov.toggleEngine(val),
                activeThumbColor: Colors.amber,
                inactiveThumbColor: Colors.white70,
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('NoSQL', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          body: Column(
            children: [
              _ActiveChip(prov: prov),
              _Form(
                tituloCtrl: _tituloCtrl,
                descCtrl: _descCtrl,
                isEditing: prov.isEditing,
                onSubmit: () => _submit(prov),
                onCancel: () => _clearForm(prov),
              ),
              const Divider(height: 1),
              Expanded(
                child: prov.records.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin registros. Agrega el primero.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: prov.records.length,
                        separatorBuilder: (context, idx) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (context, index) {
                          final rec = prov.records[index];
                          final id = rec['id'] as int;
                          final isSelected = prov.editingId == id;
                          return ListTile(
                            tileColor: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withAlpha(80)
                                : null,
                            title: Text(
                              rec['titulo'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(rec['descripcion'] as String),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  tooltip: 'Editar',
                                  onPressed: () => prov.startEdit(
                                    id,
                                    rec['titulo'] as String,
                                    rec['descripcion'] as String,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  tooltip: 'Eliminar',
                                  onPressed: () =>
                                      _confirmDelete(context, prov, id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppProvider prov, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Confirmas la eliminación de este registro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await prov.deleteRecord(id);
  }
}

class _ActiveChip extends StatelessWidget {
  final AppProvider prov;
  const _ActiveChip({required this.prov});

  @override
  Widget build(BuildContext context) {
    final isHive = prov.useHive;
    return Container(
      width: double.infinity,
      color: isHive ? Colors.amber.shade50 : Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Chip(
        avatar: Icon(
          isHive ? Icons.storage : Icons.table_rows,
          size: 18,
          color: isHive ? Colors.amber.shade800 : Colors.blue.shade800,
        ),
        label: Text(
          prov.activeOriginLabel,
          style: TextStyle(
            color: isHive ? Colors.amber.shade900 : Colors.blue.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor:
            isHive ? Colors.amber.shade100 : Colors.blue.shade100,
        side: BorderSide(
          color: isHive ? Colors.amber.shade300 : Colors.blue.shade300,
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  final TextEditingController tituloCtrl;
  final TextEditingController descCtrl;
  final bool isEditing;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _Form({
    required this.tituloCtrl,
    required this.descCtrl,
    required this.isEditing,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: tituloCtrl,
            decoration: const InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSubmit,
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Guardar cambios' : 'Agregar'),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
