import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_state.dart';
import '../core/prayer_calc.dart';
import '../data/cities.dart';

double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

String nameForCoordinates(double lat, double lng) {
  City? best;
  var bestKm = double.infinity;
  for (final c in kCities) {
    final d = _distanceKm(lat, lng, c.lat, c.lng);
    if (d < bestKm) {
      bestKm = d;
      best = c;
    }
  }
  if (best != null && bestKm < 40) return 'Near ${best.name}';
  return '${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°';
}

void applyLocation(double lat, double lng, String name, {bool suggest = false}) {
  AppState.instance.update((s) {
    s.lat = lat;
    s.lng = lng;
    s.place = name;
    if (suggest) s.method = suggestMethod(lat, lng);
  }, times: true);
}

/// Returns null on success, or a message explaining what went wrong.
Future<String?> useDeviceLocation({bool suggest = false}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Location is turned off on this phone. Turn it on, or choose a city instead.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return 'Location permission was not given. You can choose a city instead.';
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is blocked for this app. Allow it in your phone’s settings, or choose a city instead.';
    }
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos == null) return 'Could not find your location. Try again outside, or choose a city.';
    applyLocation(pos.latitude, pos.longitude,
        nameForCoordinates(pos.latitude, pos.longitude),
        suggest: suggest);
    return null;
  } catch (e) {
    return 'Could not find your location ($e). Choose a city instead.';
  }
}

Future<City?> showCityPicker(BuildContext context) {
  return showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _CityPicker(),
  );
}

class _CityPicker extends StatefulWidget {
  const _CityPicker();

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = kCities
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.country.toLowerCase().contains(q))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search cities',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No city found. Use your location, or enter coordinates in Settings.',
                          textAlign: TextAlign.center),
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final c = results[i];
                      return ListTile(
                        title: Text(c.name),
                        subtitle: Text(c.country),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<(double, double)?> showCoordinateDialog(BuildContext context) {
  final s = AppState.instance.settings;
  final latCtrl = TextEditingController(text: s.lat?.toStringAsFixed(4) ?? '');
  final lngCtrl = TextEditingController(text: s.lng?.toStringAsFixed(4) ?? '');
  return showDialog<(double, double)>(
    context: context,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Enter coordinates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Latitude', hintText: 'For example 51.5074'),
              ),
              TextField(
                controller: lngCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Longitude', hintText: 'For example -0.1278'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final lat = double.tryParse(latCtrl.text.trim());
                final lng = double.tryParse(lngCtrl.text.trim());
                if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
                  setLocal(() => error = 'Latitude must be between -90 and 90, longitude between -180 and 180.');
                  return;
                }
                Navigator.pop(ctx, (lat, lng));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
}
