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
  DesktopWindow.setWindowSize(Size(400, 600));
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
  var createDirectories = true.obs;
  var canEnableSwitch = false.obs;

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

  appDebug(String msg) {
    //final logController = Get.find<LogController>();
    //logController.logDebug(msg); // Usa logDebug per i messaggi di errore
    print('DEBUG: $msg'); // Usa logDebug per i messaggi di errore
  }

  // Seleziona il file CSV
  Future<void> pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      csvFilePath.value = result.files.single.path;
      checkCSV();
    }
  }

  // Metodo per verificare la presenza delle colonne 'directory' e 'subdirectory'
  Future<void> checkCSV() async {
    if (csvFilePath.value == null) return;

    final csvFile = File(csvFilePath.value!);
    if (csvFile.existsSync()) {
      String csvContent = await csvFile.readAsString();

      var d = FirstOccurrenceSettingsDetector(
        fieldDelimiters: [';', ','],
        eols: ['\n', '\r\n'],
      );

      List<List<dynamic>> fields = CsvToListConverter(
              csvSettingsDetector: d, convertEmptyTo: EmptyValue.NULL)
          .convert(csvContent);

      if (fields.isEmpty || fields[0].length < 2) {
        message = 'CSV non valido - #,nome,descr,dir,subdir';
        appError('CSV non valido - #,nome,descr,dir,subdir');
        //appInfo('CSV non valido - #,nome,descr,dir,subdir');
        return;
      }
      // Verifica se la colonna 4 (indice 3) e la colonna 5 (indice 4) sono presenti
      if (fields.isNotEmpty && fields[0].length >= 5) {
        // Se entrambe le colonne 4 e 5 esistono, abilitare lo switch
        createDirectories.value = true; // Imposta su ON
        canEnableSwitch.value = true; // Abilita lo switch
      } else {
        // Se una delle colonne manca, disabilitare lo switch
        createDirectories.value = false; // Imposta su OFF
        canEnableSwitch.value = false; // Disabilita lo switch
      }
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
        appDebug('Pagina $x OK!');
        //message = 'Pagina $x OK!';
      }
    }
    return pdf;
  }

  //Non trova occorrenze se l'occorrenza termina con l'apostrofo.
  List<String> cercaOccorrenze(String testo, String occorrenza) {
    // Definisci una regex per cercare l'occorrenza all'interno di un testo
    String occorrenzaEscaped = RegExp.escape(occorrenza);

    // Il pattern cerca una sequenza di parole (separati da spazi) che coincidano esattamente con 'occorrenza'
    RegExp regExp = RegExp(r'\b' + occorrenzaEscaped);

    // Trova tutte le corrispondenze nel testo
    Iterable<Match> matches = regExp.allMatches(testo);

    // Estrai le corrispondenze e le restituisce in una lista
    List<String> risultati = [];
    for (var match in matches) {
      risultati.add(match.group(0)!);
    }

    return risultati;
  }

  //Da rivedere i messaggi di errore e di info
  bool SearchName(String name, PdfDocument outPdf) {
    // Legge il file di testo
    String text = PdfTextExtractor(outPdf).extractText();

    List<String> nomeCognome = cercaOccorrenze(text, name);

    if (nomeCognome.isNotEmpty) {
      appInfo('Nome $name [$nomeCognome] OK!');
      return true;
    } else {
      appError('Nome $name [$nomeCognome] Non TROVATO!');
      return false;
    }
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

  // Funzione che verifica se il valore è un numero
  bool isOK(dynamic valore) {
    if (valore == null) return false;
    if (valore is int) return true;
    if (valore is double) return false;
    return false;
  }

  // Splitta il PDF
  Future<void> splitPdf() async {
    if (csvFilePath.value == null || pdfFilePath.value == null) {
      message = 'Seleziona i file CSV e PDF';
      return;
    }

    try {
      appInfo('<--------------SPLITTING---------------->');
      isProcessing.value = true;

      var d = FirstOccurrenceSettingsDetector(
          fieldDelimiters: [';', ','],
          eols: ['\n', '\r\n']); // Leggi il file CSV
      final csv = File(csvFilePath.value!).readAsStringSync();
      List<List<dynamic>> fields = CsvToListConverter(
              csvSettingsDetector: d, convertEmptyTo: EmptyValue.NULL)
          .convert(csv);

      if (fields.isEmpty || fields[0].length < 2) {
        message = 'CSV non valido - #,nome,descr,dir,subdir';
        appError('CSV non valido - #,nome,descr,dir,subdir');
        return;
      }
/*
      // Verifica se la colonna 4 (indice 3) e la colonna 5 (indice 4) sono presenti
      if (fields.isNotEmpty && fields[0].length >= 5) {
        // Se entrambe le colonne 4 e 5 esistono, abilitare lo switch
        createDirectories.value = true; // Imposta su ON
        canEnableSwitch.value = true; // Abilita lo switch
      } else {
        // Se una delle colonne manca, disabilitare lo switch
        createDirectories.value = false; // Imposta su OFF
        canEnableSwitch.value = false; // Disabilita lo switch
      }
*/
      // Filtra le righe per mantenere solo quelle che iniziano con un numero
      fields = fields.where((row) {
        // Verifica se il primo campo è un numero
        return row.isNotEmpty && isOK(row[0]);
      }).toList();

      fields.removeWhere((row) => row.contains(null));
      List<int> pageNumbers =
          fields.map((row) => int.tryParse(row[0].toString()) ?? 0).toList();
      List<String> fileNames = fields.map((row) => row[1].toString()).toList();
      List<String> dirNames = [];
      List<String> subdirNames = [];

      // Se l'opzione di creare directory è attiva, estrai anche dirNames e subdirNames
      if (createDirectories.value) {
        dirNames = fields.map((row) => row[3].toString()).toList();
        subdirNames = fields.map((row) => row[4].toString()).toList();
      }

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
        //Carica il file pdf sempre completo
        PdfDocument inPdf = await _loadPdfDocument(pdfFilePath.value!);
        //Estrae la pagina i dal file pdf
        PdfDocument outPdf = extractPage(pageNumbers[i] - 1, inPdf);

        //Estrae il campo nome all'interno del file PDF
        //String name = extractName(outPdf);
        //if (name != fileNames[i]) {

        //Cerca il nome dell'utente all'interno del filePdf
        if (!SearchName(fileNames[i], outPdf)) {
          message = 'Pagina: ${pageNumbers[i]} - ${fileNames[i]} ERROR! ';
          appError('${pageNumbers[i]} - ${fileNames[i]} Errore!');
        } else {
          appInfo('${pageNumbers[i]} - ${fileNames[i]}  OK!');

          message = 'Pagina ${pageNumbers[i]} - ${fileNames[i]}  OK!';

          String newDirPath = path.join(documentsPath, 'pdf_splitter');

          if (createDirectories.value) {
            // Se la creazione delle directory è abilitata, aggiungi dirNames e subdirNames
            newDirPath =
                path.joinAll([newDirPath, dirNames[i], subdirNames[i]]);
          } else {
            // Se la creazione delle directory non è abilitata, usa la directory principale
            appDebug(
                'Creazione directory disabilitata. I file verranno salvati nella directory principale.');
          }

          // Crea la directory se non esiste
          if (createDirectories.value) {
            Directory outputDir = Directory(newDirPath);
            if (!await outputDir.exists()) {
              await outputDir.create(recursive: true);
              appDebug('Directory creata: $newDirPath');
            } else {
              appDebug('La directory $newDirPath esiste già.');
            }
          } else {
            appDebug(
                'Creazione directory disabilitata. I file verranno salvati nella directory principale.');
            newDirPath = path.join(documentsPath,
                'pdf_splitter'); // Imposta la directory principale
          }

          // Crea un nome di file per ciascun PDF
          final outputFileName = '${fileNames[i]}.pdf';
          final filePath = path.join(newDirPath, outputFileName);

          // Salva ogni singola pagina come file PDF
          final file = File(filePath);
          await file.writeAsBytes(await outPdf.save());
          appInfo('File salvato: $filePath');
          outPdf.dispose();
        }
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
            // Switch per abilitare/disabilitare la creazione di directory
            Obx(() => SwitchListTile(
                  title: Text("Crea directory e sottodirectory"),
                  value: controller.createDirectories.value,
                  onChanged: controller.canEnableSwitch.value
                      ? (value) {
                          controller.createDirectories.value = value;
                        }
                      : null, // Disabilita lo switch se canEnableSwitch è false
                  subtitle: controller.canEnableSwitch.value
                      ? null
                      : Text(
                          "Le colonne 'directory' e 'subdirectory' non sono presenti nel CSV."),
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
