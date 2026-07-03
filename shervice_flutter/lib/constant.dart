import 'dart:io';
import 'package:flutter/foundation.dart';

const String localIp = '192.168.1.1';

String get backendUrl {
  if (kIsWeb) return 'http://127.0.0.1:5000/api';

  // For physical mobile devices on the same network, use the host machine IP.
  // Update localIp to the actual IP address of the computer running the backend.
  if (Platform.isAndroid || Platform.isIOS) {
    return 'http://$localIp:5000/api';
  }

  // Fallback for desktop or simulator running locally.
  return 'http://127.0.0.1:5000/api';
}
