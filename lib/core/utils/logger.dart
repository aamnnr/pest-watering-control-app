import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

class AppLogger {
  static void debug(String message) {
    logger.d(message);
  }
  
  static void info(String message) {
    logger.i(message);
  }
  
  static void warning(String message) {
    logger.w(message);
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // Beberapa versi logger menerima error dan stackTrace sebagai positional arguments
    if (error != null && stackTrace != null) {
      logger.e(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      logger.e(message, error: error);
    } else {
      logger.e(message);
    }
  }
  
  static void verbose(String message) {
    logger.v(message);
  }
  
  static void wtf(String message) {
    logger.wtf(message);
  }
}