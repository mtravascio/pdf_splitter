import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/services.dart';
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
  DesktopWindow.setWindowSize(Size(480, 1000));
  //DesktopWindow.setBorders(false);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Splitter',
      home: PdfSplitter(),
      debugShowCheckedModeBanner: false,
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
  var useDescription = false.obs;
  var createDirectories = true.obs;
  var sendEmailAfterSplit = false.obs;
  var canEnableSwitchDir = false.obs;
  var canEnableSwitchDescr = false.obs;
  var canEnableSwitchEmail = false.obs;
  var splitIntoSubdir = false.obs;
  var canEnableSplitIntoSubdir = false.obs;
  String fromAddress = '';

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
        // Se entrambe le colonne 0 e 1 esistono, abilitare lo switch
        createDirectories.value = true; // Imposta su ON
        canEnableSwitchDir.value = true; // Abilita lo switch
        canEnableSwitchDescr.value = true; // Abilita lo switch
      } else if (fields.isNotEmpty && fields[0].length >= 3) {
        // Se una delle colonne manca, disabilitare lo switch ma ancora descr esiste
        createDirectories.value = false; // Imposta su OFF
        canEnableSwitchDir.value = false; // Disabilita lo switch
        canEnableSwitchDescr.value = true; // Abilita lo switch
      } else {
        createDirectories.value = false; // Imposta su OFF
        canEnableSwitchDir.value = false; // Disabilita lo switch
        canEnableSwitchDescr.value = false; // Disabilita lo switch
      }
      if (fields.isNotEmpty &&
          fields[0].length >= 6 &&
          fields[0][5].toString().contains(RegExp(
              r'(?<=from:\s+)([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'))) {
        RegExp emailRegExp = RegExp(
            r'(?<=from:\s+)([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})');
        var match = emailRegExp.firstMatch(fields[0][5].toString());
        if (match != null) {
          fromAddress = match.group(0)!;
          message = 'Email di invio: $fromAddress';
          appInfo('Email di invio: $fromAddress');
        } else {
          message = 'Email di invio non valida!';
          appError('Email di invio non valida!');
        }
        sendEmailAfterSplit.value = false; // Imposta su OFF precauzionalmente
        canEnableSwitchEmail.value = true; // Abilita lo switch
      } else {
        // Se una delle colonne manca, disabilitare lo switch
        sendEmailAfterSplit.value = false; // Imposta su OFF
        canEnableSwitchEmail.value = false; // Disabilita lo switch
      }
    }
  }

  // Seleziona il file PDF
  Future<void> pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      pdfFilePath.value = result.files.single.path;
      canEnableSplitIntoSubdir.value = true;
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
      List<int> pageNumbers = fields
          .map((row) => int.tryParse(row[0].toString().trim()) ?? 0)
          .toList();
      List<String> fileNames =
          fields.map((row) => row[1].toString().trim()).toList();
      List<String> descNames = [];
      if (useDescription.value) {
        descNames = fields.map((row) => row[2].toString().trim()).toList();
      }
      List<String> dirNames = [];
      List<String> subdirNames = [];

      // Se l'opzione di creare directory è attiva, estrai anche dirNames e subdirNames
      if (createDirectories.value) {
        dirNames = fields.map((row) => row[3].toString().trim()).toList();
        subdirNames = fields.map((row) => row[4].toString().trim()).toList();
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
          String outputFileName = '';
          if (useDescription.value) {
            outputFileName = '${fileNames[i]}_${descNames[i]}.pdf';
          } else {
            outputFileName = '${fileNames[i]}.pdf';
          }

          final filePath = path.join(newDirPath, outputFileName);

          if (splitIntoSubdir.value) {
            String subdirName = path.basenameWithoutExtension(outputFileName);
            String subdirPath = path.join(newDirPath, subdirName);
            Directory subDir = Directory(subdirPath);
            if (!await subDir.exists()) {
              await subDir.create(recursive: true);
              appDebug('Subdirectory creata: $subdirPath');
            }
            String newFilePath = path.join(subdirPath, '$subdirName.pdf');
            final file = File(filePath);
            await file.writeAsBytes(await outPdf.save());
            await file.rename(newFilePath);
            appInfo('File salvato in subdirectory: $newFilePath');
          } else {
            // Salva ogni singola pagina come file PDF
            final file = File(filePath);
            await file.writeAsBytes(await outPdf.save());
            appInfo('File salvato: $filePath');
          }
          outPdf.dispose();

          if (sendEmailAfterSplit.value) {
            // Invia l'email con il file PDF in allegato
            message = 'Attesa 10s prima di invio';
            appInfo('Attesa 10s prima di invio');
            await Future.delayed(Duration(seconds: 10));
            message = 'Invio email a ${fields[i][5]} con file $filePath';
            appInfo(
                'Invio email a ${fields[i][5]} con Oggetto ${fields[i][2]} e con file $filePath');
            await sendEmail(
                fields[i][5].toString(),
                fields[i][2].toString(),
                'Gentile ${fields[i][1]}, si trasmette in allegato quanto in oggetto.',
                filePath);
            message = 'Attesa 10s post di invio';
            appInfo('Attesa 10s post di invio');
            await Future.delayed(Duration(seconds: 10));
          }
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

  // Funzione per inviare un'email usando lo script VBS
  Future<void> sendEmail(
      String email, String subject, String body, String filePath) async {
    // Leggi lo script VBS dagli asset
    String vbsScript = await rootBundle.loadString('assets/send_mail.vbs');
    String mailScript = await rootBundle.loadString('assets/send_mail.sh');

    Directory tempDir = await getTemporaryDirectory();
    String tempDirPath = tempDir.path;
    // Scrivi lo script VBS in un file temporaneo
    //File tempVbsFile = File('C:\\send_email.vbs');
    String command;
    if (Platform.isWindows) {
      File tempVbsFile = File(path.join(tempDirPath, 'send_email.vbs'));
      await tempVbsFile.writeAsString(vbsScript);
      // Comando per eseguire lo script VBS
      command =
          'cscript ${tempVbsFile.path} -from "$fromAddress" -to "$email" -subject "$subject" -body "$body" -attach "$filePath"';
    } else {
      File tempShFile = File(path.join(tempDirPath, 'send_email.sh'));
      await tempShFile.writeAsString(mailScript);
      command =
          '${tempShFile.path} -from "$fromAddress" -to "$email" -subject "$subject" -body "$body" -attach "$filePath"';
    }
    // Comando per eseguire lo script VBS
    appDebug('Comando: $command');

    //String regCommand = command.replaceAll(r'\', '');

    //appDebug('regComando: $regCommand');
    // Esegui il comando
    var result;
    if (Platform.isWindows) {
      result = await Process.run('cmd.exe', ['/c', command]);
      //result = await Process.run('cmd.exe', ['/c', regCommand]);
      //result = await Process.run('cmd.exe', ['/c', 'echo $command']);
    } else if (Platform.isLinux) {
      //result = await Process.run('bash', ['-c', command]);
      result = await Process.run('bash', ['-c', 'echo $command']);
    } else if (Platform.isMacOS) {
      //result = await Process.run('bash', ['-c', command]);
      result = await Process.run('bash', ['-c', 'echo $command']);
    }

    if (result.exitCode == 0) {
      message = 'Email inviata con successo a $email!';
      appInfo("Email inviata con successo a $email");
    } else {
      appError("Errore durante l'invio dell'email: ${result.stderr}");
    }
  }
}

class PdfSplitter extends StatelessWidget {
  final PdfSplitterController controller = Get.put(PdfSplitterController());

  @override
  Widget build(BuildContext context) {
    controller.getAppName();
    controller.getAppVersion();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => Text(
                      controller.appName.value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    )),
                Obx(() => Text(
                      'v${controller.version.value}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    )),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.deepPurpleAccent.shade700,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              if (value == 'help') {
                _showHelpDialog(context);
              } else if (value == 'about') {
                _showAboutDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.deepPurpleAccent),
                    SizedBox(width: 12),
                    Text('Guida'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.deepPurpleAccent),
                    SizedBox(width: 12),
                    Text('Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileSelectionCard(),
            const SizedBox(height: 12),
            _buildOptionsCard(),
            const SizedBox(height: 12),
            _buildActionCard(),
            const SizedBox(height: 12),
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_open,
                    color: Colors.deepPurpleAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Selezione File',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFileButton(
              icon: Icons.description,
              label: 'Seleziona CSV',
              isCsv: true,
            ),
            const SizedBox(height: 8),
            Obx(() => _buildFilePath(
                  label: 'CSV',
                  path: controller.csvFilePath.value,
                  icon: Icons.table_chart,
                )),
            const SizedBox(height: 12),
            _buildFileButton(
              icon: Icons.picture_as_pdf,
              label: 'Seleziona PDF',
              isCsv: false,
            ),
            const SizedBox(height: 8),
            Obx(() => _buildFilePath(
                  label: 'PDF',
                  path: controller.pdfFilePath.value,
                  icon: Icons.auto_stories,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFileButton({
    required IconData icon,
    required String label,
    required bool isCsv,
  }) {
    return Obx(() => ElevatedButton.icon(
          onPressed: controller.isProcessing.value
              ? null
              : (isCsv ? controller.pickCsvFile : controller.pickPdfFile),
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            backgroundColor:
                isCsv ? Colors.orange.shade700 : Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
        ));
  }

  Widget _buildFilePath({
    required String label,
    required String? path,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path ?? 'Nessun file selezionato',
              style: TextStyle(
                color: path != null ? Colors.black87 : Colors.grey.shade500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.deepPurpleAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Opzioni',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() => _buildSwitch(
                  title: 'Invia email dopo lo split',
                  subtitle: controller.canEnableSwitchEmail.value
                      ? 'La colonna email (#6) è presente'
                      : "La colonna 'email' (#6) non è presente nel CSV",
                  value: controller.sendEmailAfterSplit.value,
                  enabled: controller.canEnableSwitchEmail.value,
                  onChanged: (value) =>
                      controller.sendEmailAfterSplit.value = value,
                  icon: Icons.email,
                )),
            const Divider(height: 16),
            Obx(() => _buildSwitch(
                  title: "Usa la 'description' nel nomefile",
                  subtitle: controller.canEnableSwitchDescr.value
                      ? "La colonna description (#3) è presente"
                      : "La colonna 'description' (#3) non è presente nel CSV",
                  value: controller.useDescription.value,
                  enabled: controller.canEnableSwitchDescr.value,
                  onChanged: (value) => controller.useDescription.value = value,
                  icon: Icons.text_fields,
                )),
            const Divider(height: 16),
            Obx(() => _buildSwitch(
                  title: "Crea 'directory' e 'sottodirectory'",
                  subtitle: controller.canEnableSwitchDir.value
                      ? "Le colonne directory (#4) e subdirectory (#5) sono presenti"
                      : "Le colonne 'directory' (#4) e 'subdirectory' (#5) non sono presenti nel CSV",
                  value: controller.createDirectories.value,
                  enabled: controller.canEnableSwitchDir.value,
                  onChanged: (value) =>
                      controller.createDirectories.value = value,
                  icon: Icons.folder,
                )),
            const Divider(height: 16),
            Obx(() => _buildSwitch(
                  title: 'Split in sottodirectory che hanno il nome del file',
                  subtitle: controller.canEnableSplitIntoSubdir.value
                      ? 'Crea una directory per ogni file PDF'
                      : 'Seleziona prima CSV e PDF',
                  value: controller.splitIntoSubdir.value,
                  enabled: controller.canEnableSplitIntoSubdir.value,
                  onChanged: (value) =>
                      controller.splitIntoSubdir.value = value,
                  icon: Icons.create_new_folder,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(
        icon,
        color: enabled ? Colors.deepPurpleAccent : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeTrackColor: Colors.deepPurpleAccent.shade200,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.deepPurpleAccent;
        }
        return Colors.grey;
      }),
    );
  }

  Widget _buildActionCard() {
    return Card(
      elevation: 3,
      color: Colors.deepPurpleAccent.shade700,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton.icon(
              onPressed:
                  controller.isProcessing.value ? null : controller.splitPdf,
              icon: controller.isProcessing.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.play_arrow, size: 24),
              label: Text(
                controller.isProcessing.value
                    ? 'Elaborazione in corso...'
                    : 'Splitta e Rinomina PDF',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurpleAccent.shade700,
              ),
            )),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.deepPurpleAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Stato',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: controller.isProcessing.value
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: controller.isProcessing.value
                          ? Colors.blue.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (controller.isProcessing.value) ...[
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          controller.message.isEmpty
                              ? 'Pronto per elaborare...'
                              : controller.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: controller.isProcessing.value
                                ? Colors.blue.shade700
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.deepPurpleAccent),
            SizedBox(width: 12),
            Text('Guida'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection('Come funziona',
                  'Questa app divide un PDF in singole pagine, rinominando ogni pagina secondo le informazioni presenti nel file CSV.'),
              _buildHelpSection('Formato CSV richiesto',
                  'Colonna 0: Numero pagina (intero)\nColonna 1: Nome file\nColonna 2: Descrizione (opzionale)\nColonna 3: Directory (opzionale)\nColonna 4: Subdirectory (opzionale)\nColonna 5: Email (opzionale, formato: from: email@esempio.com)'),
              _buildHelpSection('Seleziona CSV',
                  'Scegli il file CSV contenente i dati per la divisione. Vengono rilevate automaticamente le colonne presenti.'),
              _buildHelpSection('Seleziona PDF',
                  'Scegli il file PDF da dividere in singole pagine.'),
              _buildHelpSection('Opzioni',
                  '- Invia email: Invia automaticamente ogni PDF splittato via email (richiede colonna #6)\n- Usa description: Aggiunge la descrizione al nome del file (richiede colonna #3)\n- Crea directory: Organizza i file in cartelle basate su directory/subdirectory (richiede colonne #4 e #5)\n- Split in sottodirectory: Crea una directory separata che ha il nome del file per ogni file PDF con il file pdf splittato all\'interno'),
              _buildHelpSection('Splitta PDF',
                  'Avvia il processo di divisione. Ogni pagina viene salvata come file separato e verificata per il nome.'),
              _buildHelpSection('Nota',
                  'Le opzioni vengono abilitate automaticamente in base alle colonne presenti nel file CSV selezionato.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.deepPurpleAccent),
            SizedBox(width: 12),
            Text('Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF Splitter',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Obx(() => Text('Versione: ${controller.version.value}')),
            SizedBox(height: 16),
            Text(
              'Divide PDF in singole pagine basandosi sui nomi presenti in un file CSV.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
          ),
          SizedBox(height: 4),
          Text(content, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
