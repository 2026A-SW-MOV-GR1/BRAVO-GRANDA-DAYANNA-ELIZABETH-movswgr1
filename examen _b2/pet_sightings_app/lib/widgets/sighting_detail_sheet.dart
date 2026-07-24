import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pet_sighting.dart';
import '../providers/sighting_provider.dart';
import '../services/intent_service.dart';
import 'custom_marker.dart';

Future<void> showSightingDetailSheet(BuildContext context, PetSighting sighting) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SightingDetailSheet(sighting: sighting),
  );
}

class SightingDetailSheet extends StatelessWidget {
  final PetSighting sighting;

  const SightingDetailSheet({super.key, required this.sighting});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final color = colorForStatus(sighting.status);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (sighting.photoPath != null) _buildPhoto(),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(iconForPetType(sighting.petType), color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sighting.petName, style: Theme.of(context).textTheme.titleLarge),
                    Text('${sighting.petType.label} · ${sighting.status.label}',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(sighting.description),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.schedule, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(dateFmt.format(sighting.sightedAt)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.phone, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(sighting.contactPhone),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.place, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text('${sighting.latitude.toStringAsFixed(5)}, '
                '${sighting.longitude.toStringAsFixed(5)}'),
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<SightingProvider>().toggleStatus(sighting);
                    Navigator.of(context).pop();
                  },
                  icon: Icon(sighting.status == SightingStatus.visto
                      ? Icons.check_circle_outline
                      : Icons.undo),
                  label: Text(sighting.status == SightingStatus.visto
                      ? 'Marcar como encontrada'
                      : 'Reabrir aviso'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  context.read<SightingProvider>().deleteSighting(sighting.id);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Eliminar',
              ),
            ],
          ),
          if (sighting.caseId != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _sendToShelters(context),
                icon: const Icon(Icons.home_work_outlined),
                label: const Text('Buscar refugios cercanos'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Paso 2 -> 3 del flujo entre apps (ver CONTRATO_INTENTS.md): envía este
  // avistamiento, ya vinculado a un caso de App 1, hacia App 3 (Refugios).
  Future<void> _sendToShelters(BuildContext context) async {
    final sent = await IntentService().sendSightingFollowup(
      petId: sighting.caseId!,
      petName: sighting.petName,
      petType: sighting.petType.name,
      sightingLat: sighting.latitude,
      sightingLng: sighting.longitude,
      sightingDescription: sighting.description,
      sightingAt: sighting.sightedAt,
      contactPhone: sighting.contactPhone,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent
            ? 'Enviado a la app de Refugios'
            : 'No se encontró la app de Refugios instalada'),
      ),
    );
  }

  Widget _buildPhoto() {
    final path = sighting.photoPath!;
    Widget image;
    if (kIsWeb) {
      image = Image.network(path, height: 180, width: double.infinity, fit: BoxFit.cover);
    } else {
      image = Image.file(File(path), height: 180, width: double.infinity, fit: BoxFit.cover);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
    );
  }
}
