import 'package:flutter/foundation.dart';

class EnvironmentUtil {
  /// Returns true if the application is running in local development mode
  /// (e.g. localhost, 127.0.0.1, or debug mode).
  static bool get isLocalhost {
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      return host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '0.0.0.0' ||
          host.isEmpty ||
          kDebugMode;
    }
    return kDebugMode;
  }
}
