import 'package:flutter/material.dart';

import '../models/pet_sighting.dart';

IconData iconForPetType(PetType type) {
  switch (type) {
    case PetType.perro:
      return Icons.pets;
    case PetType.gato:
      return Icons.cruelty_free;
    case PetType.otro:
      return Icons.emoji_nature;
  }
}

Color colorForStatus(SightingStatus status) {
  return status == SightingStatus.encontrado
      ? const Color(0xFF2E7D32)
      : const Color(0xFFE65100);
}

/// Marcador personalizado: forma de gota con el ícono de la mascota,
/// coloreado según el estado del avistamiento (visto / encontrado).
class PetMarker extends StatelessWidget {
  final PetSighting sighting;
  final VoidCallback onTap;

  const PetMarker({super.key, required this.sighting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = colorForStatus(sighting.status);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(iconForPetType(sighting.petType), color: Colors.white, size: 18),
          ),
          CustomPaint(size: const Size(10, 6), painter: _TrianglePainter(color)),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}

/// Marcador temporal para el punto que el usuario está eligiendo en el mapa.
class PendingMarker extends StatelessWidget {
  const PendingMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.location_on, color: Colors.blueAccent, size: 42);
  }
}
