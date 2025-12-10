import 'package:logger/logger.dart';

YukaConsole yukaConsole = YukaConsole();
enum LoggerLevel{log,warning,error,silent}
LoggerLevel currentLevel = LoggerLevel.warning;

// ignore: camel_case_types
class YukaConsole {
  late Logger _logger;

  /// Gives access to internal logger
  Logger get rawLogger => _logger;

  /// Creates a instance of [FLILogger].
  /// In case [isVerbose] is `true`,
  /// it logs all the [verbose] logs to console
  YukaConsole() {
    _logger = Logger(
      printer: PrettyPrinter(
          methodCount: 2, // Number of method calls to be displayed
          errorMethodCount: 8, // Number of method calls if stacktrace is provided
          lineLength: 120, // Width of the output
          colors: true, // Colorful log messages
          printEmojis: true, // Print an emoji for each log message
          printTime: true // Should each log print contain a timestamp
      ),
      level: Level.all
    );
  }

    /// Logs error messages
  void error(Object? message){
    if(currentLevel.index <= LoggerLevel.error.index) _logger.e('Error Log', error: '⚠️ $message');
  }

  /// Prints to console if [isVerbose] is true
  void verbose(Object? message){
    if(currentLevel.index <= LoggerLevel.log.index){
      _logger.t(message.toString());
    }
  }
  /// Prints to console
  void warning(Object? message){
    if(currentLevel.index <= LoggerLevel.warning.index){
      _logger.w(message.toString());
    }
  }
  /// Prints to console if [isVerbose] is true
  void info(Object? message){
    if(currentLevel.index <= LoggerLevel.log.index){
      _logger.i(message.toString());
    }
  }
}
