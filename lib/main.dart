import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

void main(List<String> arguments) {
  // Controlla se il percorso del file PDF è passato come argomento
  if (arguments.isEmpty) {
    print("Errore: Devi fornire il percorso del file PDF come argomento.");
    return;
  }

  String pdfFilePath = arguments[0];

  runApp(MyApp(pdfFilePath));
}

class MyApp extends StatelessWidget {
  final String pdfFilePath;

  MyApp(this.pdfFilePath);

  Future<void> splitPdf() async {
    // Carica il PDF originale
    final pdfDocument = await _loadPdfDocument(pdfFilePath);

    // Ottieni la directory in cui salvare i file PDF separati
    final directory = await getApplicationDocumentsDirectory();

    // Suddividi il PDF in singole pagine
    for (int i = 0; i < pdfDocument.pages.count; i++) {
      final outPdf = await _loadPdfDocument(pdfFilePath);
      for (int x = 0; x < pdfDocument.pages.count; x++) {
        if (x < i) {
          outPdf.pages.removeAt(0);
        } else if (x > i) {
          outPdf.pages.removeAt(1);
        } else {
          print('OK pagina $x');
        }
      }
      // Crea un nome di file per ciascun PDF
      final filePath = '${directory.path}/page_${i + 1}.pdf';

      // Salva ogni singola pagina come file PDF
      final file = File(filePath);
      await file.writeAsBytes(await outPdf.save());
      outPdf.dispose();
      print('File salvato: $filePath');
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('PDF Splitter'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: splitPdf,
            child: Text('Split PDF'),
          ),
        ),
      ),
    );
  }
}
