import 'dart:io';
import 'package:flutter/foundation.dart';

String get backendUrl {
  if (kIsWeb) return 'http://127.0.0.1:5000/api';

  if (Platform.isAndroid) {
    return 'http://HOTSPOT:5000/api';
  }
  // Fallback for iOS Simulator or desktop
  return 'http://127.0.0.1:5000/api';
}