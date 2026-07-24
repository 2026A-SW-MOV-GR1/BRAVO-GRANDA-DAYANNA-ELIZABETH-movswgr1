import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/sighting_provider.dart';
import 'screens/map_screen.dart';
import 'services/sighting_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = SightingRepository();
  await repository.init();

  final provider = SightingProvider(repository);
  await provider.load();

  runApp(PetSightingsApp(provider: provider));
}

class PetSightingsApp extends StatelessWidget {
  final SightingProvider provider;

  const PetSightingsApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        title: 'Mascotas Perdidas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
          useMaterial3: true,
        ),
        home: const MapScreen(),
      ),
    );
  }
}
