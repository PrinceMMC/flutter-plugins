import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kReleaseMode) {
      // 可以在这里添加更多调试信息（如时间戳、调用栈等）
      debugPrint(message);
    }
  }
}
