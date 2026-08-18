import 'ml/detector.dart';
import 'services/auth.dart';
import 'services/data.dart';
import 'services/location.dart';

/// App-wide singletons.
///
/// Plain globals rather than a DI container: there is exactly one of each, and
/// every service takes its Firebase dependencies through its constructor, so
/// tests can still build their own with fakes.
final auth = AuthService();
final data = DataService();
final location = LocationService();

Future<Detector>? _detector;

/// The TFLite model is ~6 MB and takes a moment to load, so it loads on first
/// use and stays loaded. Callers await this every time; only the first one waits.
Future<Detector> detector() => _detector ??= Detector.load();
