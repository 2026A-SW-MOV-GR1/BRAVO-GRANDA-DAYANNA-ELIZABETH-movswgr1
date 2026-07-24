import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Punto por defecto del mapa cuando no hay ubicación disponible (Quito, Ecuador).
const LatLng defaultCenter = LatLng(-0.1807, -78.4678);

class LocationService {
  static const _channelTimeout = Duration(seconds: 8);

  /// Nunca deja pendiente una llamada de plataforma: si el canal de
  /// geolocalización no responde (p. ej. en entornos sin GPS/plataforma
  /// real como los tests), la operación se resuelve como "no disponible"
  /// en vez de bloquear la app indefinidamente.
  Future<LatLng?> getCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled().timeout(_channelTimeout);
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission().timeout(_channelTimeout);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(_channelTimeout);
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(_channelTimeout);
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }
}
