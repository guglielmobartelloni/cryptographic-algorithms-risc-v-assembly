# Algoritmi di cifratura in assembly RISC-V

Progetto didattico che implementa cinque trasformazioni di stringhe in assembly RISC-V. Il programma permette di concatenarle, mostra i risultati intermedi e applica le operazioni inverse per ricostruire il testo iniziale.

Il codice è contenuto in [`main.S`](main.S) ed è pensato per il simulatore [Ripes](https://github.com/mortbopet/Ripes). La versione indicata nella documentazione originale è **v2.1.0**; la compatibilità con altre versioni non è stata verificata.

> **Solo per scopi didattici.** Queste trasformazioni non offrono le garanzie della crittografia moderna e non devono essere usate per proteggere dati sensibili. La “cifratura a blocchi” del progetto è una trasformazione additiva con chiave ripetuta, non un cifrario a blocchi moderno come AES.

## Indice

- [Avvio rapido](#avvio-rapido)
- [Configurazione](#configurazione)
- [Flusso del programma](#flusso-del-programma)
- [Algoritmi](#algoritmi)
- [Organizzazione della memoria](#organizzazione-della-memoria)
- [Routine di supporto](#routine-di-supporto)
- [Limiti e precauzioni](#limiti-e-precauzioni)

## Avvio rapido

1. Clona il repository:

   ```sh
   git clone https://github.com/guglielmobartelloni/cryptographic-algorithms-risc-v-assembly.git
   cd cryptographic-algorithms-risc-v-assembly
   ```

2. Avvia Ripes e carica `main.S` come sorgente assembly.
3. Usa una configurazione RISC-V a **32 bit**: il programma salva registri e indirizzi con istruzioni `sw` e `lw`.
4. Eventualmente modifica i parametri nella sezione `.data`, descritti sotto.
5. Assembla ed esegui il programma; consulta l'output delle chiamate di sistema del simulatore per leggere le stringhe stampate.

Il programma non richiede input interattivo: testo, sequenza e chiavi sono definiti nel sorgente. La stampa usa `ecall` con `a7 = 4`, secondo la convenzione del simulatore; il file non è un programma Linux direttamente eseguibile.

### Esempio predefinito

La configurazione presente nel repository applica il cifrario di Cesare con spostamento 20:

```asm
mycypher:    .string "A"
myplaintext: .string "AMO AssEMbLYa"
sostK:       .word 20
blocKey:     .string "FIER"
```

L'output atteso, ricavato dal codice ma **non verificato al simulatore**, è:

```text
AMO AssEMbLYa
UGI UmmYgvFSu
AMO AssEMbLYa
```

Le tre righe corrispondono al testo iniziale, al testo cifrato e al testo ricostruito.

## Configurazione

Modifica queste etichette all'inizio di `main.S`:

| Parametro | Ruolo | Valore predefinito |
| --- | --- | --- |
| `myplaintext` | Testo iniziale, terminato da byte nullo | `"AMO AssEMbLYa"` |
| `mycypher` | Sequenza di trasformazioni da applicare | `"A"` |
| `sostK` | Spostamento per il cifrario di Cesare | `20` |
| `blocKey` | Chiave ripetuta per la cifratura a blocchi | `"FIER"` |

Nonostante il nome, **`mycypher` contiene la sequenza di algoritmi, non il testo cifrato**.

### Codici degli algoritmi

| Codice | Trasformazione | Routine di cifratura | Routine di decifratura |
| --- | --- | --- | --- |
| `A` | Cesare | `cifraCesare` | `decifraCesare` |
| `B` | Cifratura a blocchi con chiave ripetuta | `cifraBlocchi` | `decifraBlocchi` |
| `C` | Codifica delle occorrenze | `cifraOccorrenze` | `decifraOccorrenze` |
| `D` | Sostituzione a dizionario | `dizionario` | `dizionario` |
| `E` | Inversione della stringa | `inversione` | `inversione` |

Per esempio:

```asm
mycypher: .string "ABDE"
```

applica Cesare, blocchi, dizionario e inversione, in quest'ordine. La decifratura percorre la sequenza al contrario e usa le operazioni inverse. È possibile ripetere gli algoritmi; considera però la crescita della stringa provocata da `C` e l'assenza di controlli sui buffer.

I caratteri diversi da `A`, `B`, `C`, `D`, `E` vengono ignorati: non è previsto un messaggio di errore.

## Flusso del programma

Il punto di ingresso `main`:

1. Copia `myplaintext` nell'area di lavoro indicata da `plain`.
2. Azzera i byte della stringa originale tramite `resettaArray`.
3. Chiama `cifra`, che scorre `mycypher` da sinistra a destra.
4. Chiama `decifra`, che inverte **in memoria** `mycypher` e applica le operazioni inverse.
5. Raggiunge l'etichetta finale `end`.

`cifra` stampa il contenuto corrente prima di ogni trasformazione e una volta raggiunta la fine della sequenza. Per una sequenza valida e non vuota, `decifra` stampa il risultato dopo ogni operazione inversa, senza ristampare inizialmente il testo cifrato.

Schema concettuale, non codice eseguibile:

```text
 testo = copia del plaintext nell'area di lavoro

 per ogni codice nella sequenza:
     testo = applica la trasformazione associata al codice

 per ogni codice nella sequenza percorsa al contrario:
     testo = applica la trasformazione inversa associata al codice
```

## Algoritmi

### A — Cifrario di Cesare

Sposta soltanto le lettere ASCII, mantenendo separati gli intervalli `A–Z` e `a–z`. Numeri, spazi e punteggiatura rimangono invariati.

Indicando con `x` il codice del carattere, con `k` lo spostamento e con `base` il codice di `A` oppure di `a`, la trasformazione è:

```text
cifratura:   base + mod(x - base + k, 26)
decifratura: base + mod(x - base - k, 26)
```

Qui `mod` indica un resto normalizzato nell'intervallo `0–25`. Il codice lo calcola con `divisioneResto`, senza usare un'istruzione hardware di divisione.

- `isLettera` distingue cifre, maiuscole, minuscole e altri caratteri.
- `spostamentoCesare` e `spostamentoDecifraCesare` eseguono il calcolo.
- `cifraCesare` e `decifraCesare` ricevono l'indirizzo della stringa in `a0` e lo spostamento in `a1`, modificando il testo sul posto.

### B — Cifratura a blocchi con chiave ripetuta

Scorre il testo e la chiave contemporaneamente. Quando raggiunge il terminatore di `blocKey`, riparte dal primo carattere della chiave.

Con `p` codice del carattere del testo e `k` codice del carattere corrente della chiave:

```text
cifratura:   32 + mod((p - 32) + (k - 32), 96)
decifratura: 32 + mod((p - 32) - (k - 32), 96)
```

Per caratteri e chiave nell'intervallo ASCII `32–127`, il risultato resta nello stesso intervallo. Il valore `127` è DEL e non è un carattere stampabile: alcuni risultati possono quindi non essere leggibili nell'output.

La routine riceve l'indirizzo del testo in `a0` e quello della chiave in `a1`. Entrambe le operazioni modificano il testo sul posto e usano `divisioneResto` per il resto non negativo; la decifratura corregge una differenza negativa aggiungendo 96.

**La chiave deve essere non vuota:** con testo non vuoto e chiave vuota, il ciclo continua a ripristinare il puntatore alla chiave senza avanzare.

### C — Codifica delle occorrenze

Per ogni carattere distinto, nell'ordine della sua prima comparsa, scrive il carattere seguito dalle posizioni in cui compare. Le posizioni partono da **1** e sono separate da trattini; i gruppi sono separati da uno spazio.

Esempio:

```text
Testo:    banana
Codifica: b-1 a-2-4-6 n-3-5
```

Non viene conservato uno spazio finale dopo l'ultimo gruppo.

Schema della cifratura:

```text
visitati = insieme vuoto
risultato = sequenza vuota

per ogni carattere c del testo:
    se c non è in visitati:
        aggiungi c a visitati
        trova tutte le posizioni di c nel testo
        aggiungi il gruppo c-posizione1-posizione2-... al risultato

unisci i gruppi con uno spazio
```

La decifratura legge ogni carattere e converte le posizioni decimali in interi, quindi scrive il carattere nelle posizioni indicate.

Routine principali di supporto:

- `isPresenteOccorrenza`: controlla se un carattere è già stato elaborato.
- `generaPosOccorrenze`: costruisce l'array di posizioni e ne restituisce il numero di elementi.
- `appendChar` e `appendNum`: scrivono caratteri e rappresentazioni decimali.
- `parseInt`: converte le cifre di una posizione nel corrispondente intero.

La cifratura usa aree ausiliarie e ricopia il risultato nell'area di lavoro. **La stringa risultante può essere molto più lunga dell'originale**, soprattutto applicando più volte questa trasformazione.

### D — Sostituzione a dizionario

Sostituisce lettere e cifre con il corrispondente carattere in ordine inverso, cambiando anche il caso delle lettere:

| Input | Output |
| --- | --- |
| `a … z` | `Z … A` |
| `A … Z` | `z … a` |
| `0 … 9` | `9 … 0` |

Spazi, punteggiatura e altri caratteri restano invariati.

```text
minuscola: 'Z' - (carattere - 'a')
maiuscola: 'z' - (carattere - 'A')
cifra:     '9' - (carattere - '0')
```

La trasformazione è **involutiva**: applicandola due volte si ottiene il testo iniziale. Per questo cifratura e decifratura usano entrambe `dizionario`, con l'indirizzo della stringa in `a0`.

### E — Inversione della stringa

La routine `inversione` riceve l'indirizzo della stringa in `a0` e:

1. Inserisce nello stack ciascun byte, escluso il terminatore nullo.
2. Estrae i byte secondo la politica LIFO e li riscrive dall'inizio della stringa.

La trasformazione avviene sul posto e richiede spazio sullo stack proporzionale alla lunghezza del testo. Anche questa operazione è involutiva.

**L'implementazione presuppone una stringa non vuota**: il ciclo di estrazione non controlla il caso di zero caratteri prima di accedere allo stack.

## Organizzazione della memoria

Oltre alle stringhe nella sezione `.data`, il programma usa indirizzi numerici fissi, memorizzati in variabili `.word`:

| Etichetta | Indirizzo decimale | Utilizzo |
| --- | --- | --- |
| `ciphertext` | `40000` | Buffer ausiliario delle trasformazioni per occorrenze |
| `plain` | `60000` | Area di lavoro del testo |
| `addressPerNum` | `70000` | Buffer per convertire le posizioni da stringa a intero |
| `addressPosOccorrenze` | `80000` | Array di posizioni, memorizzate come word |
| `addressOccorrenze` | `90000` | Caratteri già elaborati dalla codifica delle occorrenze |

Questi valori sono **indirizzi, non dimensioni di buffer**. Le aree non sono riservate con direttive come `.space` e il programma non verifica i limiti delle scritture. Il corretto funzionamento dipende quindi anche dalla mappa di memoria del simulatore e dal contenuto iniziale delle aree utilizzate.

Le routine salvano sullo stack registri e indirizzi di ritorno secondo le proprie necessità. Si tratta di codice didattico autonomo: non va considerato automaticamente conforme a tutte le regole ABI per l'integrazione con altro codice.

## Routine di supporto

| Routine | Funzione |
| --- | --- |
| `copiaArray` | Copia la stringa da `a1` alla destinazione in `a0`, incluso il terminatore |
| `resettaArray` | Azzera i byte a partire da `a0` fino al primo byte già nullo |
| `isLettera` | Restituisce `0` per altri caratteri, `1` per cifre, `2` per maiuscole e `3` per minuscole |
| `divisioneResto` | Calcola per sottrazioni successive; restituisce il resto in `a0` e il quoziente in `a1` per operandi non negativi e divisore positivo |
| `molt` | Esegue la moltiplicazione per somme ripetute |
| `pow` | Calcola una potenza tramite moltiplicazioni ripetute |
| `numLength` | Calcola il numero di cifre decimali di un intero non negativo |
| `appendNum` | Scrive un numero in formato decimale a partire dall'indirizzo ricevuto |
| `parseInt` | Converte una stringa di cifre decimali in intero |
| `strlength` | Calcola la lunghezza di una stringa terminata da byte nullo |
| `stampaStringa` | Stampa la stringa in `a0` tramite `ecall` |

## Limiti e precauzioni

- **Testo ASCII:** il programma elabora byte, non caratteri Unicode. Accenti e altri caratteri UTF-8 non sono gestiti come singoli caratteri.
- **Stringhe terminate da zero:** un byte nullo indica la fine del testo e non può farne parte.
- **Input non vuoto:** evita sia un testo iniziale vuoto sia una sequenza `mycypher` vuota. `decifra` inverte sempre la sequenza e `inversione` non gestisce correttamente le stringhe vuote.
- **Chiave non vuota:** necessaria quando si usa `B`.
- **Nessun controllo delle dimensioni:** non è garantita una lunghezza massima sicura. La crescita dovuta a `C` può sovrapporre aree di memoria.
- **Pulizia parziale dei buffer:** `resettaArray` si ferma al primo byte nullo; non azzera un'area di dimensione prefissata e non equivale a una cancellazione sicura della memoria.
- **Nessuna validazione del formato delle occorrenze:** la decifratura si aspetta il formato generato dalla cifratura, non dati arbitrari o corrotti.
- **Aritmetica didattica:** divisione, moltiplicazione e potenza usano cicli; valori elevati possono rendere l'esecuzione lenta e non sono previsti controlli di overflow. Un divisore nullo in `divisioneResto` può provocare un ciclo infinito.
- **Stato modificato durante l'esecuzione:** il plaintext originale viene azzerato e `mycypher` viene invertita. Per ripetere un esperimento, ricarica il programma e reinizializza la memoria.

Il repository non include test automatici. Per una verifica manuale, prova prima ogni codice singolarmente e poi le combinazioni, controllando che l'ultima stringa stampata coincida con il testo iniziale. La procedura e gli esempi di questo README non sostituiscono una verifica nel simulatore.
