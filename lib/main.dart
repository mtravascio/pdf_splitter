import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:desktop_window/desktop_window.dart';

void main() {
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
  var message = ''.obs;

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
        print('OK pagina $x');
      }
    }
    return pdf;
  }

  // Splitta il PDF
  Future<void> splitPdf() async {
    if (csvFilePath.value == null || pdfFilePath.value == null) {
      message.value = 'Seleziona i file CSV e PDF';
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

      if (fields.isEmpty || fields[0].length < 2) {
        message.value = 'CSV non valido';
        return;
      }

      fields.removeWhere((row) => row.contains(null));
      List<String> fileNames = fields.map((row) => row[1].toString()).toList();
      List<int> pageNumbers =
          fields.map((row) => int.tryParse(row[0].toString()) ?? 0).toList();
      // Carica il PDF originale
      final pdfDocument = await _loadPdfDocument(pdfFilePath.value!);

      // Controlla se il numero delle pagine corrisponde ai nomi
      int pageCount = pdfDocument.pages.count;
      if (fileNames.length > pageCount) {
        message.value =
            "Il numero di pagine ($pageCount) inferiore al numero di righe nel file CSV (" +
                fileNames.length.toString() +
                ")";
        return;
      }

      // Splitta il PDF in pagine singole
      //Directory outputDir = Directory('./output');
      Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      String documentsPath =
          appDocumentsDir.path.replaceAll('Library/Containers', 'Documents');
      String newDirPath = path.join(documentsPath, 'pdf_splitter');

      // Crea la directory se non esiste
      Directory outputDir = Directory(newDirPath);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
        print('Directory creata: $newDirPath');
      } else {
        print('La directory esiste già.');
      }

      // Suddividi il PDF in singole pagine
      for (int i = 0; i < fileNames.length; i++) {
        PdfDocument inPdf = await _loadPdfDocument(pdfFilePath.value!);
        //Estrae la pagina i dal file pdf
        PdfDocument outPdf = extractPage(pageNumbers[i] - 1, inPdf);

        // Crea un nome di file per ciascun PDF
        final outputFileName = '${fileNames[i]}.pdf';
        final filePath = path.join(outputDir.path, outputFileName);
        //final filePath = '${newDir.path}/${fileNames[i]}.pdf';

        // Salva ogni singola pagina come file PDF
        final file = File(filePath);
        await file.writeAsBytes(await outPdf.save());
        outPdf.dispose();
        print('File salvato: $filePath');
      }
      message.value = 'PDF splittato e rinominato correttamente!';
    } catch (e) {
      message.value = 'Errore durante il processamento: $e';
    } finally {
      isProcessing.value = false;
    }
  }
}

class PdfSplitter extends StatelessWidget {
  final PdfSplitterController controller = Get.put(PdfSplitterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Splitter')),
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
            Obx(() => ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.pickPdfFile,
                  child: Text('Seleziona file PDF'),
                )),
            SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.splitPdf,
                  child: Text('Splitta e rinomina PDF'),
                )),
            SizedBox(height: 20),
            Obx(() => controller.isProcessing.value
                ? CircularProgressIndicator()
                : Container()),
            SizedBox(height: 20),
            Obx(() => Text(controller.message.value)),
            SizedBox(height: 20),
            Obx(() => controller.csvFilePath.value != null
                ? Text('CSV scelto: ${controller.csvFilePath.value}')
                : Container()),
            Obx(() => controller.pdfFilePath.value != null
                ? Text('PDF scelto: ${controller.pdfFilePath.value}')
                : Container()),
          ],
        ),
      ),
    );
  }
}
