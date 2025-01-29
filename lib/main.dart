import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pdf_splitter/logger_controller.dart';

import 'package:desktop_window/desktop_window.dart';

void main() {
  // Inizializza il controller dei log
  Get.put(LogController());

  WidgetsFlutterBinding.ensureInitialized();
  //DesktopWindow.setMinWindowSize(Size(300, 300)); // Imposta la dimensione minima della finestra
  //DesktopWindow.setMaxWindowSize(Size(800, 800)); // Imposta la dimensione massima della finestra
  DesktopWindow.setWindowSize(Size(400, 500));
  //DesktopWindow.setBorders(false);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PdfSplitter(),
    );
  }
}

class PdfSplitterController extends GetxController {
  var csvFilePath = Rx<String?>(null);
  var pdfFilePath = Rx<String?>(null);
  var isProcessing = false.obs;
  var _message = ''.obs;
  var appName = ''.obs;
  var version = ''.obs;

  // Getter per ottenere il valore del messaggio
  String get message => _message.value;

  // Setter per impostare il valore del messaggio
  set message(String newMessage) {
    _message.value = newMessage;
    //app_print(newMessage);
  }

  // Metodo per ottenere la versione dell'app
  Future<void> getAppName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName.value = packageInfo.appName; // Imposta la versione
  }

  // Metodo per ottenere la versione dell'app
  Future<void> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version.value = packageInfo.version; // Imposta la versione
  }

  // Redirigi le chiamate a print e debugPrint ai metodi del LogController
  appInfo(String msg) {
    final logController = Get.find<LogController>();
    logController.logInfo(msg); // Usa logInfo per i messaggi generali
  }

  appError(String msg) {
    final logController = Get.find<LogController>();
    logController.logError(msg); // Usa logDebug per i messaggi di errore
  }

  // Seleziona il file CSV
  Future<void> pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      csvFilePath.value = result.files.single.path;
    }
  }

  // Seleziona il file PDF
  Future<void> pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      pdfFilePath.value = result.files.single.path;
    }
  }

  Future<PdfDocument> _loadPdfDocument(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Il file PDF non esiste: $path');
    }
    final bytes = await file.readAsBytes();
    return PdfDocument(inputBytes: bytes);
  }

  PdfDocument extractPage(int pageIndex, PdfDocument pdf) {
    int pageCount = pdf.pages.count;
    for (int x = 0; x < pageCount; x++) {
      if (x < pageIndex) {
        pdf.pages.removeAt(0);
      } else if (x > pageIndex) {
        pdf.pages.removeAt(1);
      } else {
        appInfo('Pagina $x OK!');
        message = 'Pagina $x OK!';
      }
    }
    return pdf;
  }

  String extractName(PdfDocument outPdf) {
    try {
      // Legge il file di testo
      String text = PdfTextExtractor(outPdf).extractText();

      // Trova la posizione della frase "Si attesta che"
      final startIndex = text.indexOf("Si attesta che");

      if (startIndex == -1) {
        message = "Frase 'Si attesta che' non trovata nel file.";
        appError("Frase 'Si attesta che' non trovata nel file.");
        return "Frase 'Si attesta che' non trovata nel file.";
      }

      // Estrae il testo che inizia con "Si attesta che"
      String substring = text.substring(startIndex);

      // Trova la fine della stringa, che è il trattino ('-')
      final endIndex = substring.indexOf('-');
      if (endIndex == -1) {
        message =
            "Trattino di separazione del nome '-' non trovato nel contenuto del testo.";
        appError(
            "Trattino di separazione del nome '-' non trovato nel contenuto del testo.");
        return "Trattino di separazione del nome '-' non trovato nel contenuto del testo.";
      }

      // Estrae il testo tra "Si attesta che" e il trattino
      String nomeCognomeParte =
          substring.substring("Si attesta che".length, endIndex).trim();

      // Restituisce il risultato
      return nomeCognomeParte;
    } catch (e) {
      message = "Errore durante la lettura del contenuto del file PDF";
      appError("Errore durante la lettura del contenuto del file PDF");
      return "Errore durante la lettura del contenuto del file PDF";
    }
  }

  // Splitta il PDF
  Future<void> splitPdf() async {
    if (csvFilePath.value == null || pdfFilePath.value == null) {
      message = 'Seleziona i file CSV e PDF';
      return;
    }

    try {
      isProcessing.value = true;

      var d = FirstOccurrenceSettingsDetector(
          fieldDelimiters: [';', ','],
          eols: ['\n', '\r\n']); // Leggi il file CSV
      final csv = File(csvFilePath.value!).readAsStringSync();
      final fields = CsvToListConverter(
              csvSettingsDetector: d, convertEmptyTo: EmptyValue.NULL)
          .convert(csv);

      if (fields.isEmpty || fields[0].length < 5) {
        message = 'CSV non valido - #,nome,descr,dir,subdir';
        appError('CSV non valido - #,nome,descr,dir,subdir');
        return;
      }

      fields.removeWhere((row) => row.contains(null));
      List<String> fileNames = fields.map((row) => row[1].toString()).toList();
      List<String> dirNames = fields.map((row) => row[3].toString()).toList();
      List<String> subdirNames =
          fields.map((row) => row[4].toString()).toList();
      List<int> pageNumbers =
          fields.map((row) => int.tryParse(row[0].toString()) ?? 0).toList();
      // Carica il PDF originale
      final pdfDocument = await _loadPdfDocument(pdfFilePath.value!);

      // Controlla se il numero delle pagine corrisponde ai nomi
      int pageCount = pdfDocument.pages.count;
      if (fileNames.length > pageCount) {
        message = "#pagine PDF < #file CVS !";
        appError(
            "#pagine PDF ($pageCount) < #file CSV (${fileNames.length.toString()})");
        return;
      }

      // Preleva la directory Documents
      Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      // Evita la sandbox MacOS
      String documentsPath =
          appDocumentsDir.path.replaceAll('Library/Containers', 'Documents');

      // Suddividi il PDF in singole pagine creando le directory di destinazione
      for (int i = 0; i < fileNames.length; i++) {
        String newDirPath = path.joinAll(
            [documentsPath, 'pdf_splitter', dirNames[i], subdirNames[i]]);

        // Crea la directory se non esiste
        Directory outputDir = Directory(newDirPath);
        if (!await outputDir.exists()) {
          await outputDir.create(recursive: true);
          message = 'Directory creata: $newDirPath';
          appInfo('Directory creata: $newDirPath');
        } else {
          message = 'La directory $newDirPath esiste già.';
          appInfo('La directory $newDirPath esiste già.');
        }

        //Carica il file pdf sempre completo
        PdfDocument inPdf = await _loadPdfDocument(pdfFilePath.value!);
        //Estrae la pagina i dal file pdf
        PdfDocument outPdf = extractPage(pageNumbers[i] - 1, inPdf);

        //cerca il nome dell'utente il suffisso regex
        String name = extractName(outPdf);

        if (name != fileNames[i]) {
          appError(
              'errore tra  contenuto PDF ($name) e file CSV indice $i (${fileNames[i]})');
        } else
          appInfo('Nome OK - $name');

        // Crea un nome di file per ciascun PDF
        final outputFileName = '${fileNames[i]}.pdf';
        final filePath = path.join(outputDir.path, outputFileName);

        // Salva ogni singola pagina come file PDF
        final file = File(filePath);
        await file.writeAsBytes(await outPdf.save());
        appInfo('File salvato: $filePath');
        outPdf.dispose();
        message = 'File salvato: $filePath';
      }
      message = 'PDF splittati e rinominati';
      appInfo('PDF splittati e rinominati');
    } catch (e) {
      message = 'Errore durante il processamento: $e';
      appError('Errore durante il processamento: $e');
    } finally {
      isProcessing.value = false;
    }
  }
}

class PdfSplitter extends StatelessWidget {
  final PdfSplitterController controller = Get.put(PdfSplitterController());

  @override
  Widget build(BuildContext context) {
    //Recupera il nome e la versione dell'App
    controller.getAppName();
    controller.getAppVersion();
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          // Mostra il nome dell'app dinamicamente
          return Text(controller.appName.value);
        }),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          // Usa Obx per osservare e aggiornare automaticamente la versione
          Obx(() {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                controller.version.isNotEmpty
                    ? 'Version: ${controller.version.value}'
                    : 'Loading...',
                style: TextStyle(fontSize: 16),
              ),
            );
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.pickCsvFile,
                  child: Text('Seleziona file CSV'),
                )),
            SizedBox(height: 20),
            Obx(() => controller.csvFilePath.value != null
                ? Text('CSV: ${controller.csvFilePath.value}')
                : Container()),
            SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.pickPdfFile,
                  child: Text('Seleziona file PDF'),
                )),
            SizedBox(height: 20),
            Obx(() => controller.pdfFilePath.value != null
                ? Text('PDF: ${controller.pdfFilePath.value}')
                : Container()),
            SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.splitPdf,
                  child: Text('Splitta e Rinomina PDF'),
                )),
            SizedBox(height: 20),
            Obx(() => controller.isProcessing.value
                ? CircularProgressIndicator()
                : Container()),
            SizedBox(height: 20),
            Obx(() => Text(controller.message)),
          ],
        ),
      ),
    );
  }
}
