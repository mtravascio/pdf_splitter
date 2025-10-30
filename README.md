# PDF Splitter

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/mtravascio/pdf_splitter)](https://github.com/mtravascio/pdf_splitter/releases/latest)
[![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](https://github.com/mtravascio/pdf_splitter/releases/latest)

[🇮🇹 Italian version below](#versione-italiana)

---

## English Version

**PDF Splitter** is a cross-platform desktop application developed with Flutter/Dart that enables splitting PDF files into individual pages, organizing them into specific directories, and optionally sending them via email based on a CSV input file.

### Key Features

- **CSV-Based PDF Splitting**: Automates the division of large PDF files into smaller, manageable documents based on CSV instructions.
- **Text Search and Validation**: Performs textual search within each page to validate content before saving.
- **Email Delivery**: Automatically sends extracted PDF files to email addresses specified in the CSV file, with support for Outlook on Windows and default mail clients on Linux and macOS.
- **Flexible Organization**: Creates a custom directory structure to save generated files based on information provided in the CSV.
- **Cross-Platform**: Supports Windows, Linux, and macOS, with native installation packages for each operating system.
- **Simple User Interface**: An intuitive interface that guides users through file selection and process initiation.

### Workflow and CSV Format

The application uses a CSV file to define how the input PDF should be processed. Each row in the CSV file corresponds to a splitting operation and must contain the following columns, separated by semicolon (`;`) or comma (`,`):

| Column | Name                | Description                                                                                                                                                              |
| :----- | :------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #1     | **Page ID**         | The page number to extract from the PDF file|
| #2     | **Name**            | A name or text string to search for in the extracted page to confirm it is the correct document.                                                                         |
| #3     | **Description**     | Used as the name for the generated PDF file and as the email subject if sending is enabled.                                                                             |
| #4     | **Directory**       | The main folder where the extracted file will be saved. It will be created inside the `Documents/pdf_splitter` folder.                                                  |
| #5     | **Subdirectory**    | A subfolder within the main directory for further organization.                                                                                                          |
| #6     | **Email**           | The recipient's email address to send the generated PDF file. To specify the sender, insert `from: address@email.com` in the header of this column.                     |

### Installation

You can download the latest version of the application for your operating system from the [**Releases**](https://github.com/mtravascio/pdf_splitter/releases/latest) page. The following formats are available:

- **Windows**: `.exe`,`.msix`,`.zip`
- **Linux**: `.rpm`, `.deb`, `.flatpak`,`.zip`
- **macOS**: `.dmg`

### Key Dependencies

The project relies on a high-quality ecosystem of Dart and Flutter packages, including:

- **[syncfusion_flutter_pdf](https://pub.dev/packages/syncfusion_flutter_pdf)**: For PDF document manipulation and page extraction.
- **[csv](https://pub.dev/packages/csv)**: For reading and parsing CSV files.
- **[get](https://pub.dev/packages/get)**: For simple and reactive state and dependency management.
- **[file_picker](https://pub.dev/packages/file_picker)**: To allow users to select PDF and CSV files from their system.
- **[desktop_window](https://pub.dev/packages/desktop_window)**: For managing desktop application window size and properties.

### Contributing

Contributions are always welcome! If you wish to improve the project, feel free to fork the repository, make your changes, and submit a pull request.

### License

This project is released under the [MIT License](https://opensource.org/licenses/MIT).

---

## Versione Italiana

**PDF Splitter** è un'applicazione desktop multi-piattaforma sviluppata in Flutter/Dart che consente di dividere un file PDF in pagine singole, nominarle e organizzarle in directory specifiche basandosi su un file di input CSV. L'applicazione offre inoltre la possibilità di inviare i file PDF generati via email.

### Funzionalità Principali

- **Splitting di PDF basato su CSV**: Automatizza la divisione di file PDF di grandi dimensioni in documenti più piccoli e gestibili.
- **Ricerca e Validazione**: Esegue una ricerca testuale all'interno di ogni pagina per validare il contenuto prima di salvarlo.
- **Invio tramite Email**: Invia automaticamente i file PDF estratti a indirizzi email specificati nel file CSV, con supporto per Outlook su Windows e client di posta predefiniti su Linux e macOS.
- **Organizzazione Flessibile**: Crea una struttura di directory personalizzata per salvare i file generati, basandosi sulle informazioni fornite nel CSV.
- **Multi-piattaforma**: Supporta Windows, Linux e macOS, con pacchetti di installazione nativi per ciascun sistema operativo.
- **Interfaccia Utente Semplice**: Un'interfaccia intuitiva che guida l'utente nella selezione dei file e nell'avvio del processo.

### Flusso di Lavoro e Formato CSV

L'applicazione utilizza un file CSV per definire come il PDF di input debba essere processato. Ogni riga del file CSV corrisponde a un'operazione di splitting e deve contenere le seguenti colonne, separate da punto e virgola (`;`) o virgola (`,`):

| Colonna | Nome                | Descrizione                                                                                                                                                              |
| :------ | :------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #1      | **ID Pagina**       | Il numero di pagina da estrarre dal file PDF.                                                                                                                            |
| #2      | **Nome**            | Un nome o una stringa di testo da cercare nella pagina estratta per confermare che si tratti del documento corretto.                                                      |
| #3      | **Descrizione**     | Utilizzata come nome per il file PDF generato e come oggetto dell'email se viene abilitato l'invio.                                                                    |
| #4      | **Directory**       | La cartella principale in cui salvare il file estratto. Verrà creata all'interno della cartella `Documenti/pdf_splitter`.                                                   |
| #5      | **Sottodirectory**  | Una sottocartella, all'interno della directory principale, per un'ulteriore organizzazione.                                                                              |
| #6      | **Email**           | L'indirizzo email del destinatario a cui inviare il file PDF generato. Per specificare il mittente, inserire `from: indirizzo@email.com` nell'intestazione di questa colonna. |

### Installazione

È possibile scaricare l'ultima versione dell'applicazione per il proprio sistema operativo dalla pagina [**Releases**](https://github.com/mtravascio/pdf_splitter/releases/latest). Sono disponibili i seguenti formati:

- **Windows**: `.exe`,`.msix`,`.zip`
- **Linux**: `.rpm`, `.deb`, `.flatpak`,`.zip`
- **macOS**: `.dmg`

### Dipendenze Principali

Il progetto si basa su un ecosistema di pacchetti Dart e Flutter di alta qualità, tra cui:

- **[syncfusion_flutter_pdf](https://pub.dev/packages/syncfusion_flutter_pdf)**: Per la manipolazione e l'estrazione di pagine da documenti PDF.
- **[csv](https://pub.dev/packages/csv)**: Per la lettura e l'analisi di file CSV.
- **[get](https://pub.dev/packages/get)**: Per la gestione dello stato e delle dipendenze in modo semplice e reattivo.
- **[file_picker](https://pub.dev/packages/file_picker)**: Per consentire all'utente di selezionare i file PDF e CSV dal proprio sistema.
- **[desktop_window](https://pub.dev/packages/desktop_window)**: Per la gestione delle dimensioni e delle proprietà della finestra dell'applicazione desktop.

### Contribuire

I contributi sono sempre i benvenuti! Se desideri migliorare il progetto, sei invitato a creare una fork del repository, apportare le tue modifiche e inviare una pull request.

### Licenza

This project is released under the [MIT License](https://opensource.org/licenses/MIT).
