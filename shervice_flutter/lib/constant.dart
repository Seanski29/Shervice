import 'package:flutter/foundation.dart';

// 1. CHANGE THIS to your PC's actual Wi-Fi IP address
const String localIp = '10.129.21.10';

String get backendUrl {
  // 2. Web Check FIRST
  if (kIsWeb) {
    return 'http://$localIp:5000/api';
  }

  // 3. Mobile Check (Web-safe way, no dart:io needed!)
  if (defaultTargetPlatform == TargetPlatform.android || 
      defaultTargetPlatform == TargetPlatform.iOS) {
    // If you are using a PHYSICAL phone, this works perfectly.
    // (Note: If using an Android Emulator, you might need to change this to 'http://10.0.2.2:5000/api')
    return 'http://$localIp:5000/api';
  }

  // Fallback for Windows/macOS desktop apps running locally
  return 'http://127.0.0.1:5000/api';
}