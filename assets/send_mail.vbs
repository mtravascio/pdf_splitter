Option Explicit

Dim FromAddress, ToAddress, CcAddress, MessageSubject, MessageBody, AttachmentPath
Dim ol, newMail
Const olMailItem = 0

' Inizializza le variabili
FromAddress = ""
ToAddress = ""
CcAddress = ""
MessageSubject = "Nessun Oggetto"
MessageBody = "Messaggio vuoto."
AttachmentPath = ""

' Analizza gli argomenti passati
Call ParseArguments()

' Controllo: il campo -to è obbligatorio
If ToAddress = "" Then
    MsgBox "Errore: Specificare almeno un destinatario con '-to'!", vbCritical, "Errore"
    WScript.Quit
End If

' Crea l'oggetto Outlook e la nuova email
Set ol = WScript.CreateObject("Outlook.Application")
Set newMail = ol.CreateItem(olMailItem)

' Recupera la firma predefinita (se presente)
Dim signature
newMail.Display ' Necessario per caricare la firma
signature = newMail.HtmlBody

' Imposta i dettagli della mail
newMail.Subject = MessageSubject
newMail.HtmlBody = MessageBody & "<br><br>" & signature
newMail.To = ToAddress
If CcAddress <> "" Then newMail.Cc = CcAddress

' Imposta il mittente se specificato
If FromAddress <> "" Then
    On Error Resume Next
    Set newMail.SendUsingAccount = GetOutlookAccount(FromAddress)
    If Err.Number <> 0 Then
        MsgBox "Errore: Impossibile impostare il mittente su '" & FromAddress & "'. Verifica che l'account esista in Outlook e che tu abbia i permessi.", vbExclamation, "Errore"
        Err.Clear
    End If
    On Error GoTo 0
End If

' Se è stato fornito un allegato, lo aggiunge
If AttachmentPath <> "" Then
    If FileExists(AttachmentPath) Then
        newMail.Attachments.Add AttachmentPath
    Else
        MsgBox "Errore: Il file allegato non esiste!" & vbCrLf & AttachmentPath, vbExclamation, "Errore"
    End If
End If

' Mostra la mail all'utente prima dell'invio
' newMail.Display ' Per mostrare la mail prima di inviarla
newMail.Send ' Per inviare direttamente

' Rilascia gli oggetti
Set newMail = Nothing
Set ol = Nothing

' ----------------------------------------------------------------------
' Funzione per rimuovere i caratteri '\' all'inizio e alla fine della stringa
' ----------------------------------------------------------------------
Function TrimSlashes(str)
    If Left(str, 1) = "\" Then
        str = Mid(str, 2)
    End If
    If Right(str, 1) = "\" Then
        str = Left(str, Len(str) - 1)
    End If
    TrimSlashes = str
End Function

' ----------------------------------------------------------------------
' Funzione per analizzare gli argomenti della riga di comando
' ----------------------------------------------------------------------
Sub ParseArguments()
    Dim i, arg, key, value, objArgs
    Set objArgs = WScript.Arguments
    Dim tempArg
    
    ' Ciclo sugli argomenti passati
    For i = 0 To objArgs.Count - 1
        tempArg = objArgs.Item(i)
        
        ' Se inizia con "-", è una chiave
        If Left(tempArg, 1) = "-" Then
            key = LCase(Mid(tempArg, 2)) ' Rimuove il "-"
            
            ' Verifica se c'è un valore successivo
            If i + 1 < objArgs.Count Then
                value = Trim(objArgs.Item(i + 1))
                
                ' Assegna il valore alla variabile corrispondente
                Select Case key
                    Case "from"
                        FromAddress = TrimSlashes(value)
                    Case "to"
                        ToAddress = TrimSlashes(value)
                    Case "cc"
                        CcAddress = TrimSlashes(value)
                    Case "subject"
                        MessageSubject = TrimSlashes(value)
                    Case "body"
                        MessageBody = TrimSlashes(value)
                    Case "attach"
                        AttachmentPath = TrimSlashes(value)
                End Select
            End If
        End If
    Next
End Sub

' ----------------------------------------------------------------------
' Funzione per ottenere l'account Outlook corrispondente a un indirizzo email
' ----------------------------------------------------------------------
Function GetOutlookAccount(email)
    Dim session, account
    Set session = ol.Session
    For Each account In session.Accounts
        If LCase(account.SmtpAddress) = LCase(email) Then
            Set GetOutlookAccount = account
            Exit Function
        End If
    Next
    Set GetOutlookAccount = Nothing
End Function

' ----------------------------------------------------------------------
' Funzione per verificare se un file esiste
' ----------------------------------------------------------------------
Function FileExists(FilePath)
    Dim objFSO
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    FileExists = objFSO.FileExists(FilePath)
    Set objFSO = Nothing
End Function

