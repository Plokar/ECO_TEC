import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';

/// The Eco Map — litter hotspots, recycling points and cleanups.
///
/// OpenStreetMap tiles rather than Google Maps: no API key, no billing account,
/// and no per-map-load cost as the user base grows.
class MapScreen extends StatefulWidget {
  const MapScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = MapController();

  /// Amsterdam — EcoTech HQ. Only used until we have a GPS fix.
  static const _fallback = LatLng(52.3676, 4.9041);

  LatLng? _me;
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    final position = await location.current();
    if (!mounted) return;
    setState(() {
      _me = position == null
          ? null
          : LatLng(position.latitude, position.longitude);
      _locating = false;
    });
    if (_me != null) _controller.move(_me!, 14);
  }

  Future<void> _report(PinKind kind, String title) async {
    final at = _me;
    if (at == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need your location to drop a pin.')),
      );
      return;
    }
    await data.reportPin(
      MapPin(id: '', kind: kind, lat: at.latitude, lng: at.longitude, title: title),
      widget.profile.uid,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reported: $title')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final centre = _me ?? _fallback;
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<MapPin>>(
            stream: data.pinsNear(centre.latitude, centre.longitude),
            builder: (context, snap) {
              final pins = snap.data ?? const <MapPin>[];
              return FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: centre,
                  initialZoom: _me == null ? 11 : 14,
                  minZoom: 3,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // OSM's tile policy requires an identifiable UA.
                    userAgentPackageName: 'com.ecotech.ecoquest',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      for (final pin in pins)
                        Marker(
                          point: LatLng(pin.lat, pin.lng),
                          width: 36,
                          height: 36,
                          child: _PinMarker(pin: pin),
                        ),
                      if (_me case final me?)
                        Marker(
                          point: me,
                          width: 22,
                          height: 22,
                          child: const _MeMarker(),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),

          // OSM attribution is a licence condition, not decoration — so it sits
          // clear of the docked shutter button, which protrudes ~48dp up into
          // the body around the horizontal centre and clipped the last word.
          Positioned(
            bottom: 52,
            left: 0,
            child: Container(
              color: Colors.black45,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '© OpenStreetMap contributors',
                style: ui(size: 10, color: Tokens.bone),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Tokens.s12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Tokens.s16,
                        vertical: Tokens.s12,
                      ),
                      decoration: BoxDecoration(
                        color: Tokens.forestSurface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(Tokens.rCard),
                        border: Border.all(color: Tokens.forestLine),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 18,
                            color: Tokens.impactCyan,
                          ),
                          const SizedBox(width: Tokens.s8),
                          Expanded(
                            child: Text(
                              _locating
                                  ? 'Finding you…'
                                  : _me == null
                                      ? 'Location off — showing Amsterdam'
                                      : 'Litter near you',
                              style: ui(size: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Tokens.s8),
                  IconButton.filled(
                    onPressed: _locate,
                    icon: const Icon(Icons.my_location),
                    style: IconButton.styleFrom(
                      backgroundColor: Tokens.forestSurface,
                      foregroundColor: Tokens.questGreen,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: Tokens.s12,
            bottom: 140,
            child: Column(
              children: [
                _MapAction(
                  icon: Icons.delete_outline,
                  color: Tokens.streakFire,
                  tooltip: 'Report litter here',
                  onTap: () => _report(PinKind.litterHotspot, 'Litter reported'),
                ),
                const SizedBox(height: Tokens.s8),
                _MapAction(
                  icon: Icons.recycling,
                  color: Tokens.questGreen,
                  tooltip: 'Add a recycling point',
                  onTap: () => _report(PinKind.recyclingPoint, 'Recycling point'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapAction extends StatelessWidget {
  const _MapAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton.filled(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Tokens.forestSurface,
        foregroundColor: color,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: Tokens.forestLine),
      ),
    ),
  );
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({required this.pin});

  final MapPin pin;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (pin.kind) {
      PinKind.litterHotspot => (Icons.delete_outline, Tokens.streakFire),
      PinKind.recyclingPoint => (Icons.recycling, Tokens.questGreen),
      PinKind.cleanupEvent => (Icons.groups_outlined, Tokens.duelViolet),
      PinKind.completedQuest => (Icons.check, Tokens.impactCyan),
    };
    return Tooltip(
      message: pin.title,
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.deepForest,
          shape: BoxShape.circle,
          border: Border.all(
            color: pin.resolved ? Tokens.forestLine : color,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: pin.resolved ? Tokens.boneDim : color,
        ),
      ),
    );
  }
}

class _MeMarker extends StatelessWidget {
  const _MeMarker();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Tokens.impactCyan,
      shape: BoxShape.circle,
      border: Border.all(color: Tokens.bone, width: 3),
    ),
  );
}
