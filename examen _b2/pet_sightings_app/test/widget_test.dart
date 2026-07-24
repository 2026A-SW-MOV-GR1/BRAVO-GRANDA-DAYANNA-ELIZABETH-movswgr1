// Pruebas de la lógica del módulo (modelo, repositorio y formulario).
//
// El mapa interactivo (FlutterMap) y la geolocalización dependen de red y de
// canales de plataforma reales, así que se validan manualmente con
// `flutter run` en lugar de en `flutter test` (que corre en un VM headless
// sin esos servicios). Aquí se cubre la lógica de negocio pura del módulo:
// serialización del modelo, alta/baja/filtrado de avistamientos y el
// formulario de reporte.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:pet_sightings_app/models/pet_sighting.dart';
import 'package:pet_sightings_app/providers/sighting_provider.dart';
import 'package:pet_sightings_app/screens/report_form_screen.dart';
import 'package:pet_sightings_app/services/sighting_repository.dart';

int _testBoxCounter = 0;

Future<SightingProvider> _newProvider() async {
  final tempDir = await Directory.systemTemp.createTemp('pet_sightings_test');
  final repository = SightingRepository(boxName: 'test_box_${_testBoxCounter++}');
  await repository.init(testPath: tempDir.path);
  final provider = SightingProvider(repository);
  await provider.load();
  return provider;
}

void main() {
  test('PetSighting sobrevive un ciclo toJson/fromJson', () {
    final original = PetSighting(
      id: 'abc-123',
      petName: 'Firulais',
      petType: PetType.perro,
      description: 'Labrador color café, con collar rojo',
      contactPhone: '0999999999',
      latitude: -0.1807,
      longitude: -78.4678,
      sightedAt: DateTime(2026, 7, 20, 15, 30),
      status: SightingStatus.visto,
    );

    final restored = PetSighting.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.petName, original.petName);
    expect(restored.petType, original.petType);
    expect(restored.latitude, original.latitude);
    expect(restored.longitude, original.longitude);
    expect(restored.sightedAt, original.sightedAt);
    expect(restored.status, original.status);
  });

  test('SightingProvider guarda, filtra y elimina avistamientos', () async {
    final provider = await _newProvider();

    await provider.addSighting(
      petName: 'Michi',
      petType: PetType.gato,
      description: 'Gato blanco y negro, muy asustadizo',
      contactPhone: '0988888888',
      latitude: -0.18,
      longitude: -78.46,
      sightedAt: DateTime.now(),
    );
    await provider.addSighting(
      petName: 'Rex',
      petType: PetType.perro,
      description: 'Pastor alemán, sin collar',
      contactPhone: '0977777777',
      latitude: -0.19,
      longitude: -78.47,
      sightedAt: DateTime.now(),
    );

    expect(provider.all.length, 2);

    provider.setTypeFilter(PetType.gato);
    expect(provider.filtered.length, 1);
    expect(provider.filtered.first.petName, 'Michi');

    provider.setTypeFilter(null);
    final rex = provider.all.firstWhere((s) => s.petName == 'Rex');
    await provider.toggleStatus(rex);
    final updatedRex = provider.all.firstWhere((s) => s.petName == 'Rex');
    expect(updatedRex.status, SightingStatus.encontrado);

    await provider.deleteSighting(updatedRex.id);
    expect(provider.all.length, 1);
  });

  testWidgets('El formulario de reporte guarda un nuevo avistamiento',
      (WidgetTester tester) async {
    // testWidgets ejecuta el cuerpo en una zona de "fake async" que no
    // impulsa E/S real (archivos de Hive); tester.runAsync() sale de esa
    // zona para permitir que la E/S real se complete.
    late SightingProvider provider;
    await tester.runAsync(() async {
      provider = await _newProvider();
    });

    // Viewport alto para que todo el formulario quepa sin necesidad de
    // scroll (evita ambigüedad entre el Scrollable del ListView y los
    // Scrollables internos de cada TextField).
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Se abre mediante push (no como "home") para que exista una ruta previa
    // a la que volver: así Navigator.pop() dentro del formulario funciona
    // igual que en la app real (MapScreen -> push -> ReportFormScreen).
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportFormScreen(location: LatLng(-0.18, -78.46)),
                    ),
                  ),
                  child: const Text('abrir formulario'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir formulario'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre de la mascota (o "Desconocido")'), 'Toby');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción (color, tamaño, collar, comportamiento...)'),
      'Perro pequeño color negro',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Teléfono de contacto'), '0991234567');

    final saveButtonFinder = find.widgetWithText(FilledButton, 'Guardar reporte');
    // El guardado dispara E/S real de Hive; se ejecuta en runAsync por la
    // misma razón que la inicialización del repositorio.
    await tester.runAsync(() async {
      await tester.tap(saveButtonFinder);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(provider.all.length, 1);
    expect(provider.all.first.petName, 'Toby');
  });
}
