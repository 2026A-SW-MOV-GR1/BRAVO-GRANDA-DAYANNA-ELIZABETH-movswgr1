import 'pet_sighting.dart';
import '../services/intent_contract.dart';

/// Caso de mascota perdida recibido desde App 1 vía Intent. Ver
/// CONTRATO_INTENTS.md (sección Paso 1 -> 2) para el detalle de cada campo.
class LostPetCase {
  final String petId;
  final String petName;
  final PetType petType;
  final String description;
  final double lastSeenLat;
  final double lastSeenLng;
  final String contactPhone;
  final DateTime reportedAt;

  const LostPetCase({
    required this.petId,
    required this.petName,
    required this.petType,
    required this.description,
    required this.lastSeenLat,
    required this.lastSeenLng,
    required this.contactPhone,
    required this.reportedAt,
  });

  /// Construye el caso a partir de los extras crudos del Intent (tal como
  /// llegan desde la capa nativa: un `Map<String, dynamic>` con valores
  /// String/double). Devuelve null si faltan campos obligatorios.
  static LostPetCase? fromIntentExtras(Map<Object?, Object?>? extras) {
    if (extras == null) return null;
    final petId = extras[IntentContract.extraPetId] as String?;
    final petName = extras[IntentContract.extraPetName] as String?;
    final petTypeRaw = extras[IntentContract.extraPetType] as String?;
    final description = extras[IntentContract.extraDescription] as String?;
    final lastSeenLat = (extras[IntentContract.extraLastSeenLat] as num?)?.toDouble();
    final lastSeenLng = (extras[IntentContract.extraLastSeenLng] as num?)?.toDouble();
    final contactPhone = extras[IntentContract.extraContactPhone] as String?;
    final reportedAtRaw = extras[IntentContract.extraReportedAt] as String?;

    if (petId == null ||
        petName == null ||
        description == null ||
        lastSeenLat == null ||
        lastSeenLng == null ||
        contactPhone == null) {
      return null;
    }

    return LostPetCase(
      petId: petId,
      petName: petName,
      petType: PetType.values.firstWhere(
        (e) => e.name == petTypeRaw,
        orElse: () => PetType.otro,
      ),
      description: description,
      lastSeenLat: lastSeenLat,
      lastSeenLng: lastSeenLng,
      contactPhone: contactPhone,
      reportedAt: DateTime.tryParse(reportedAtRaw ?? '') ?? DateTime.now(),
    );
  }
}
