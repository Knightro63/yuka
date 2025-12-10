import 'package:flutter/material.dart';

YukaConsole yukaConsole = YukaConsole();
enum LoggerLevel{log,warning,error,silent}
LoggerLevel currentLevel = LoggerLevel.warning;

// ignore: camel_case_types
class YukaConsole {
  /// Gives access to internal logger
  dynamic get rawLogger => null;

    /// Logs error messages
  void error(Object? message){
    if(currentLevel.index <= LoggerLevel.error.index) throw('Error Log', error: '⚠️ $message');
  }

  /// Prints to console
  void warning(Object? message){
    if(currentLevel.index <= LoggerLevel.warning.index){
      debugPrint(message.toString());
    }
  }
  /// Prints to console if [isVerbose] is true
  void log(Object? message){
    if(currentLevel.index <= LoggerLevel.log.index){
      debugPrint(message.toString());
    }
  }

  void setLevel(int level ) {
		currentLevel = LoggerLevel.values[level];
	}
}
