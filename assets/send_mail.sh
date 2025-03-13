#!/bin/bash

# Inizializza le variabili
FROM=""
TO=""
CC=""
SUBJECT="Nessun Oggetto"
BODY="Messaggio vuoto."
ATTACHMENT=""

# Funzione per analizzare gli argomenti della riga di comando
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -from)
                FROM="$2"
                shift 2
                ;;
            -to)
                TO="$2"
                shift 2
                ;;
            -cc)
                CC="$2"
                shift 2
                ;;
            -subject)
                SUBJECT="$2"
                shift 2
                ;;
            -body)
                BODY="$2"
                shift 2
                ;;
            -attach)
                ATTACHMENT="$2"
                shift 2
                ;;
            *)
                echo "Opzione sconosciuta: $1"
                exit 1
                ;;
        esac
    done
}

# Verifica se il destinatario è stato fornito
validate_input() {
    if [[ -z "$TO" ]]; then
        echo "Errore: Specificare almeno un destinatario con '-to'!"
        exit 1
    fi
}

# Funzione per inviare l'email
send_email() {
    if [[ -n "$ATTACHMENT" && -f "$ATTACHMENT" ]]; then
        echo -e "$BODY" | mailx -s "$SUBJECT" -a "$ATTACHMENT" ${CC:+-c "$CC"} ${FROM:+-r "$FROM"} "$TO"
    else
        echo -e "$BODY" | mailx -s "$SUBJECT" ${CC:+-c "$CC"} ${FROM:+-r "$FROM"} "$TO"
    fi

    if [[ $? -eq 0 ]]; then
        echo "Email inviata con successo!"
    else
        echo "Errore nell'invio dell'email!"
        exit 1
    fi
}

# Main
parse_arguments "$@"
validate_input
send_email
