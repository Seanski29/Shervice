import 'dart:io';
import 'package:flutter/foundation.dart';

// 1. CHANGE THIS to your PC's actual Wi-Fi IP address
const String localIp = '10.129.21.10';

String get backendUrl {
  // 2. CHANGE THIS so the web browser generates the QR code correctly
  if (kIsWeb) return 'http://$localIp:5000/api';

  // For physical mobile devices on the same network, use the host machine IP.
  if (Platform.isAndroid || Platform.isIOS) {
    return 'http://$localIp:5000/api';
  }

  // Fallback for desktop or simulator running locally.
  return 'http://127.0.0.1:5000/api';
}
