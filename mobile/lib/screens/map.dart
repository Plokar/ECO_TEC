import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';
import 'capture.dart';

/// The Eco Map — the board the game is played on. Litter other players have
/// tagged, recycling points, cleanups, and friends who chose to be visible.
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
  Timer? _beacon;

  @override
  void initState() {
    super.initState();
    _locate();
    // Refresh the shared position while the map is open. Only while it is open:
    // a background location service is a battery and a privacy cost this app
    // has no need for.
    //
    // ponytail: 2-minute polling. Swap for a positionStream subscription if the
    // dots ever feel laggy.
    _beacon = Timer.periodic(const Duration(minutes: 2), (_) => _publish());
  }

  @override
  void dispose() {
    _beacon?.cancel();
    super.dispose();
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
    if (_me != null) {
      _controller.move(_me!, 15);
      _publish();
    }
  }

  /// Publishes where we are, but only if the player opted in. The service
  /// re-checks the same flag, so this can never leak by mistake.
  void _publish() {
    final me = _me;
    if (me == null || !widget.profile.shareLocation) return;
    data.shareLocation(widget.profile, me.latitude, me.longitude).ignore();
  }

  Future<void> _spotLitter() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CaptureScreen(profile: widget.profile, mode: CaptureMode.spot),
      ),
    );
  }

  Future<void> _openPin(MapPin pin) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PinSheet(
      pin: pin,
      profile: widget.profile,
      onClear: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaptureScreen(
              profile: widget.profile,
              clearing: pin,
            ),
          ),
        );
      },
    ),
  );

  Future<void> _addRecyclingPoint() async {
    final at = _me;
    if (at == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need your location to drop a pin.')),
      );
      return;
    }
    await data.reportPin(
      MapPin(
        id: '',
        kind: PinKind.recyclingPoint,
        lat: at.latitude,
        lng: at.longitude,
        title: 'Recycling point',
        authorName: widget.profile.displayName,
      ),
      widget.profile.uid,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recycling point added. +thanks.')),
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
            builder: (context, pinSnap) {
              final pins = pinSnap.data ?? const <MapPin>[];
              return StreamBuilder<List<Presence>>(
                stream: data.friendsOnMap(widget.profile),
                builder: (context, friendSnap) {
                  final friends = friendSnap.data ?? const <Presence>[];
                  return FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: centre,
                      initialZoom: _me == null ? 11 : 15,
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
                              width: 46,
                              height: 46,
                              child: _PinMarker(
                                pin: pin,
                                onTap: () => _openPin(pin),
                              ),
                            ),
                          for (final friend in friends)
                            Marker(
                              point: LatLng(friend.lat, friend.lng),
                              width: 54,
                              height: 62,
                              child: _FriendMarker(friend: friend),
                            ),
                          if (_me case final me?)
                            Marker(
                              point: me,
                              width: 26,
                              height: 26,
                              child: const _MeMarker(),
                            ),
                        ],
                      ),
                    ],
                  );
                },
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
              color: Tokens.page.withValues(alpha: 0.85),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '© OpenStreetMap contributors',
                style: ui(size: 10, color: Tokens.ink),
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
                      decoration: Tokens.card(),
                      child: Row(
                        children: [
                          const Flower(size: 20),
                          const SizedBox(width: Tokens.s8),
                          Expanded(
                            child: Text(
                              _locating
                                  ? 'Finding you…'
                                  : _me == null
                                  ? 'Location off — showing Amsterdam'
                                  : 'Litter near you',
                              style: ui(size: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!widget.profile.shareLocation)
                            const Tooltip(
                              message: 'You are hidden from friends',
                              child: Icon(
                                Icons.visibility_off_outlined,
                                size: 18,
                                color: Tokens.inkDim,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Tokens.s8),
                  _MapAction(
                    icon: Icons.my_location,
                    color: Tokens.paper,
                    tooltip: 'Find me',
                    onTap: _locate,
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
                  icon: Icons.add_a_photo_outlined,
                  color: Tokens.streakFire,
                  tooltip: 'Spot litter for others',
                  onTap: _spotLitter,
                ),
                const SizedBox(height: Tokens.s12),
                _MapAction(
                  icon: Icons.recycling,
                  color: Tokens.questGreen,
                  tooltip: 'Add a recycling point',
                  onTap: _addRecyclingPoint,
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
    child: Semantics(
      button: true,
      label: tooltip,
      child: Press(
        onTap: onTap,
        radius: Tokens.rPill,
        child: Container(
          height: 52,
          width: 52,
          alignment: Alignment.center,
          decoration: Tokens.card(
            fill: color,
            radius: Tokens.rPill,
            offset: 3,
          ),
          child: Icon(icon, color: Tokens.onFill(color), size: 24),
        ),
      ),
    ),
  );
}

/// A pin on the board. Litter leads carry their rarity colour and a tail, so a
/// legendary find is visible from across the map.
class _PinMarker extends StatelessWidget {
  const _PinMarker({required this.pin, required this.onTap});

  final MapPin pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (pin.kind) {
      PinKind.litterHotspot => (
        Icons.delete_outline,
        Tokens.rarity(pin.rarity.name),
      ),
      PinKind.recyclingPoint => (Icons.recycling, Tokens.questGreen),
      PinKind.cleanupEvent => (Icons.groups_outlined, Tokens.duelViolet),
      PinKind.completedQuest => (Icons.check, Tokens.sky),
    };
    final fill = pin.resolved ? Tokens.pageSubtle : color;
    return Semantics(
      button: true,
      label: pin.title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: Tokens.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: Tokens.ink, offset: Offset(2, 2), blurRadius: 0),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: pin.resolved ? Tokens.inkDim : Tokens.onFill(fill),
          ),
        ),
      ),
    );
  }
}

/// A friend, live. Their avatar with a name tag under it — a dot on a map tells
/// you nothing about who you are looking at.
class _FriendMarker extends StatelessWidget {
  const _FriendMarker({required this.friend});

  final Presence friend;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      PlayerAvatar(avatar: friend.avatar, size: 40, ring: Tokens.duelViolet),
      Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: Tokens.chip(Tokens.paper),
        child: Text(
          friend.displayName.split(' ').first,
          style: ui(size: 9, weight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _MeMarker extends StatelessWidget {
  const _MeMarker();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Tokens.impactCyan,
      shape: BoxShape.circle,
      border: Border.all(color: Tokens.ink, width: 3),
    ),
  );
}

/// What a tagged spot actually is: a photo, what was found, who found it, and
/// the one button that matters — go and clear it.
class _PinSheet extends StatelessWidget {
  const _PinSheet({
    required this.pin,
    required this.profile,
    required this.onClear,
  });

  final MapPin pin;
  final UserProfile profile;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Tokens.s24),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pin.photoUrl case final url?) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.rCard),
              child: Image.network(
                url,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  color: Tokens.pageSubtle,
                  alignment: Alignment.center,
                  child: Text(
                    'Photo unavailable',
                    style: ui(size: 13, color: Tokens.inkDim),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Tokens.s16),
          ],
          Row(
            children: [
              Expanded(child: Text(pin.title, style: display(size: 22))),
              if (pin.kind == PinKind.litterHotspot) RarityBadge(pin.rarity),
            ],
          ),
          const SizedBox(height: Tokens.s8),
          Text(
            [
              if (pin.className case final c?) c.replaceAll('_', ' '),
              if (pin.authorName case final name?)
                pin.uid == profile.uid ? 'spotted by you' : 'spotted by $name',
              if (pin.createdAt case final at?) DateFormat.MMMd().add_Hm().format(at),
            ].join(' · '),
            style: ui(size: 13, color: Tokens.inkDim),
          ),
          const SizedBox(height: Tokens.s24),
          if (pin.resolved)
            Sticker(
              fill: Tokens.pageSubtle,
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Tokens.questGreenDeep),
                  const SizedBox(width: Tokens.s8),
                  Expanded(
                    child: Text(
                      'Already cleared. Nice work, whoever you were.',
                      style: ui(size: 14),
                    ),
                  ),
                ],
              ),
            )
          else if (pin.isLead)
            FilledButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.cleaning_services, size: 20),
              label: Text(
                pin.rarity == Rarity.common
                    ? 'Clear this spot'
                    : 'Clear it · ${pin.rarity.title} bonus',
              ),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Close'),
            ),
        ],
      ),
    ),
  );
}
