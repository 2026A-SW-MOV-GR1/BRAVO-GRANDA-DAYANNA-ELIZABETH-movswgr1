import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/lost_pet_case.dart';
import 'intent_contract.dart';

/// Puente hacia el contrato de Intents del flujo "Mascota Perdida" (ver
/// CONTRATO_INTENTS.md). Solo tiene efecto en Android; en el resto de
/// plataformas (web, usado para pruebas/demo) se degrada de forma segura.
class IntentService {
  static const _methodChannel = MethodChannel('com.examenb2.petflow/intent');
  static const _eventChannel = EventChannel('com.examenb2.petflow/intent_stream');

  // dart:io no está disponible al compilar para web; defaultTargetPlatform
  // sí funciona en todas las plataformas.
  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Caso recibido al arrancar la app (App 1 -> App 2), si la app fue
  /// lanzada mediante el Intent del contrato. Null si se abrió normalmente.
  Future<LostPetCase?> getInitialCase() async {
    if (!_isAndroid) return null;
    try {
      final extras = await _methodChannel.invokeMapMethod<String, dynamic>('getInitialExtras');
      return LostPetCase.fromIntentExtras(extras);
    } on MissingPluginException {
      return null;
    }
  }

  /// Casos que lleguen mientras la app ya está abierta (Android reutiliza la
  /// Activity por `launchMode="singleTop"` y dispara `onNewIntent`).
  Stream<LostPetCase> onNewCase() {
    if (!_isAndroid) return const Stream.empty();
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => LostPetCase.fromIntentExtras(event as Map<Object?, Object?>?))
        .where((c) => c != null)
        .cast<LostPetCase>();
  }

  /// Envía el Intent del Paso 2 -> 3 hacia App 3 (Refugios). Devuelve false
  /// si no hay ninguna app instalada que declare ese `<intent-filter>`.
  Future<bool> sendSightingFollowup({
    required String petId,
    required String petName,
    required String petType,
    required double sightingLat,
    required double sightingLng,
    required String sightingDescription,
    required DateTime sightingAt,
    required String contactPhone,
  }) async {
    if (!_isAndroid) return false;

    final intent = AndroidIntent(
      action: IntentContract.actionSightingFollowup,
      category: IntentContract.categoryDefault,
      arguments: {
        IntentContract.extraPetId: petId,
        IntentContract.extraPetName: petName,
        IntentContract.extraPetType: petType,
        IntentContract.extraSightingLat: sightingLat,
        IntentContract.extraSightingLng: sightingLng,
        IntentContract.extraSightingDescription: sightingDescription,
        IntentContract.extraSightingAt: sightingAt.toIso8601String(),
        IntentContract.extraContactPhone: contactPhone,
      },
    );

    final canResolve = await intent.canResolveActivity() ?? false;
    if (!canResolve) return false;

    await intent.launch();
    return true;
  }
}
