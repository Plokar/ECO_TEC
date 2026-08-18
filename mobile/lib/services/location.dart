import 'package:geolocator/geolocator.dart';

/// GPS, treated as optional everywhere.
///
/// A quest must still be completable with location denied — the photo and the
/// detector are the proof, and location only strengthens it. Nothing here throws
/// on refusal; it returns null and the caller carries on.
class LocationService {
  /// Current position, or null if permission or hardware isn't available.
  Future<Position?> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      // Timed out or no fix — fall back to whatever was last known.
      return Geolocator.getLastKnownPosition();
    }
  }
}
