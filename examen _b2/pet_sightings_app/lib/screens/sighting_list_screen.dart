import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pet_sighting.dart';
import '../providers/sighting_provider.dart';
import '../widgets/custom_marker.dart';
import '../widgets/sighting_detail_sheet.dart';

class SightingListScreen extends StatelessWidget {
  const SightingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SightingProvider>();
    final sightings = provider.filtered;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Avistamientos reportados')),
      body: sightings.isEmpty
          ? const Center(child: Text('Aún no hay avistamientos reportados'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sightings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = sightings[index];
                final color = colorForStatus(s.status);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: Icon(iconForPetType(s.petType), color: Colors.white),
                    ),
                    title: Text(s.petName),
                    subtitle: Text('${s.petType.label} · ${dateFmt.format(s.sightedAt)}\n'
                        '${s.description}'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(s.status.label, style: const TextStyle(fontSize: 11)),
                      backgroundColor: color.withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: color),
                    ),
                    onTap: () => showSightingDetailSheet(context, s),
                  ),
                );
              },
            ),
    );
  }
}
