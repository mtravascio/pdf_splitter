# PDF Splitter

[![Licenza](https://img.shields.io/badge/licenza-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Versione](https://img.shields.io/github/v/release/mtravascio/pdf_splitter)](https://github.com/mtravascio/pdf_splitter/releases/latest)
[![Piattaforme](https://img.shields.io/badge/piattaforme-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](https://github.com/mtravascio/pdf_splitter/releases/latest)

**PDF Splitter** è un'applicazione desktop multi-piattaforma sviluppata in Flutter/Dart che consente di dividere un file PDF in pagine singole, nominarle e organizzarle in directory specifiche basandosi su un file di input CSV. L'applicazione offre inoltre la possibilità di inviare i file PDF generati via email.

## Funzionalità Principali

- **Splitting di PDF basato su CSV**: Automatizza la divisione di file PDF di grandi dimensioni in documenti più piccoli e gestibili.
- **Ricerca e Validazione**: Esegue una ricerca testuale all'interno di ogni pagina per validare il contenuto prima di salvarlo.
- **Invio tramite Email**: Invia automaticamente i file PDF estratti a indirizzi email specificati nel file CSV, con supporto per Outlook su Windows e client di posta predefiniti su Linux e macOS.
- **Organizzazione Flessibile**: Crea una struttura di directory personalizzata per salvare i file generati, basandosi sulle informazioni fornite nel CSV.
- **Multi-piattaforma**: Supporta Windows, Linux e macOS, con pacchetti di installazione nativi per ciascun sistema operativo.
- **Interfaccia Utente Semplice**: Un'interfaccia intuitiva che guida l'utente nella selezione dei file e nell'avvio del processo.

## Flusso di Lavoro e Formato CSV

L'applicazione utilizza un file CSV per definire come il PDF di input debba essere processato. Ogni riga del file CSV corrisponde a un'operazione di splitting e deve contenere le seguenti colonne, separate da punto e virgola (`;`) o virgola (`,`):

| Colonna | Nome                | Descrizione                                                                                                                                                              |
| :------ | :------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #1      | **ID Pagina**       | Il numero di pagina da estrarre dal file PDF.                                                                                                                            |
| #2      | **Nome**            | Un nome o una stringa di testo da cercare nella pagina estratta per confermare che si tratti del documento corretto.                                                      |
| #3      | **Descrizione**     | Utilizzata come nome per il file PDF generato e come oggetto dell'email se viene abilitato l'invio.                                                                    |
| #4      | **Directory**       | La cartella principale in cui salvare il file estratto. Verrà creata all'interno della cartella `Documenti/pdf_splitter`.                                                   |
| #5      | **Sottodirectory**  | Una sottocartella, all'interno della directory principale, per un'ulteriore organizzazione.                                                                              |
| #6      | **Email**           | L'indirizzo email del destinatario a cui inviare il file PDF generato. Per specificare il mittente, inserire `from: indirizzo@email.com` nell'intestazione di questa colonna. |

## Installazione

È possibile scaricare l'ultima versione dell'applicazione per il proprio sistema operativo dalla pagina [**Releases**](https://github.com/mtravascio/pdf_splitter/releases/latest). Sono disponibili i seguenti formati:

- **Windows**: `.msix`,`.exe`,`.zip`
- **Linux**: `.rpm`, `.deb`, `.flatpak`,`.zip`
- **macOS**: `.dmg`

## Dipendenze Principali

Il progetto si basa su un ecosistema di pacchetti Dart e Flutter di alta qualità, tra cui:

- **[syncfusion_flutter_pdf](https://pub.dev/packages/syncfusion_flutter_pdf)**: Per la manipolazione e l'estrazione di pagine da documenti PDF.
- **[csv](https://pub.dev/packages/csv)**: Per la lettura e l'analisi di file CSV.
- **[get](https://pub.dev/packages/get)**: Per la gestione dello stato e delle dipendenze in modo semplice e reattivo.
- **[file_picker](https://pub.dev/packages/file_picker)**: Per consentire all'utente di selezionare i file PDF e CSV dal proprio sistema.
- **[desktop_window](https://pub.dev/packages/desktop_window)**: Per la gestione delle dimensioni e delle proprietà della finestra dell'applicazione desktop.

## Contribuire

I contributi sono sempre i benvenuti! Se desideri migliorare il progetto, sei invitato a creare una fork del repository, apportare le tue modifiche e inviare una pull request.

## Licenza

Questo progetto è rilasciato sotto la [Licenza MIT](https://opensource.org/licenses/MIT).
