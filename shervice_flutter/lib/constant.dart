import 'package:flutter/foundation.dart'; // dart:io is removed!

// 1. CHANGE THIS to your PC's actual Wi-Fi IP address
const String localIp = '192.168.1.11';

String get backendUrl {
  // 2. Web check
  if (kIsWeb) {
    return 'http://$localIp:5000/api';
  }

  // 3. Web-safe mobile check
  if (defaultTargetPlatform == TargetPlatform.android || 
      defaultTargetPlatform == TargetPlatform.iOS) {
    return 'http://$localIp:5000/api';
  }

  // 4. Fixed syntax on the fallback
  return 'http://127.0.0.1:5000/api';
}