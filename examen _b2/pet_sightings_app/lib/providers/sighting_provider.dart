import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/pet_sighting.dart';
import '../services/sighting_repository.dart';

class SightingProvider extends ChangeNotifier {
  final SightingRepository _repository;
  final _uuid = const Uuid();

  List<PetSighting> _sightings = [];
  PetType? _typeFilter;
  SightingStatus? _statusFilter;

  SightingProvider(this._repository);

  List<PetSighting> get all => _sightings;

  PetType? get typeFilter => _typeFilter;
  SightingStatus? get statusFilter => _statusFilter;

  List<PetSighting> get filtered => _sightings.where((s) {
        final typeOk = _typeFilter == null || s.petType == _typeFilter;
        final statusOk = _statusFilter == null || s.status == _statusFilter;
        return typeOk && statusOk;
      }).toList();

  Future<void> load() async {
    _sightings = _repository.getAll();
    notifyListeners();
  }

  Future<void> addSighting({
    required String petName,
    required PetType petType,
    required String description,
    required String contactPhone,
    required double latitude,
    required double longitude,
    required DateTime sightedAt,
    String? photoPath,
  }) async {
    final sighting = PetSighting(
      id: _uuid.v4(),
      petName: petName,
      petType: petType,
      description: description,
      contactPhone: contactPhone,
      latitude: latitude,
      longitude: longitude,
      sightedAt: sightedAt,
      photoPath: photoPath,
    );
    await _repository.save(sighting);
    await load();
  }

  Future<void> toggleStatus(PetSighting sighting) async {
    final updated = sighting.copyWith(
      status: sighting.status == SightingStatus.visto
          ? SightingStatus.encontrado
          : SightingStatus.visto,
    );
    await _repository.save(updated);
    await load();
  }

  Future<void> deleteSighting(String id) async {
    await _repository.delete(id);
    await load();
  }

  void setTypeFilter(PetType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setStatusFilter(SightingStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }
}
