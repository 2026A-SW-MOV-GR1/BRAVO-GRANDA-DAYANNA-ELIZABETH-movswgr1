// =============================================================================
// PROYECTO B1: RED Y ALMACENAMIENTO SEGURO
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto B1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAVEGACIÓN PRINCIPAL
// IndexedStack conserva el estado de cada módulo al cambiar de pestaña.
// setState() en _onTap reconstruye el Scaffold mostrando el módulo correcto.
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [NetworkModule(), StorageModule()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: 'Módulo Red'),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Almacenamiento'),
        ],
      ),
    );
  }
}

// =============================================================================
// MÓDULO 1: CONECTIVIDAD A RED (API REST)
// =============================================================================
class NetworkModule extends StatefulWidget {
  const NetworkModule({super.key});

  @override
  State<NetworkModule> createState() => _NetworkModuleState();
}

class _NetworkModuleState extends State<NetworkModule> {
  final _idCtrl    = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();

  // _loading = true → spinner visible + botones deshabilitados.
  // _loading = false → UI interactiva.
  bool   _loading = false;
  String _status  = '';

  // JSONPlaceholder no persiste los PUT realmente, así que guardamos
  // localmente las ediciones del usuario para que GET las muestre.
  final Map<int, Map<String, String>> _localEdits = {};

  @override
  void dispose() {
    // Liberar controllers al destruir el widget (evita memory leaks).
    _idCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // ─── GET ──────────────────────────────────────────────────────────────────
  // async/await: suspende esta función sin bloquear la UI mientras espera
  // la respuesta HTTP. Flutter sigue renderizando el spinner durante la espera.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _get() async {
    final id = int.tryParse(_idCtrl.text.trim());
    if (id == null) return;

    setState(() { _loading = true; _status = ''; });

    try {
      final res = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'),
      );

      if (!mounted) return; // Guarda de ciclo de vida post-await

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        // Si el usuario ya editó este ID con PUT, mostrar su versión local.
        // JSONPlaceholder no guarda realmente los cambios del servidor.
        final local = _localEdits[id];
        _titleCtrl.text = local?['title'] ?? data['title'] as String;
        _bodyCtrl.text  = local?['body']  ?? data['body']  as String;
        setState(() => _status = local != null
            ? 'Estado: post cargado (con tus ediciones)'
            : 'Estado: post cargado');
      } else {
        setState(() => _status = 'Estado: error ${res.statusCode}');
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Estado: error de conexión');
    } finally {
      // finally siempre se ejecuta: apaga el spinner pase lo que pase.
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── PUT ──────────────────────────────────────────────────────────────────
  // Toma el texto ACTUAL de los TextFields (puede ser el original del GET
  // o cualquier modificación manual del usuario) y lo envía al API.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _put() async {
    final id = int.tryParse(_idCtrl.text.trim());
    if (id == null) return;

    setState(() { _loading = true; _status = ''; });

    try {
      final res = await http.put(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'id':     id,
          'title':  _titleCtrl.text,
          'body':   _bodyCtrl.text,
          'userId': 1,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        // Guardar la edición localmente para que GET la muestre luego.
        _localEdits[id] = {
          'title': _titleCtrl.text,
          'body':  _bodyCtrl.text,
        };
        setState(() => _status = 'Estado: actualizado (200 OK)');
      } else {
        setState(() => _status = 'Estado: error ${res.statusCode}');
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Estado: error de conexión');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo Red (API REST)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Fila: Post ID + botón GET ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idCtrl,
                        // Abre teclado numérico nativo en el dispositivo.
                        keyboardType: TextInputType.number,
                        // Bloquea cualquier carácter que no sea dígito.
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        // enabled: false deshabilita el TextField visualmente
                        // durante la carga (sin interacción posible).
                        enabled: !_loading,
                        decoration: const InputDecoration(
                          labelText: 'Post ID',
                          hintText: '1 – 100',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ElevatedButton(
                        // onPressed: null → botón deshabilitado durante la carga.
                        onPressed: _loading ? null : _get,
                        child: const Text('GET'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── TextField editable: Title ─────────────────────────────
                // Se pre-llena con la respuesta del GET, pero el usuario
                // puede borrarlo o escribir lo que quiera antes del PUT.
                TextField(
                  controller: _titleCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                // ── TextField editable: Body (multiline) ──────────────────
                TextField(
                  controller: _bodyCtrl,
                  enabled: !_loading,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Botón PUT ─────────────────────────────────────────────
                ElevatedButton(
                  onPressed: _loading ? null : _put,
                  child: const Text('PUT'),
                ),

                const SizedBox(height: 8),

                // ── Etiqueta de estado dinámica ───────────────────────────
                // Muestra "Estado: post cargado" o "Estado: actualizado (200 OK)"
                if (_status.isNotEmpty)
                  Text(
                    _status,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: _status.contains('error')
                          ? Colors.red
                          : Colors.green.shade700,
                    ),
                  ),
              ],
            ),
          ),

          // ── Indicador de carga superpuesto ────────────────────────────────
          // Visible solo mientras _loading == true.
          // Cubre la pantalla impidiendo toques accidentales dobles.
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// =============================================================================
// MÓDULO 2: PERSISTENCIA Y ALMACENAMIENTO SEGURO
// =============================================================================
class StorageModule extends StatefulWidget {
  const StorageModule({super.key});

  @override
  State<StorageModule> createState() => _StorageModuleState();
}

class _StorageModuleState extends State<StorageModule> {
  final _secureStorage = const FlutterSecureStorage();

  // Opción activa en el grupo de RadioListTile.
  String _selectedStorage = 'SharedPreferences';

  static const _options = [
    'SharedPreferences',
    'DataStore',
    'EncryptedSharedPreferences',
  ];

  // Controllers de la sección "Guardar secreto"
  final _saveKeyCtrl   = TextEditingController();
  final _saveValueCtrl = TextEditingController();

  // Controllers de la sección "Recuperar secreto"
  final _readKeyCtrl = TextEditingController();

  // Valor recuperado; null = aún no se ha consultado (o no se encontró).
  String? _readResult;

  bool _loading = false;

  @override
  void dispose() {
    _saveKeyCtrl.dispose();
    _saveValueCtrl.dispose();
    _readKeyCtrl.dispose();
    super.dispose();
  }

  // ─── GUARDAR ──────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final key   = _saveKeyCtrl.text.trim();
    final value = _saveValueCtrl.text.trim();

    if (key.isEmpty || value.isEmpty) {
      _showAlert('La llave y el valor no pueden estar vacíos.');
      return;
    }

    setState(() => _loading = true);

    try {
      if (_selectedStorage == 'SharedPreferences') {
        // shared_preferences: texto plano, sin cifrado.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } else {
        // flutter_secure_storage: cifrado AES-256 con Android Keystore.
        // Cubre tanto "DataStore" como "EncryptedSharedPreferences".
        await _secureStorage.write(key: key, value: value);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardado en $_selectedStorage'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _saveKeyCtrl.clear();
        _saveValueCtrl.clear();
      }
    } catch (_) {
      _showAlert('Error al guardar. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── RECUPERAR ────────────────────────────────────────────────────────────
  // SEGURIDAD: Si la llave no existe, el sistema NO indica si existe o no.
  // La alerta es genérica en ambos casos (llave inexistente o valor vacío).
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _read() async {
    final key = _readKeyCtrl.text.trim();

    if (key.isEmpty) {
      _showAlert('Ingresa una llave para recuperar.');
      return;
    }

    setState(() { _loading = true; _readResult = null; });

    try {
      String? value;

      if (_selectedStorage == 'SharedPreferences') {
        final prefs = await SharedPreferences.getInstance();
        value = prefs.getString(key);
      } else {
        value = await _secureStorage.read(key: key);
      }

      if (!mounted) return;

      if (value == null || value.isEmpty) {
        // Alerta genérica intencionalmente vaga: no confirma si la llave existe.
        _showAlert('Acceso denegado: la llave no existe o está vacía.');
      } else {
        // Inyectar el valor recuperado en el área de resultado.
        setState(() => _readResult = value);
      }
    } catch (_) {
      if (mounted) _showAlert('Error de seguridad al recuperar.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Diálogo de alerta genérico para errores de seguridad.
  void _showAlert(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.security, color: Colors.orange, size: 40),
        title: const Text('Aviso de Seguridad'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Almacenamiento Seguro'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Selector de tipo de almacenamiento (RadioListTile) ─────
                Text(
                  'Tipo de almacenamiento',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                // RadioGroup (Flutter 3.32+): gestiona el valor del grupo
                // en un ancestro, evitando pasar groupValue/onChanged a cada tile.
                RadioGroup<String>(
                  groupValue: _selectedStorage,
                  onChanged: (v) {
                    if (_loading || v == null) return;
                    setState(() {
                      _selectedStorage = v;
                      _readResult = null;
                    });
                  },
                  child: Column(
                    children: _options
                        .map((opt) => RadioListTile<String>(
                              title: Text(opt),
                              value: opt,
                            ))
                        .toList(),
                  ),
                ),

                const Divider(height: 32, thickness: 1),

                // ── SECCIÓN 1: Guardar secreto ────────────────────────────
                Text(
                  'Guardar secreto',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _saveKeyCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'Llave',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _saveValueCtrl,
                  enabled: !_loading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: const Text('GUARDAR'),
                ),

                const Divider(height: 32, thickness: 1),

                // ── SECCIÓN 2: Recuperar secreto ──────────────────────────
                Text(
                  'Recuperar secreto',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Debes conocer la llave exacta de antemano.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _readKeyCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'Llave',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _read,
                  child: const Text('RECUPERAR'),
                ),

                // Valor recuperado (visible solo si _read() fue exitoso).
                if (_readResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Valor recuperado:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _readResult!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Indicador de carga ────────────────────────────────────────────
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
