*Progetto Algoritmi di Cifratura in RISCV*


# <a name="_vq3sawnykzk9"></a>Descrizione della soluzione adottata
In questo paragrafo, oltre a mostrare il relativo pseudocodice per ogni funzionalità che andremo a realizzare, verranno spiegate le nostre ipotesi di risoluzione per ogni singolo algoritmo che è stato implementato nel codice assembly.

**Versione Ripes**: v2.1.0
## <a name="_elzi9fe0eb0k"></a>Inversione
### <a name="_yrra9km5gffl"></a>Descrizione del metodo
Questa funzione si occupa di implementare la funzione di inversione di una stringa, più precisamente, data in input una stringa, ritorna la stessa stringa ma scritta in ordine inverso. La funzione agisce nel seguente modo:

Prende ogni lettera che compone la stringa e la salva all'interno dello stack. Questa operazione viene eseguita finché la stringa non è terminata. Successivamente vengono rimesse le lettere all'interno della stringa prendendole però in ordine inverso, sfruttando la politica dello stack LIFO (l'ultima lettera che è stata inserita sarà la prima ad essere immessa).
### <a name="_pl6i3egfw65"></a>Uso della memoria
Input: a0 → indirizzo della stringa

Output: a0 → indirizzo della stringa
Variabili temporanee:

- t0: contiene l’indirizzo iniziale della stringa
- t1: contiene il contatore del ciclo
- t2: contiene il singolo carattere

`  `Stack:

- Nello stack pointer, carico tutta la stringa carattere per carattere
- Dopo aver caricato la stringa carattere per carattere nello stack, vado a prelevare carattere per carattere dallo stack, ottenendo così la stringa inversa. (Per politica LIFO dello stack)
## <a name="_pk5jdi2okjkg"></a>Cifratura a Blocchi
### <a name="_x8ft4fsqdzmi"></a>Descrizione del metodo
Per la crittografia di questo algoritmo è necessario scorrere lettera per lettera ed applicare la seguente funzione di cifratura:

*{[(cod(bij)–32)+ (cod(keyj)–32)] % 96} + 32, 1 ≤ j ≤ k*

Quindi nell’algoritmo esiste un ciclo che scorre carattere per carattere ed effettua la somma della codifica del carattere del plaintext e del blocKey.
La stringa blocKey viene scansionata mentre si sta scansionando carattere per carattere la stringa plaintext. Non possiamo utilizzare lo stesso ciclo for e lo stesso indice per entrambi i cicli for, perché la stringa blocKey può essere più breve del plaintext. Quindi avremo un ciclo for esterno e un ciclo for interno: quando il carattere della stringa blocKey è uguale a zero (cioè la stringa è terminata), allora l’indice per il blocKey verrà ripristinato al valore iniziale (0). Il ciclo for esterno concluderà quando il carattere del plaintext scansionato è uguale a 0.
### <a name="_9w5ad051ki8p"></a>Pseudo codice
public char[] cifraBlocchi(char[] myplaintext, char[] blocKey){

`	`//In Assembly si sovrascrive direttamente il valore nel myplaintext
`	`char[] cipherText = new char[myplaintext.length];

`	`int j = 0;

for(int i = 0; cipherText[i] != 0; i++){

`		`if(blocKey[j] == 0){

`			`j = 0;

`		`}
`		`//In Assembly somma tra char -> somma tra codifiche!

`		`cipherText[i] = //applica formula scritta sopra

`		`j++;

}

return cipherText;

}

Per la decifratura, il procedimento sarà il medesimo, solamente che si utilizzerà la seguente formula:

*{[(cod(bij)–32) - (cod(keyj)–32)] % 96} + 32, 1 ≤ j ≤ k*

Dove al posto del + in mezzo alle due codifiche dei caratteri, vi si inserisce il -.
### <a name="_gm34r0i9aufj"></a>Utilizzo della memoria
Input: a0 → indirizzo myplaintext, a1 → indirizzo blocKey

Variabili temporanee:

- t6 → indirizzo myplaintext
- t1 → indirizzo blocKey
- t2 → carattere attuale myplaintext, risultati parziali della codifica
- t3 →  carattere attuale blocKey

Stack Pointer: nello stack pointer viene inserito

- Il registro ra
- a0 e a1 prima della chiamata alla funzione divisioneResto

Viene inserito il contenuto di ra all’interno dello stack all’inizio della funzione perché all’interno del corpo di cifraBlocchi si utilizza un altro metodo (divisioneResto). Se non si procedesse in tal senso, il riferimento al chiamante del metodo cifraBlocchi si perderebbe, causando malfunzionamenti indesiderati.
## <a name="_f18kc3k3e12"></a>Cifra Occorrenze
### <a name="_436utj3x2oh0"></a>Descrizione del metodo
Il metodo cifra occorrenze si appoggia a diverse altre funzionalità:

- isPresenteOccorrenza: è una funzione che, presi in input due parametri (il primo la stringa, e il secondo il carattere), controlla se il secondo parametro è presente nella stringa. Se è presente ritorna 1, 0 altrimenti. Questo metodo ci serve per evitare di effettuare nuovamente la cifratura di un carattere più di una volta: prendiamo come esempio la stringa “esempio”: non si deve creare due volte nel ciphertext la stringa *e-1-3*, ma solo una volta: quindi ci serve tenere salvato da qualche parte i caratteri che sono stati già visitati dall’algoritmo; questi singoli caratteri vengono inseriti dentro ad una stringa di appoggio, che sarà il primo parametro inviato a questo metodo.
- generaPosOccorrenze: questo metodo serve per creare un array di interi, dove ogni intero rappresenta il numero della posizione dell’occorrenza per una determinata lettera: ad esempio se ho la stringa “banana”, durante la scansione della a, il generaPosOccorrenze genererà un array con i seguenti elementi: {2,4,6}. Questo ci serve per poter scrivere subito il ciphertext corrispondente per quella sequenza, cioè “a-2-4-6 ”
- appendNum: questo metodo serve a stampare il numero della posizione della lettera nel ciphertext. Non possiamo utilizzare direttamente una store word del numero che vogliamo scrivere nel ciphertext, ma dobbiamo trasformarlo in un numero rappresentabile in una stringa (in byte): quindi va scomposto byte per byte. La logica applicata a questo metodo è quella di trovare l’esponente più grande (in base 10) che rappresenta il numero: ad esempio 1300 → esponente=3 (10^3). (Per trovare l’esponente più grande in base dieci che rappresenta il numero, è sufficiente contare la lunghezza della stringa dove vi è salvato. Tale lunghezza diminuita di uno rappresenta l’esponente da noi desiderato). Poi divido il numero per 10^esponente. Nel quoziente ci sarà il numero di unità con peso 10^3, nel resto il numero rimanente (resto della divisione) → 1300/1000 = 1 resto 300. Per ottenere il carattere corrispondente a 1 ci aggiungo 48, e, dopo aver scritto uno nella stringa, allora andrò al ciclo successivo diminuendo la potenza di 1 e prendendo il resto della divisione precedente come nuovo dividendo. Iterazione successiva → 300 / 100 =  3 resto 0 (l’esponente viene diminuito di uno ad ogni iterazione). E così via. Si è scelto di adottare questo metodo per renderlo più generale possibile (anche se il plaintext iniziale è lungo 100 caratteri, se si adoperano 4 cifrature occorrenze, la lunghezza del ciphertext diventerà sicuramente più lunga di 100, raggiungendo anche l’ordine delle migliaia. Quindi si è preferito rendere la soluzione di questo problema più generale e più facilmente espandibile a versioni future che potranno supportare stringhe più lunghe di 100 caratteri)
- appendChar: questo metodo serve per inserire alla fine della stringa data come parametro, un carattere che viene passato alla funzione come secondo parametro.

Il metodo cifraOccorrenze è strutturato nel seguente modo:

Abbiamo un ciclo for esterno che scorre tutti gli elementi della stringa: ad ogni carattere che è stato prelevato si controlla se non è stato scansionato precedentemente. Se è stato già visionato, il carattere viene ignorato e si passa al successivo, altrimenti si aggiunge il carattere all’insieme dei caratteri già visitati. Adesso si effettua un altro scorrimento, cercando le occorrenze relative al carattere che è stato prelevato dal myplaintext: si genererà grazie al metodo *generaPosOccorrenze* un array di interi che conterrà le posizioni del carattere dove compare nel myplaintext.
A questo punto devo scrivere nel ciphertext la lettera esaminata con le rispettive posizioni, separate da un trattino. Però adesso c’è un problema: dobbiamo scomporre i numeri byte per byte e trasformarli in stringhe. Per fare ciò abbiamo il metodo di servizio appendNum che ha il compito, dato come parametro la stringa e il numero da inserire nella stringa, di inserire il numero direttamente in fondo alla stringa passata come parametro. Per convertire un numero in una stringa si applica il ragionamento visto in precedenza.

E questo ragionamento viene applicato ad ogni lettera distinta del plaintext.

Il metodo decifraOccorrenze, avrà un compito differente: dovrà leggere il carattere da scrivere sul testo cifrato e le rispettive posizioni, andando a trascrivere il carattere correntemente selezionato così come indicato.

Ora dobbiamo risolvere il problema di tipo opposto, ovvero le posizioni sono considerate come stringhe: quindi andranno convertite in numeri per far sì che si possa accedere alle posizioni giuste delle lettere esaminate nell’iterazione.
Per esplicitare il funzionamento di parseInt, forniremo un esempio:

*Es: numero → 132*

*Passo 1
`  `0\*10 = 0
`  `0 + 1 = 1*

*Passo 2
`  `1\* 10 = 10*

`  `*10 + 3 = 13*

*Passo 3
`  `13 \* 10 = 130
`  `130 + 2 = 132*

In pratica noi prendiamo la somme parziale (che ad inizio ha valore zero), e ad ogni iterazione la moltiplichiamo per 10, aggiungendoci poi il numero che avevamo selezionato. (Per ottenere il numero equivalente al carattere è sufficiente sottrarre 48 al singolo carattere).
### <a name="_40wayyrnyho1"></a>Pseudo codice
Questa è l’idea formulata prima di aver provato e riscontrato eventuali criticità. Potrebbero essere stati effettuati dei piccoli cambiamenti, ma l’idea di fondo che è stata implementata è molto simile.

public char[] cifraOccorrenze(char[] myplaintext){

`	`char[] occorrenze = new char[myplaintext.length];

`	`char[] ciphertext = new char[//Da definire!];

`	`int indexOcc = 0; z = 0; -> indice array cipher

for(int i = 0; myplaintext[i] != 0; i++){

`		`if(!isPresente(occorrenze)){

`			`occorrenze[indexOcc] = myplaintext[i];

`			`indexOcc++;

`			`//Due valori di ritorno:a0 -> array di occorrenze a1 -> nOccorrenze

`			`int nOccorrenze = getOccorrenze(myplaintext[i]);

`			`int[] occorrenze = getOccorrenze(myplaintext[i]);

ciphertext[z] = myplaintext[i];

`			`int indexOccorrenze = 0;

int z+=1;

`			`while(indexOccorrenze < nOccorrenze){

`				`ciphertext[z] = ‘-’;

ciphertext[z+1] = occorrenze[indexOccorrenze];

z+=2;

`				`indexOccorrenze++;

`			`}

`			`ciphertext[z] = ‘’;

`		`}

`	`}

`	`return ciphertext;

}
### <a name="_1yx3kewpujwu"></a>Utilizzo della memoria
In cifraOccorrenze abbiamo bisogno di 4 variabili che non devono essere modificate dai metodi chiamati all’interno di cifraOcc che sono:

- s0 →  che contiene l’indirizzo corrente del plaintext che viene aumentato di uno ogni qualvolta termina la scrittura del corrispondente carattere selezionato o ad ogni carattere scartato perché già visitato
- s2 → che contiene l’indirizzo corrente del cipher che viene costantemente aggiornato in base agli inserimenti fatti, per consentire di creare la stringa finale di criptazione come  una concatenazione di sequenze di questo tipo:
  `	`<*character*>-<*pos1*>-<*pos2*>-...<*posN*><*spazio*>
- s4 → che contiene l’indirizzo dell’array della posizione delle occorrenze
- s5 → che contiene il numero di elementi dell’array di posOccorrenze

Il corpo del metodo è spezzato dalle seguenti etichette:

- loopCifraOccorrenze: rappresenta il ciclo esterno del cifraOccorrenze. In questo ciclo vengono scansionati i singoli elementi ad uno ad uno.
- generaCifraOcc: blocco di codice che ha il compito di creare l’array di interi contenente le posizioni delle occorrenze dei vari elementi e di aggiornare l’array che contiene i caratteri già visitati.
- loopScriviOccorrenzePerChar: questo blocco di codice ha il compito di scrivere tutte le occorrenze di ciascuna lettera.
- endLoopPerChar: terminate le occorrenze da scrivere, si scrive nel ciphertext lo spazio
- endCicloCifraOcc: in questa parte di codice, avviene il ripristino delle variabili *s* ai valori prima della chiamata del metodo (le variabili *s* non devono essere mai modificate al di fuori del main per convenzione) e si ripristina l’indirizzo *ra* che si era salvato nello stack per poter così ritornare al chiamante.

In decifraOccorrenze utilizziamo le seguenti variabili:

- s0 → carattere spazio
- s1 → carattere trattino
- t6 → primo carattere estratto per occorrenze
- t5 → carattere estratto all’interno del ciclcoCarattereSuccessivo
- t4 → indirizzo del numero che stiamo estraendo all’interno del ciclo(si passa la stringa carattere per carattere e i singoli byte che rappresentano le cifre dei numeri vengono salvate momentaneamente in un array di interi che, successivamente,verrà convertito in un numero)
- t2 → indirizzo corrente del ciphertext
- t1 → vi è salvato il carattere di fine stringa(0)

Label:

- decifraOcc → metodo principale di decifraOccorrenze
- forDecifraOccorrenze → ciclo esterno del decifra occorrenze che seleziona i caratteri presenti nel futuro plaintext.
- cicloCarattereSuccessivo → ha il compito di selezionare i singoli byte per poi raggrupparli nei numeri che rappresentano la posizione del carattere estratto nel forDecifraOccorrenze.
- caricaByteInPos → ha il compito di caricare il carattere selezionato nel forDecifraOccorrenze nella posizione trovata nel cicloCarattereSuccessivo(che, all’interno di questo blocco di codice verrà convertita da array di interi in un intero attraverso il metodo parseInt)
- endDecifraOccorrenze → dealloca lo stack e si conclude il metodo, inserendo in a0 la posizione dell’array utilizzato dove è memorizzata la stringa.


***Nota:*** abbiamo riscontrato dei problemi nella allocazione delle variabili: nell’ambiente di sviluppo Ripes abbiamo visto che se si crea una variabile .string nella sezione .data, a quella stringa viene allocato un determinato spazio. Il metodo cifra occorrenze genera sempre una stringa più lunga rispetto a quella iniziale: questo può creare dei problemi al programma in quanto, durante la fase di cifratura e decifratura vi è la possibilità che vengano letti caratteri non desiderati. Quindi si è deciso di ricopiare l’intera stringa del plaintext in una posizione arbitraria, da noi fissata.
Inoltre, in un secondo momento, ci siamo accorti che alcuni array di servizio utilizzati nel cifraOccorrenze rimanevano “Sporchi” da precedenti cifrature delle occorrenze: abbiamo deciso quindi di implementare una funzione che ripulisca gli array.
## <a name="_bwa30ahe3r98"></a>CifraCesare
Questo metodo si occupa di traslare le lettere del plaintext di sostK posizioni.  In particolare il metodo estrarrà ogni lettera dal plaintext e dopo aver controllato che essa sia effettivamente una lettera eseguirà lo spostamento richiesto.

Il metodo cifraCesare si compone di due sottoprogrammi principali:  il primo serve per controllare che un carattere estratto sia un numero oppure una lettera maiuscola/minuscola, il secondo si occupa di spostare il carattere della quantità indicata dalla variabile sostK.

Qui sotto verranno spiegati i metodi più nel dettaglio:

- isLettera(lettera):  restituisce l'esito del controllo sulla lettera data come parametro. 1 se è un numero, due se è una lettera maiuscola, 3 se è una lettera minuscola e 0 altrimenti. I controlli che vengono eseguiti sulla lettera sono dei semplici controlli di range secondo la tabella ASCII.
- spostamentoCesare(lettera,sostK,isLettera): questo è il metodo fondamentale dell'algoritmo, che data in input una lettera, si occupa di spostarla della quantità indicata da sostK, dato che questo spostamento cambia a seconda che la lettera sia maiuscola e minuscola, il metodo deve sapere la lettera è maiuscola o minuscola  questa informazione è infatti contenuta nel terzo parametro. L'operazione di spostamento si può riassumere come segue: (((lettera+sostK)-ASCII(a))%grandezzaAlfabeto)+ASCII(a))

Dove lettera è la lettera che deve essere spostata.

sostK è lo spostamento da applicare.

ASCII(a)  è il codice ASCII della lettera ‘a’ maiuscola o minuscola a seconda del caso

grandezzaAlfabeto è la quantità di lettere che è presente nell' alfabeto Nel nostro caso 26.

### <a name="_nqjcyhaectcw"></a>Uso della memoria
I registri di memoria che sono utilizzate all’interno del metodo principale *dizionario* sono:

- t2: dove viene inserito il carattere corrente
- s2: sostK
- s1: dove è presente il plaintext

All’interno del metodo *spostamentoCesare* sono presenti due variabili di appoggio t0, t1 che contengono rispettivamente  2, 3 che servono per il controllo con il valore che ritorna *isLettera* che quindi indica di che tipo di carattere si tratta.

Tutte le variabili a0, a1, ra, s0, s1 vengono salvate nello stack all’inizio del metodo per essere poi ripristinati alla fine.



## <a name="_tx1uu3s935ad"></a>Dizionario
Questo è un algoritmo simile a cifraCesare, infatti si può dire che il suo funzionamento è analogo, avendo però un sostK fisso e considerando anche i numeri. L'algoritmo scorre ogni carattere del plaintext, controlla che sia una lettera oppure un numero e procede allo spostamento. Si compone di due metodi principali isLettera  e spostamentoDizionario. isLettera è lo stesso metodo utilizzato nel cifraCesare, il secondo invece è utilizzato per rendere una lettera minuscola in maiuscola ( o viceversa) prendendola con l'alfabeto inverso, oppure la sottrazione del codice ASCII del 9 al numero. In particolare ecco la descrizione del metodo:

- spostamentoDizionario( lettera, isLettera): il metodo, a seconda dei casi (maiuscola o minuscola) agisce diversamente, l'operazione di spostamento può essere riassunta come segue: ASCII(Z)-(lettera-ASCII(a)) *//per le lettere minuscole*

**Nota**: non è presente un metodo di decifratura in quanto questa è analoga alla cifratura.
### <a name="_wqr0oqfn8e5q"></a>Uso della memoria
I registri di memoria che sono utilizzate all’interno del metodo principale *dizionario* sono:

- s0: dove viene inserito l’indirizzo della stringa
- s1: dove viene inserito il carattere corrente
- a0: che inizialmente contiene l’indirizzo della stringa e poi viene sovrascritto, dopo aver salvato il valore, con la lettera corrente per eseguire *isLettera*

All’interno del metodo *spostamentoDizionario* sono presenti tre variabili di appoggio t0, t1, t3 che contengono rispettivamente 1, 2, 3 che servono per il controllo con il valore che ritorna *isLettera* che quindi indica di che tipo di carattere si tratta.

Tutte le variabili a0, ra, s0, s1 vengono salvate nello stack all’inizio del metodo per essere poi ripristinati alla fine.
## <a name="_ddq8y8ywf12m"></a>Metodo Main
### <a name="_gfi1bt81no7e"></a>Struttura
- mychyper: stringa che conterrà il testo finale (abbiamo usato un indirizzo manuale per evitare problemi riguardo alla sovrapposizione di altri elementi in memoria).
- myplaintext: stringa che contiene il testo in chiaro.
- sostk: parametro utilizzato per la cifratura a blocchi.

main(){

`	`cifra(myplaintext,mycypher);

`	`decifra(myplaintext,mycypher);

}

public void cifra(char[] myplaintext, char[] mycypher){

`	`for(char carattere : mychyper){

`		`if(carattere == ‘A’)

`			`cifraCesare(myplaintext,sostk);

`		`if(carattere == ‘B’)

`			`cifraBlocchi(myplaintext,sostk);

`		`if(carattere == ‘C’)

`			`cifraOccorrenze(myplaintext,sostk);

`		`if(carattere == ‘D’)

`			`cifraDizionario(myplaintext,sostk);

`		`if(carattere == ‘E’)

`			`inversione(myplaintext,sostk);

`	`}

`	`stampa(chyperText);

for(char carattere : inversione(mychper)){

`		`if(carattere == ‘A’)

`			`decifraCesare(myplaintext,sostk);

`		`if(carattere == ‘B’)

`			`decifraBlocchi(myplaintext,sostk);

`		`if(carattere == ‘C’)

`			`decifraOccorrenze(myplaintext,sostk);

`		`if(carattere == ‘D’)

`			`decifraDizionario(myplaintext,sostk);

`		`if(carattere == ‘E’)

`			`inversione(myplaintext,sostk);

`	`}

}

