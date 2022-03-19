
import 'dart:async';

import 'package:flutter/services.dart';

class FbDropDown {
  static const MethodChannel _channel = MethodChannel('fb_drop_down');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
