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
    if (!logDirectory.existsSync()) {
      logDirectory.createSync(recursive: true);
    }
    return logDirectory;
  }

  // Ottieni il nome del file di log per il giorno corrente
  String _getLogFileName() {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    return '${logDirectory.path}/log_$today.txt';
  }

  // Scrivi un messaggio nel file di log
  void _writeLog(String message) {
    final logFile = File(_getLogFileName());
    final logMessage =
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())} - $message\n';
    logFile.writeAsStringSync(logMessage, mode: FileMode.append);
  }

  // Gestisci la rotazione dei log: rimuovi i log più vecchi di 30 giorni
  void _cleanUpOldLogs() {
    final files = logDirectory.listSync();
    final thresholdDate = DateTime.now().subtract(Duration(days: maxLogDays));

    for (var file in files) {
      if (file is File) {
        final fileName = file.uri.pathSegments.last;
        print('🧪 Found file: $fileName'); // Per debug: vedi tutti i file

        try {
          // Usa RegExp per garantire che il nome del file sia nel formato corretto
          final regex = RegExp(r'^log_(\d{8})\.txt$');
          final match = regex.firstMatch(fileName);

          if (match != null) {
            final dateString = match.group(1)!; // Ottieni la data dal match
            print('📅 Parsing file date from string: "$dateString"');
            //final fileDate = DateFormat('yyyyMMdd').parse(dateString); // Parsea la data
            final year = int.parse(dateString.substring(0, 4));
            final month = int.parse(dateString.substring(4, 6));
            final day = int.parse(dateString.substring(6, 8));
            final fileDate = DateTime(year, month, day);

            if (fileDate.isBefore(thresholdDate)) {
              print(
                  '🗑️ Deleting old log file: $fileName'); // Mostra quale file viene cancellato
              file.deleteSync();
            }
          } else {
            debugPrint(
                '⚠️ Skipping non-log file: $fileName'); // Aggiunto per debug
          }
        } catch (e) {
          debugPrint('❌ Errore nel parsing del file "$fileName": $e');
        }
      }
    }
  }

  // Funzione per scrivere i log di INFO
  void logInfo(String message) {
    debugPrint('INFO: $message');
    _writeLog('INFO: $message');
  }

  // Funzione per scrivere i log di DEBUG
  void logDebug(String message) {
    debugPrint('DEBUG: $message');
    _writeLog('DEBUG: $message');
  }

  // Funzione per scrivere i log di ERROR
  void logError(String message) {
    debugPrint('ERROR: $message');
    _writeLog('ERROR: $message');
  }
}
