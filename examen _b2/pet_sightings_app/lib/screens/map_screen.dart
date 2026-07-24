import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/lost_pet_case.dart';
import '../models/pet_sighting.dart';
import '../providers/sighting_provider.dart';
import '../services/intent_service.dart';
import '../services/location_service.dart';
import '../widgets/custom_marker.dart';
import '../widgets/sighting_detail_sheet.dart';
import 'report_form_screen.dart';
import 'sighting_list_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final IntentService _intentService = IntentService();
  StreamSubscription<LostPetCase>? _newCaseSubscription;

  bool _pickingLocation = false;
  LatLng? _pendingPoint;
  LatLng _center = defaultCenter;

  @override
  void initState() {
    super.initState();

    // Si App 1 ya envió un caso al arrancar (ver main.dart), centrar el
    // mapa ahí en vez de en la ubicación del usuario.
    final activeCase = context.read<SightingProvider>().activeCase;
    if (activeCase != null) {
      _center = LatLng(activeCase.lastSeenLat, activeCase.lastSeenLng);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnMyLocation(silent: true));
    }

    // Casos que lleguen mientras la app ya está abierta (onNewIntent, ver
    // CONTRATO_INTENTS.md).
    _newCaseSubscription = _intentService.onNewCase().listen(_onNewCaseReceived);
  }

  @override
  void dispose() {
    _newCaseSubscription?.cancel();
    super.dispose();
  }

  void _onNewCaseReceived(LostPetCase newCase) {
    context.read<SightingProvider>().setActiveCase(newCase);
    final point = LatLng(newCase.lastSeenLat, newCase.lastSeenLng);
    setState(() => _center = point);
    _mapController.move(point, 15);
  }

  Future<void> _centerOnMyLocation({bool silent = false}) async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _center = position;
      _mapController.move(position, 15);
    } else if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener tu ubicación. Verifica los permisos.')),
      );
    }
  }

  void _startPickingLocation() {
    setState(() {
      _pickingLocation = true;
      _pendingPoint = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toca el mapa en el punto donde viste a la mascota'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _cancelPicking() {
    setState(() {
      _pickingLocation = false;
      _pendingPoint = null;
    });
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    if (!_pickingLocation) return;
    setState(() => _pendingPoint = point);
  }

  Future<void> _confirmLocation() async {
    if (_pendingPoint == null) return;
    final point = _pendingPoint!;
    final activeCase = context.read<SightingProvider>().activeCase;
    setState(() {
      _pickingLocation = false;
      _pendingPoint = null;
    });
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(location: point, activeCase: activeCase),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SightingProvider>();
    final sightings = provider.filtered;

    final markers = <Marker>[
      for (final s in sightings)
        Marker(
          point: LatLng(s.latitude, s.longitude),
          width: 44,
          height: 52,
          alignment: Alignment.topCenter,
          child: PetMarker(sighting: s, onTap: () => showSightingDetailSheet(context, s)),
        ),
      if (_pendingPoint != null)
        Marker(
          point: _pendingPoint!,
          width: 42,
          height: 42,
          alignment: Alignment.topCenter,
          child: const PendingMarker(),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mascotas Perdidas · Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Ver lista de avistamientos',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SightingListScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.examen.b2.pet_sightings_app',
                maxZoom: 19,
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.activeCase != null) ...[
                  _buildActiveCaseBanner(context, provider.activeCase!),
                  const SizedBox(height: 8),
                ],
                _buildFilterRow(context, provider),
                if (_pickingLocation) ...[
                  const SizedBox(height: 8),
                  _buildPickingBanner(context),
                ],
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton.small(
              heroTag: 'locate-me',
              onPressed: () => _centerOnMyLocation(),
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      floatingActionButton: _pickingLocation
          ? FloatingActionButton.extended(
              onPressed: _pendingPoint == null ? null : _confirmLocation,
              icon: const Icon(Icons.check),
              label: const Text('Usar esta ubicación'),
            )
          : FloatingActionButton.extended(
              onPressed: _startPickingLocation,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Reportar avistamiento'),
            ),
    );
  }

  Widget _buildActiveCaseBanner(BuildContext context, LostPetCase activeCase) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.pets),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Buscando a: ${activeCase.petName} · reportado por App 1',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cerrar caso',
              onPressed: () => context.read<SightingProvider>().clearActiveCase(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickingBanner(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.touch_app),
            const SizedBox(width: 8),
            const Expanded(child: Text('Toca el mapa para elegir la ubicación')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelPicking,
              tooltip: 'Cancelar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, SightingProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'Todos',
            selected: provider.typeFilter == null,
            onTap: () => provider.setTypeFilter(null),
          ),
          for (final type in PetType.values)
            _filterChip(
              label: type.label,
              selected: provider.typeFilter == type,
              onTap: () => provider.setTypeFilter(type),
            ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Solo vistos',
            selected: provider.statusFilter == SightingStatus.visto,
            onTap: () => provider.setStatusFilter(
              provider.statusFilter == SightingStatus.visto ? null : SightingStatus.visto,
            ),
            color: const Color(0xFFE65100),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color ?? Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : null),
        backgroundColor: Colors.white,
      ),
    );
  }
}
