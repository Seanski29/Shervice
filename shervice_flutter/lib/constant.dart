// lib/constants.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

String get backendUrl {
  if (kIsWeb) return 'http://127.0.0.1:5000/api';

  // This logic automatically switches between your phone's IP and local/emulator
  return Platform.isAndroid
      ? 'http://192.168.1.13:5000/api'
      : 'http://127.0.0.1:5000/api';
}
