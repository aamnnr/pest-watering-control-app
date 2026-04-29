import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
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
    // Logger 2.7.0 uses named parameters for error and stackTrace
    if (error != null && stackTrace != null) {
      logger.e(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      logger.e(message, error: error);
    } else {
      logger.e(message);
    }
  }

  static void trace(String message) {
    logger.t(message);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null && stackTrace != null) {
      logger.f(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      logger.f(message, error: error);
    } else {
      logger.f(message);
    }
  }
}
