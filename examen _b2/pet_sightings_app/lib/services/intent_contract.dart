/// Claves y acciones del contrato de Intents entre las 4 apps del flujo
/// "Mascota Perdida". Ver CONTRATO_INTENTS.md en la raíz del proyecto para
/// la especificación completa compartida con el equipo.
class IntentContract {
  IntentContract._();

  // Paso 1 -> 2: App 1 (Reportar mascota perdida) -> App 2 (Avistamientos)
  static const actionLostPetReported = 'com.examenb2.petflow.action.LOST_PET_REPORTED';

  static const extraPetId = 'pet_id';
  static const extraPetName = 'pet_name';
  static const extraPetType = 'pet_type';
  static const extraDescription = 'description';
  static const extraLastSeenLat = 'last_seen_lat';
  static const extraLastSeenLng = 'last_seen_lng';
  static const extraContactPhone = 'contact_phone';
  static const extraReportedAt = 'reported_at';

  // Paso 2 -> 3: App 2 (Avistamientos) -> App 3 (Refugios, KMP)
  static const actionSightingFollowup = 'com.examenb2.petflow.action.SIGHTING_FOLLOWUP';

  static const extraSightingLat = 'sighting_lat';
  static const extraSightingLng = 'sighting_lng';
  static const extraSightingDescription = 'sighting_description';
  static const extraSightingAt = 'sighting_at';

  static const categoryDefault = 'android.intent.category.DEFAULT';
}
