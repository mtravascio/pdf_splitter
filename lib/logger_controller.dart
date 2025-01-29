import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class LogController extends GetxController {
  late Directory logDirectory;
  final int maxLogDays = 30;

  // Inizializza la directory di log
  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  // Inizializza la directory di salvataggio dei log
  Future<void> _initialize() async {
    logDirectory = await _getLogDirectory();
    _cleanUpOldLogs();
    _writeLog(
        '>>>>-------------------------START--------------------------<<<<');
  }

  // Ottieni la directory dove salvare i log
  Future<Directory> _getLogDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    String documentsPath =
        directory.path.replaceAll('Library/Containers', 'Documents');
    String newDirPath = path.joinAll([documentsPath, 'pdf_splitter', 'log']);
    final logDirectory = Directory(newDirPath);
    if (!await logDirectory.exists()) {
      await logDirectory.create(recursive: true);
    }
    return logDirectory;
  }

  // Ottieni il nome del file di log per il giorno corrente
  String _getLogFileName() {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    return '${logDirectory.path}/log_$today.txt';
  }

  // Scrivi un messaggio nel file di log
  Future<void> _writeLog(String message) async {
    final logFile = File(_getLogFileName());
    final logMessage =
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())} - $message\n';
    await logFile.writeAsString(logMessage, mode: FileMode.append);
  }

  // Gestisci la rotazione dei log: rimuovi i log più vecchi di 30 giorni
  Future<void> _cleanUpOldLogs() async {
    final files = logDirectory.listSync();
    final thresholdDate = DateTime.now().subtract(Duration(days: maxLogDays));

    for (var file in files) {
      if (file is File) {
        final fileName = file.uri.pathSegments.last;
        final dateString =
            fileName.substring(4, 12); // Estrai la data dal nome del file
        final fileDate = DateFormat('yyyyMMdd').parse(dateString);

        if (fileDate.isBefore(thresholdDate)) {
          await file.delete();
        }
      }
    }
  }

  // Funzione per scrivere i log di INFO
  void logInfo(String message) async {
    debugPrint('INFO: $message');
    await _writeLog('INFO: $message');
  }

  // Funzione per scrivere i log di DEBUG
  void logDebug(String message) async {
    debugPrint('DEBUG: $message');
    await _writeLog('DEBUG: $message');
  }

  // Funzione per scrivere i log di ERROR
  void logError(String message) async {
    debugPrint('ERROR: $message');
    await _writeLog('ERROR: $message');
  }
}
