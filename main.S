.data
	newline:    .string      "\n" # Per poter andare a capo
	mycypher: .string "A"
	myplaintext: .string "AMO AssEMbLYa"
	sostK: .word 20
	blocKey: .string "FIER"
	asciizMin: .word 122
	asciiaMin: .word 97
	asciiaMai: .word 65
	asciizMai: .word 90

#parametri occorrenze
	addressOccorrenze: .word 90000
	ciphertext: .word 40000
	plain: .word 60000
	addressPerNum: .word 70000
	addressPosOccorrenze: .word 80000

.text

main:
	la a1, myplaintext
	lw a0, plain
	jal copiaArray

addi a0, a1, 0
	jal resettaArray
	lw a0, plain
		
	la a1, mycypher
	
jal cifra
	la a1, mycypher
	jal decifra
  	j end

cifra: #a0 myplaintext, a1 -> mycipher
	addi sp, sp, -16
	sw s3, 12(sp)
	sw s2, 8(sp)
	sw s1, 4(sp)
	sw ra, 0(sp)

	addi s1, a1, 0 #indirizzo mycipher
	addi s1, s1, -1
	cicloCifratura:

		jal stampaStringa
		addi sp,sp,-4
		sw a0,0(sp)
		la a0, newline
		li a7, 4
		ecall
		lw a0,0(sp)
		addi sp,sp,4

		addi s1, s1, 1
		lb s2, 0(s1) #carico indirizzo
		beq s2, zero, endCifra
		li s3, 65
		beq s2, s3, doCifraSostituzione
		addi s3, s3, 1
		beq s2, s3, doCifraBlocchi
		addi s3, s3, 1
		beq s2, s3, doCifrarioOccorrenze
		addi s3, s3, 1
		beq s2, s3, doCifraDizionario
		addi s3, s3, 1
		beq s2, s3, doInversione
		j cicloCifratura

		doCifraSostituzione:
			addi sp, sp, -4
			sw a1, 0(sp)
			lw a1, sostK
			jal cifraCesare
			lw a1, 0(sp)
			addi sp, sp, 4
			j cicloCifratura

		doCifraBlocchi:
			addi sp, sp, -4
			sw a1, 0(sp)
			la a1, blocKey
			jal cifraBlocchi
			lw a1, 0(sp)
			addi sp, sp, 4
			j cicloCifratura

		doCifrarioOccorrenze:
			jal cifraOccorrenze
			j cicloCifratura

		doCifraDizionario:
			jal dizionario
			j cicloCifratura

		doInversione:
			jal inversione
			j cicloCifratura

endCifra:
	lw s3, 12(sp)
	lw s2, 8(sp)
	lw s1, 4(sp)
	lw ra, 0(sp)
	addi sp, sp, 16
	jr ra


decifra:
	addi sp, sp, -16
	sw s3, 12(sp)
	sw s2, 8(sp)
	sw s1, 4(sp)
	sw ra, 0(sp)

	addi sp, sp, -4
	sw a0, 0(sp)

	addi a0, a1, 0 #indirizzo di mycypher
	jal inversione
	addi a1, a0, 0 #inserisco l'indirizzo del mycypher nuovamente in a1

	lw a0, 0(sp) #carico indirizzo myplaintext
	addi sp, sp,4

	addi s1, a1, 0
	addi s1, s1, -1

	li t1, 0 #carica costante che indica se siamo alla prima iterazione o meno
	cicloDecifratura:
	beq t1, zero, cicloInternoDec
	jal stampaStringa
	addi sp,sp,-4
	sw a0,0(sp)
	la a0, newline
	li a7, 4
	ecall
	lw a0,0(sp)
	addi sp,sp,4

	cicloInternoDec:
		addi s1, s1, 1
		lb s2, 0(s1) #carico indirizzo
		beq s2, zero, endDecifra

		li s3, 65
		beq s2, s3, doDecifraSostituzione
		addi s3, s3, 1
		beq s2, s3, doDecifraBlocchi
		addi s3, s3, 1
		beq s2, s3, doDecifraOccorrenze
		addi s3, s3, 1
		beq s2, s3, doDecifraDizionario
		addi s3, s3, 1
		beq s2, s3, doInversioneDec
		j cicloInternoDec

		doDecifraSostituzione:
			addi sp, sp, -4
			sw a1, 0(sp)
			lw a1, sostK
			jal decifraCesare
			lw a1, 0(sp)
			addi sp, sp, 4
			li t1, 1
			j cicloDecifratura

		doDecifraBlocchi:
			addi sp, sp, -4
			sw a1, 0(sp)
			la a1, blocKey
			jal decifraBlocchi
			lw a1, 0(sp)
			addi sp, sp, 4
			li t1, 1
			j cicloDecifratura

		doDecifraOccorrenze:
			jal decifraOccorrenze
			li t1, 1
			j cicloDecifratura

		doDecifraDizionario:
			jal dizionario
			li t1, 1
			j cicloDecifratura

		doInversioneDec:
			jal inversione
			li t1, 1
			j cicloDecifratura

	endDecifra:
		lw s3, 12(sp)
		lw s2, 8(sp)
		lw s1, 4(sp)
		lw ra, 0(sp)
		addi sp, sp, 16
		jr ra


cifraCesare:
	#salvo i registri per convesnzione
	addi sp,sp,-4
	sw a0,0(sp)

	addi sp,sp,-8
	sw s1,0(sp)
	sw s2,4(sp)

	addi sp,sp,-4 # salvo il registro ra
	sw ra, 0(sp)

	add s2,a1,zero
	add s1,a0,zero
	addi s1, s1, -1 #? sufficiente incrementare s1 di 1 volta volta

	loopCifraCesare:
		addi s1, s1, 1
		lb t2, 0(s1)   # Carattere corrente
		beq t2, zero, fineCifraCesare			# Fine stringa

		#corpo; t2 possiede il carattere corrente
		add a0,t2,zero # inserisco il carattere come parametro della funzione
		jal isLettera # controllo che il carattere sia una lettera (se non e' una lettera ritorno 0 se e' una lettera maiuscola 2, 3 se e' una lettera minuscola)
		addi t3,zero,1
		ble a0,t3,loopCifraCesare # se non e' una lettera allora vado al carattere successivo

		add a2,a0,zero # metto il risultato della funzione in a3 come parametro dello spostamento
		add a1,s2,zero # metto in a1 il valore di sostk
		add a0,t2,zero # inserisco la lettera come parametro (in a1 e' presente sostk)
		jal spostamentoCesare # eseguo lo spostamento in a0 lettera, a1 sostk, a3 se e' maiuscola o minuscola

		#riprendo il riferrimento alla lettera in s1
		#Metto la lettera spostata nella sua posizione
		sb a0,0(s1)
		j loopCifraCesare

	fineCifraCesare:
		# Riprendo i valori di originali di ra
		lw ra, 0(sp)
		addi sp,sp,4
		#ripristino i valori
		lw s1,0(sp)
		lw s2,4(sp)
		addi sp,sp,8
		
		lw a0,0(sp)
		addi sp,sp,4

		jr ra

decifraCesare:

	#salvo i registri per convesnzione
	addi sp,sp,-4
	sw a0,0(sp)

	addi sp,sp,-8
	sw s1,0(sp)
	sw s2,4(sp)

	addi sp,sp,-4 # salvo il registro ra
	sw ra, 0(sp)

	add s2,a1,zero
	add s1,a0,zero
	addi s1, s1, -1 #? sufficiente incrementare s1 di 1 volta volta

	loopDecifraCesare:
		addi s1, s1, 1
		lb t2, 0(s1)   # Carattere corrente
		beq t2, zero, fineDecifraCesare			# Fine stringa

		#corpo; t2 possiede il carattere corrente
		add a0,t2,zero # inserisco il carattere come parametro della funzione
		jal isLettera # controllo che il carattere sia una lettera (se non e' una lettera ritorno 0 se e' una lettera maiuscola 2, 3 se e' una lettera minuscola)
		addi t3,zero,1
		ble a0,t3,loopDecifraCesare # se non e' una lettera allora vado al carattere successivo (a0<=1)

		add a2,a0,zero # metto il risultato della funzione in a3 come parametro dello spostamento
		add a1,s2,zero # metto in a1 il valore di sostk
		add a0,t2,zero # inserisco la lettera come parametro (in a1 e' presente sostk)
		jal spostamentoDecifraCesare # eseguo lo spostamento in a0 lettera, a1 sostk, a3 se e' maiuscola o minuscola

		#riprendo il riferrimento alla lettera in s1
		#Metto la lettera spostata nella sua posizione
		sb a0,0(s1)
		j loopDecifraCesare

	fineDecifraCesare:
		# Riprendo i valori di originali di ra
		lw ra, 0(sp)
		addi sp,sp,4
		#ripristino i valori
		lw s1,0(sp)
		lw s2,4(sp)
		addi sp,sp,8

		lw a0,0(sp)
		addi sp,sp,4
		jr ra

spostamentoCesare:
	addi sp,sp,-4
	sw ra,0(sp)
	li t0,2
	li t1,3
	#Controllo se e' minuscola o maiuscola
	beq a2,t0,maiuscola
	beq a2,t1,minuscola

	# se per caso non e' una lettera vado al carattere successivo
	j loopCifraCesare

	maiuscola:
		# l'operazione che devo eseguire e' (((lettera+sostK)-65)%26)+65)
		add a0,a0,a1
		addi a0,a0,-65

		addi a1,zero,26
		jal divisioneResto
		add a0,a0,zero # carico il resto in a0

		addi a0,a0,65
		j fineSpostamentoCesare

	minuscola:
		# l'operazione che devo eseguire e' (((lettera+sostK)-97)%26)+97)
		add a0,a0,a1
		addi a0,a0,-97

		addi a1,zero,26
		jal divisioneResto
		add a0,a0,zero # carico il resto in a0

		addi a0,a0,97
		j fineSpostamentoCesare

fineSpostamentoCesare:
  lw ra,0(sp)
  addi sp,sp,4
  jr ra

spostamentoDecifraCesare:
	addi sp,sp,-4
	sw ra,0(sp)
	li t0,2
	li t1,3
	#Controllo se e' minuscola o maiuscola
	beq a2,t0,maiuscolaDecifra
	beq a2,t1,minuscolaDecifra

	# se per caso non e' una lettera vado al carattere successivo
	j loopDecifraCesare

  maiuscolaDecifra:
    # l'operazione che devo eseguire e' (((lettera-sostK)-65)%26)+65)
    sub a0,a0,a1
    addi a0,a0,-65

    addi a1,zero,26
    jal divisioneResto
    add a0,a0,zero # carico il resto in a0

    addi a0,a0,65
    j fineSpostamentoDecifraCesare

  minuscolaDecifra:
    # l'operazione che devo eseguire e' (((lettera-sostK)-97)%26)+97)
    sub a0,a0,a1
    addi a0,a0,-97

    addi a1,zero,26
    jal divisioneResto
    add a0,a0,zero # carico il resto in a0

    addi a0,a0,97
    j fineSpostamentoDecifraCesare

fineSpostamentoDecifraCesare:
	lw ra,0(sp)
	addi sp,sp,4
	jr ra


isLettera:
	# Salvo i valori di s0,s1,s2,s3
	addi sp,sp,-16
	sw s0,12(sp)
	sw s1,8(sp)
	sw s2,4(sp)
	sw s3,0(sp)

	lw s0,asciiaMai
	lw s1,asciizMai
	lw s2,asciiaMin
	lw s3,asciizMin


	addi s1,s1,1 #aumento di 1 la lettera Z per fare il controllo
	slt t0,a0,s1 # if( lettera<=asciiZ && lettera >= asciiA) allora e' maiuscola
	addi s0,s0,-1
	slt t1,s0,a0

	and t0,t1,t0 # se le due condizioni sono soddisfatte allora e' maiusocla

	bne t0,zero,maiuscolaIsLettera
	# Controllo per i numeri 
	li t4,47  # Valore di / (prima dello 0)
	li t3,58 # Valore di (dopo il 9)
	slt t0,a0,t3 # if(carattere<= 9)
	slt t1,t4,a0 # if(0<= carattere)
	and t1,t1,t0
	bne t1,zero,numeroIsLettera # se le due condizioni non sono soddisfatte


	addi s3,s3,1
	slt t0,a0,s3 # if( lettera<=asciiz && lettera >= asciia) allora e' minuscola
	addi s2,s2,-1
	slt t1,s2,a0

	and t0,t1,t0 # se le due condizioni sono soddisfatte allora e' maiusocla

	bne t0,zero,minuscolaIsLettera

	# altrimenti non e' una letera
	addi a0,zero,0
	j fineIsLettera


	maiuscolaIsLettera:
		addi a0,zero,2
		j fineIsLettera


	minuscolaIsLettera:
		addi a0,zero,3
		j fineIsLettera

	numeroIsLettera:
		addi a0,zero,1
		j fineIsLettera

	fineIsLettera:
		# Riprendo i valori di t0,t1,t2,t3
		lw s0,12(sp)
		lw s1,8(sp)
		lw s2,4(sp)
		lw s3,0(sp)
		addi sp,sp,16
		jr ra


inversione:
	add t0, a0, zero	#indirizzo inizio stringa
	li t1, 0 #contatore
	inv:
		lb t2, 0(t0) #carico carattere in t2
		bne t2, zero, caricoStack
		add t0, a0, zero #imposto indirizzo iniziale della stringa
	loopInversione: 				#estraggo stringa carattere per carattere dalla stack
		lb t2, 0(sp) 	#prendo primo byte dallo stack
		addi sp, sp, 1	 #dealloco lo stack
		addi t1, t1, -1 	#contatore di iterazioni
		sb t2, 0(t0)
		addi t0, t0, 1 		#aggiorno indirizzo
		bne t1, zero, loopInversione	#se t1=0 ciclo si ferma
		jr ra

	caricoStack: #inserisco stringa carattere per carattere nello stack
		addi sp, sp, -1 #alloco lo stack
		addi t1, t1, 1
		sb t2, 0(sp)
		addi t0, t0, 1
		j inv


dizionario:
	# Salvo i dati che devo ripristinare
	addi sp,sp,-4
	sw a0,0(sp)
	addi sp,sp,-4
	sw ra,0(sp)
	addi sp,sp,-8
	sw s0,0(sp)
	sw s1,4(sp)
	
	# Inizializzo le variabili
	add s0,a0,zero
	addi s0,s0,-1

	loopDizionario:
		addi s0,s0,1
		lb s1,0(s0)
		beq s1,zero,fineDizionario

		add a0,zero,s1
		jal isLettera  #controllo di che carattere si tratta
		
		beq a0,zero,loopDizionario # se non e' una lettera

		add a1,a0,zero  # metto il risultato della valutazione del carattere
		add a0,zero,s1 # metto la lettera che devo mappare

		jal spostamentoDizionario

		sb a0,0(s0) # scrivo il contenuto
		j loopDizionario

	fineDizionario:
		# Ripristino i dati 
		lw s0,0(sp)
		lw s1,4(sp)
		addi sp,sp,8

		lw ra,0(sp)
		addi sp,sp,4

		lw a0,0(sp)
		addi sp,sp,4
		
		jr ra

spostamentoDizionario:
	# Inizializzo le variabili
	li t0,1
	li t1,2
	li t2,3

	# controlli
	beq a1,t0,numeroDizionario # se e' un numero
	beq a1,t1,maiuscolaDizionario # se e' una maiuscola
	beq a1,t2,minuscolaDizionario # se e' una minuscola

	j loopDizionario # per sicurezza


maiuscolaDizionario:
	# calcolo la distanza tra le lettera A e il carattere e lo sottraggo alla z
	addi a0,a0,-65
	li t0,122
	sub a0,t0,a0
	j fineSpostamentoDizionario

minuscolaDizionario:
	# calcolo la distanza tra le lettera a e il carattere e lo sottraggo alla Z
	addi a0,a0,-97
	li t0,90
	sub a0,t0,a0
	j fineSpostamentoDizionario

numeroDizionario:
	li t0,57 # valore di 9 ascii
	addi a0,a0,-48
	sub a0,t0,a0
	j fineSpostamentoDizionario

fineSpostamentoDizionario:
	jr ra




cifraBlocchi:
	addi sp, sp, -4
	sw ra, 0(sp)

	add t6, a0, zero #puntatore myplaintext
	add t1, a1, zero #puntatore blocKey

	loopBlocchi:
		lb t2, 0(t6) #carico carattere di myplaintext in t2
		beq t2, zero, endForBlocchi #termina il ciclo se myplaintext e' arrivato al carattere = 0 che indica la terminazione della stringa
		lb t3, 0(t1) #carico carattere di blocKey in t3
		beq t3, zero, resetCont #resetta il contatore se la stringa blocKey arriva al carattere = 0
		

		#add t2, t2, t3 cifro il carattere
		addi t2, t2, -32 #prima operazione sottraggo al carattere 32
		addi t3, t3, -32 #sottraggo al carattere del blocco 32

		add t2, t2, t3 #aggiungo il nuovo carattere t2 a t3
		
		blt t2, zero, calcolaRestoNegativo
		
		addi sp, sp, -8
		sw a1, 4(sp)
		sw a0, 0(sp) #salvo indirizzo di myplaintext e di blocKey nello stack

		addi a0, t2, 0 #carico in a0 il risultato parziale della crittografia

		li a1, 96

		jal divisioneResto

		addi t2, a0, 0 #carico resto nel carattere che verr? scritta
		

		addi t2, t2, 32 

		lw a1, 4(sp)
		lw a0, 0(sp)
		addi sp, sp, 8
		j scriviCarattereCifBlocchi


		calcolaRestoNegativo:
			addi t2, t2, 96
			addi t2, t2, 32

	
		scriviCarattereCifBlocchi:
			sb t2, 0(t6)
			addi t6, t6, 1 #scorro di un carattere le stringhe
			addi t1, t1, 1
			j loopBlocchi
		resetCont:
			add t1, a1, zero #scorro il blocKey dall'inizio
			j loopBlocchi
		endForBlocchi:
			lw ra, 0(sp)
			addi sp, sp, 4
			jr ra


decifraBlocchi:
	addi sp, sp, -4
	sw ra, 0(sp)

	add t6, a0, zero #puntatore myplaintext
	add t1, a1, zero #puntatore blocKey
	loopBlocchiDec:
		lb t2, 0(t6) #carico carattere criptato in t2
		beq t2, zero, endForBlocchiDec #termina il ciclo se myplaintext e' arrivato al carattere = 0 che indica la terminazione della stringa
		lb t3, 0(t1) #carico carattere di blocKey in t3
		beq t3, zero, resetContDec #resetta il contatore se la stringa blocKey arriva al carattere = 0
		

		#add t2, t2, t3 cifro il carattere
		addi t2, t2, -32 #prima operazione sottraggo al carattere 32
		addi t3, t3, -32 #sottraggo al carattere del blocco 32

		sub t2, t2, t3 #aggiungo il nuovo carattere t2 a t3
		
		blt t2, zero, calcolaRestoNegativoDec
		
		addi sp, sp, -8
		sw a1, 4(sp)
		sw a0, 0(sp) #salvo indirizzo di myplaintext e di blocKey nello stack

		addi a0, t2, 0 #carico in a0 il risultato parziale della crittografia

		li a1, 96

		jal divisioneResto

		addi t2, a0, 0 #carico resto nel carattere che verr? scritta
		

		addi t2, t2, 32 

		lw a1, 4(sp)
		lw a0, 0(sp)
		addi sp, sp, 8
		j scriviCarattereCifBlocchiDec


		calcolaRestoNegativoDec:
			addi t2, t2, 96
			addi t2, t2, 32

	
		scriviCarattereCifBlocchiDec:
			sb t2, 0(t6)
			addi t6, t6, 1 #scorro di un carattere le stringhe
			addi t1, t1, 1
			j loopBlocchiDec
		resetContDec:
			add t1, a1, zero #scorro il blocKey dall'inizio
			j loopBlocchiDec
		endForBlocchiDec:
			lw ra, 0(sp)
			addi sp, sp, 4
			jr ra


cifraOccorrenze: #a0 ->plaintext
	addi sp, sp, -4
	sw ra, 0(sp)	

	lw a1, addressOccorrenze #address occorrenze
	lw a2, ciphertext #address cipher
	lw a3, addressPosOccorrenze #address array posOccorrenze
	jal cifraOcc

	lw ra, 0(sp)
	addi sp, sp, 4

	jr ra

decifraOccorrenze: #a0->plaintext
	addi sp, sp, -4
	sw ra, 0(sp)	

	lw a1, addressPerNum #l'indirizzo della stringa che contiene il numero da formattare!
	lw a2, ciphertext #address cipher
	jal decifraOcc
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra


cifraOcc: #a0->indirizzo plaintext, a1 -> indirizzo occorrenze, a2-> indirizzo cipher, a3-> addressPosOccorrenze
	addi sp, sp, -20
	sw s5, 16(sp) #contatore di elementi in posOccorrenze
	sw s4, 12(sp) #s4 contiene indirizzo attuale posOccorrenze
	sw s2, 8(sp) #s2 contiene indirizzo corrente cipher
	sw s0, 4(sp) #s0 contiene indirizzo corrente plaintext
	sw ra, 0(sp)
	#salvare nello stack variabili s0,s2
	add s0, a0, zero #indirizo di plaintext
	lw s2, ciphertext #indirizzo cipher
	loopCifraOccorrenze:
		addi sp, sp, -8
		sw a0, 4(sp)
		sw a1, 0(sp)

		lw a0, addressOccorrenze #inserisco indirizzo di array occorrenze in a0
		lb a1, 0(s0) #carattere da ricercare
		
		beq a1, zero, endCicloCifraOcc
		
		jal isPresenteOccorrenza #controllo se occorrenza ? presente
		

		beq a0, zero, generaCifraOcc
	
		lw a1, 0(sp)		
		lw a0, 4(sp)
		addi sp, sp, 8 #ripristino stack		


		addi s0, s0, 1
		j loopCifraOccorrenze

	generaCifraOcc: 
		lw a0, 0(sp) #carico indirizzo Occorrenze presente nello stack
		addi sp, sp, 4
		jal appendChar #inserisco carattere nelle occorrenze gi? visualizzate
		
		sb a1, 0(s2) #inserisco primo carattere nel cipher
		addi s2, s2, 1 #aggiorno puntatore 
		
		add t5, a0, zero #in t5 c'? l'indirizzoOccorrenze

		lw a0, 0(sp) #carico in a0 il plaintext
		addi sp, sp, 4
		
		addi sp, sp, -8
		sw a0, 4(sp) #ricarico l'indirizzo del plaintext nella stack
		sw t5, 0(sp) #carico indirizzoOccorrenze

		#situazione stack:
		#in a0 c'? indirizzo iniziale plain text
		#in a1 c'? lettera da visualizzare
		#in a2 c'? vettore di posOccorrenze
		#questo ci serve per funzione generaPosOccorrenze

		#salvo a2 nello stack! e dopo funzione lo recupero
		addi sp, sp, -4
		sw a2, 0(sp)

		lw a2, addressPosOccorrenze #inserisco in a2 l'indirizzo di posOccorrenze

		jal generaPosOccorrenze #alla fine della funzione in a0 c'? l'indirizzo dell'array con le posizioni delle occorrenze di una lettera del plaintext

		lw a2, 0(sp)
		addi sp, sp, 4
	
		addi s5, a1, 0 #inizializzo contatore
		addi s4, a0, 0 #indirizzo posOccorrenze
		loopScriviOccorrenzePerChar:
			li t1, 45 #carattere trattino
			beq s5, zero, endLoopPerChar
			sb t1, 0(s2)
			lw t6, 0(s4) #prendo numero da scrivere

			#bisogna scomporre il numero carattere per carattere! 
			addi a0, s2, 1
			addi a1, t6, 0
		
			#writeNumToString ? la funzione che scompone il numero e lo scrive byte per byte sulla stringa cipher!
			jal appendNum #in a1 c'? indirizzo finale di s2, che va aggiornato!

			addi a0, a1, 0 #inserisco indirizzo finale di a1 in a0! (in a1 c'? l'indirizzo finale della stringa del cipher)

			addi s2, a0, 0 #aggiorno indirizzo finale di s2

			addi s2, s2, 1 #aggiorno indirizzo cypher
			addi s4, s4, 4 #agg indirizzo posOccorrenze
			addi s5, s5, -1
			j loopScriviOccorrenzePerChar
			
		endLoopPerChar:
			li t3, 32 #carattere spazio
			sb t3, 0(s2) #si scrive lo spazio nella stringa cipher
			addi s2,s2, 1
			
			lw a0, 4(sp)		
			lw a1, 0(sp)
			addi sp, sp, 8 #ripristino stack

			addi s0, s0, 1
			j loopCifraOccorrenze #si scrive prossimo carattere con rispettive occorrenze!
			
		endCicloCifraOcc:
			li t0, 0 #inserisco a mano terminazione stringa -> il ciphertext termina con uno spazio in pi?!
			sb t0, -1(s2) #setto ultimo carattere a 0!
					

			lw s5, 24(sp)
			lw s4, 20(sp)
			lw s2, 16(sp) #recupero valore di s2
			lw s0, 12(sp)	#recupero valore di s0
			lw ra, 8(sp)   #recupero valore di ra per tornare al main
			lw a0, 4(sp)
			lw a1, 0(sp)
			addi sp, sp, 28

			addi sp, sp,-8
			sw a1, 0(sp)
			sw ra, 4(sp)

			addi a1, a2, 0 #inserisco l'indirizzo del cipher in a1

			jal copiaArray #ricopio a1 in a0

			lw a1, 0(sp)
			lw ra, 4(sp)
			addi sp, sp, 8
			
			#a0 -> cypher(indirizzo iniziale), a1 -> occorrenze, a2 -> cypher, a3 -> posOccorrenze

			addi sp, sp, -8
			sw a0, 0(sp)
			sw ra, 4(sp)

			addi a0, a1, 0 #inserisco indirizzo delle occorrenze per az
			
			jal resettaArray

			addi a0, a2, 0

			jal resettaArray


			addi a0, a3, 0

			jal resettaArray

			lw a0, 0(sp)
			lw ra, 4(sp)
			addi sp, sp, 8
			jr ra


copiaArray: #copia seconda stringa in prima stringa
	addi sp, sp, -12
	sw s3, 8(sp)
	sw s2, 4(sp)
	sw s1, 0(sp)
	addi s2, a0, 0 #indirizzo prima stringa
	addi s3, a1, 0 #seconda
	cicloRicopiatura:
		lb s1, 0(s3)
		beq s1, zero, endCicloRicopiatura
		sb s1, 0(s2)
		addi s2, s2, 1
		addi s3, s3, 1
		j cicloRicopiatura
	endCicloRicopiatura:
	li s1, 0 #fine stringa
	sb s1, 0(s2) #se seconda stringa ? pi? corta!!!

	lw s1, 0(sp)
	lw s2, 4(sp)
	lw s3, 8(sp)
	addi sp, sp, 12
	jr ra

resettaArray: #a0 -> array da resettare
	addi sp, sp, -12
	sw s1, 0(sp)
	sw s2, 4(sp)
	sw s3, 8(sp)

	addi s1, a0, 0 #indirizzo array
	li s3, 0 #fine stringa
	cicloResettaArray:
		lb s2, 0(s1)
		beq s2, zero, endCicloResettaArray
		sb s3, 0(s1)
		addi s1, s1, 1
		j cicloResettaArray
	endCicloResettaArray:
		lw s1, 0(sp)
		lw s2, 4(sp)
		lw s3, 8(sp)	
	addi sp, sp, 12
		jr ra


decifraOcc: #a0 -> indirizzo ciphertext, a1 -> array contenente gli interi delle posizioni, a2 -> array plaintext
	addi sp, sp, -12
	sw s1, 8(sp)
	sw s0, 4(sp) 	
	sw ra, 0(sp)

	li s0, 32 #carico carattere spazio in s0
	li s1, 45 #carico trattino in s1

	addi sp, sp, -4
	sw a0, 0(sp)

	addi a0, a2, 0
	jal resettaArray
	
	lw a0, 0(sp)
	addi sp, sp, 4


	addi t2, a0, -1 #carico in t2 indirizzo del ciphertext
	addi t4, a1, 0 #carico in t4 indirizzo di di a1 che contiene le stringhe relative alle posizioni di ciascuna lettera
	forDecifraOccorrenze:
		addi t2, t2, 1
		addi t4, a1, 0
		lb t6, 0(t2) #carico primo carattere
		addi t2, t2, 2 
		cicloCarattereSuccessivo:
			lb t5, 0(t2) #salto un carattere perch? so che troverei lo spazio!
			beq t5, s1, caricaByteInPos
			beq t5, zero, caricaByteInPos
			beq t5, s0, caricaByteInPos
			
			sb t5, 0(t4) #carico n-esimo carattere numerico
			addi t4, t4,1 #aggiorno indirizzo stringa che conterr? il numero
		
			addi t2, t2, 1 #aggiorno indirizzo di cipher
			j cicloCarattereSuccessivo
			
	caricaByteInPos:
			#in a1 c'? la stringa con il numero relativo alla posizione del carattere salvato in t6
			li t1, 0
			sb t1, 0(t4) #inserisco fine stringa, altrimenti rimane traccia dei numeri precedenti			

			addi sp, sp, -8
			sw a0, 4(sp)
			sw a1, 0(sp)

			addi a0, a1, 0 #inserisco in a0 l'indirizzo della stringa contenente il numero

			jal parseInt

			addi t1, t5, 0 #metto carattere n-esimo caricato in t1
			addi t5, a0, 0 #carico numero convertito in t5
			
			lw a0, 4(sp)
			lw a1, 0(sp)
			addi sp, sp, 8 #ripristino a0 e a1

			add t5, t5, a2 #in t5 c'? l'indirizzo finale dove verr? salvata la parola!
			addi t5, t5, -1 #diminuito di 1!

			sb t6, 0(t5)
			
			beq t1, s0, forDecifraOccorrenze #se carattere ? uguale allo spazio, allora carico i prossimi caratteri da inserire!
			beq t1, zero, endDecifraOccorrenze #se il carattere ? uguale a 0, allora decifratura ? conclusa 

			#finisco qui solo se sto ancora posizionando il carattere presente in t6

			addi t4, a1, 0 #ricarico indirizzo iniziale di  stringa che conterr? i numeri delle singole posizioni dei caratteri
			
			#reset stringa
			addi sp, sp, -4
			sw a0, 0(sp)

			addi a0, a1, 0
			jal resettaArray

			lw a0, 0(sp)
			addi sp, sp, 4


			addi t2, t2, 1 #scorro l'array del cipher di una posizione!


			j cicloCarattereSuccessivo



	endDecifraOccorrenze:
		#addi a0, a2, 0 array in posizione iniziale del plaintext

		addi sp, sp, -4
		sw a1, 0(sp)

		addi a1, a2, 0
		jal copiaArray
		lw a1, 0(sp)
		addi sp, sp, 4

		
		lw s1, 8(sp)
		lw s0, 4(sp) 	
		lw ra, 0(sp)
		
		addi sp, sp, 12
		
		jr ra


isPresenteOccorrenza: #a0 -> array, a1 -> carattere da verificarne la presenza nell'array
	add t0, a0, zero
	loopIsPresenteOcc:
		lb t2, 0(t0)
		addi t0, t0, 1
		beq a1, t2, returnIsPres
		bne t2, zero, loopIsPresenteOcc

		add a0, zero, zero
		jr ra
	returnIsPres:
		addi a0, zero, 1
		jr ra
	

generaPosOccorrenze:# a0 -> plaintext, a1 -> carattere, a2 -> array posOccorrenze
	addi t0, a2, 0 # -> indice plaintext 
	li t1, 1 # -> indice di posizione
	addi t2, a0, 0 # -> indirizzo dell'array
	#indirizzo dell'array che conterr? ad esempio: 256, dove ogni byte rappresenta la posizione dove nel plaintext si presenta il carattere a1
	forGenPosOcc:
		lb t3, 0(t2)
		beq t3, zero, fineCicloPos
		beq t3, a1, scriviIndicePos
		addi t2, t2, 1
		addi t1, t1, 1
		j forGenPosOcc
		
	scriviIndicePos:
		sw t1, 0(t0) #scrivo indice di posizione dell'occorrenza nell'array
		addi t2, t2, 1
		addi t1, t1, 1
		addi t0, t0, 4
		j forGenPosOcc
	
	fineCicloPos:
		addi a0, a2, 0 #ritorna numero di caratteri e l'array
		sub a1, t0, a2 #numero di elementi = (posizionearray - indice t0)/4 alla fine del ciclo
		srli a1, a1, 2
		jr ra


numLength:
	addi sp, sp, -4
	sw ra, 0(sp)
	
	li t5, 1
	loopDivisioni:
		
	li a1, 10 #divisore del resto!

		jal divisioneResto

		beq a1, zero, endNumLength

		addi a0, a1, 0 #inserisco quoziente in a0!

		addi t5, t5, 1
	
		j loopDivisioni

	endNumLength:
		addi a0, t5, 0
		lw ra, 0(sp)
		addi sp, sp, 4
		
		jr ra
		
appendChar:
	add t5, a0, zero
	li t0, 0															# Loop Counter

	conc_loop:
		add t1, t0, a0
		lb t2, 0(t1)												# Current charachter
		beq t2, zero, end_loopConc						# End of string
		addi t0, t0, 1
		j conc_loop

	end_loopConc:
		add t1, t0, a0
		sb a1, 0(t1) #appendCarattere
	
		add a0, t5, zero
		jr ra

pow: #a0 -> numero, a1 -> potenza!
	addi sp,sp, -4
	sw ra, 0(sp) #salvo ra!

	li t1, 1 #risultato in t1
	loopPow:
		beq a1, zero, endPow
		
		addi sp, sp, -8
		sw a1, 4(sp)
		sw a0, 0(sp)

		addi a1, a0, 0 #salvo in a1, il numero da moltiplicare a1 volte

		addi a0, t1, 0 #salvo in a0 il risultato parziale della potenza!

		jal molt #numero parziale * parametro a1
	
		addi t1, a0, 0 #salvo risultato parziale in t1!

		lw a1, 4(sp)
		lw a0, 0(sp)

		addi sp, sp, 8
		
		addi a1, a1, -1
		
		j loopPow
	endPow:
		addi a0, t1, 0 #salvo risultato in a0
		lw ra, 0(sp)
		addi sp, sp, 4
		jr ra

stampaArray:	#a0 -> array, a1 ->numero elementi array

	add t0, a0, zero
	add t1, a1, zero

	ciclaStamp:
		lb a0, 0(t0)
		li a7,1 
		ecall
		addi t0,t0, 1
		addi t1, t1, -1
		bgt t1, zero, ciclaStamp
		jr ra

appendNum: #a0 -> string, a1 -> numero da append
	addi sp, sp, -4
	sw ra, 0(sp)

	li t4, 0 #indice num Decine, unit?, ecc...

	addi t2, a0, 0 #indirizzo della stringa!

	addi sp, sp, -8
	
	sw a1, 4(sp)
	sw a0, 0(sp)

	addi a0, a1, 0 #inserisco in a0 numero
	
	jal numLength

	addi t6, a0, -1 #in t0 indice di potenza massima! => numLength -1

	lw a0, 0(sp)
	lw a1, 4(sp)
	addi sp, sp, 8
	#calcolaPotenza
	
	addi sp, sp, -8
	sw a1, 4(sp)
	sw a0, 0(sp)

	li a0, 10
	addi a1, t6, 0 #indice potenzaMassima

	jal pow

	addi t3, a0, 0 #potenzaSalvata in t3

	lw a1, 4(sp)
	lw a0, 0(sp)
	addi sp, sp, 8

	beq t6, zero, appendLastChar
	j dividNum
	calcolaPotenzaSucc:
		beq t6, zero, appendLastChar
		addi sp, sp, -8
		
		sw a1, 4(sp)
		sw a0, 0(sp)
	
		addi a0, t3, 0
		addi a1, zero, 10

		jal divisioneResto

		addi t3, a1, 0
	
		lw a1, 4(sp)
		lw a0, 0(sp)
		addi sp, sp, 8

	dividNum:
		addi sp, sp, -8
		sw a1, 4(sp)
		sw a0, 0(sp)

		addi a0, a1, 0 #inserisco numero parziale
		addi a1, t3, 0 #inserisco l'elemento potenza in t3

		jal divisioneResto

		addi t4, a1, 0 #carico in t4 il quoziente (corrisponde al numero pi? significativo!

		addi t4, t4, 48
		sb t4, 0(t2)

		#in a0 c'? potenza, in a1 c'? quoziente! -> ci serve per togliere 'la potenza' del numero! 3450 -> 3450 -300 -> 450 poi 450 - 400 = 50 e cos? via!
		addi t4, a0, 0 #salvo il resto in t4  

		lw a0, 0(sp)
		lw a1, 4(sp)
		addi sp, sp, 8
		
		addi t2, t2 , 1
		addi t6, t6, -1
		
		addi a1, t4, 0 #ripristino numero
		
		addi t4, zero, 0 #resetto elemento che conterr? carattere e conterr? il numero da sottrarre ad a1 per passare al prossimo numero da scrivere!
		j calcolaPotenzaSucc
		

	appendLastChar:
		addi a1, a1, 48
		sb a1, 0(t2)
		
		addi a1, t2, 0 #indirizzo finale
		
		lw ra, 0(sp)

		addi sp, sp, 4
		jr ra

parseInt: #a0 -> indirizzo stringa
	addi sp, sp, -4
	sw ra, 0(sp)
	addi t0, a0, 0 #carico indirizo di a0
	li t3, 0 #in t3 comparir? il numero finale!
	loopParseInt:
		lb t1, 0(t0)
		beq t1, zero, endParseInt #controllo se la stringa ? finita! 

		addi sp, sp, -8
		sw a0, 4(sp)
		sw t0, 0(sp)

		addi a0, t3, 0 #carico il numero per effettuare la moltiplicazione!
		li a1, 10
	
		jal molt
	
		addi t3, a0, 0 #carico il risultato dell'operazione in t3 che contiene risultato parziale!
				
		lw t0, 0(sp)
		lw a0, 4(sp)
		addi sp, sp, 8
		
		addi t1, t1, -48 #ricavo numero da Carattere!		
		add t3, t1, t3 #somma parziale del numero!
		addi t0, t0, 1 #aggiorno Posizione!
		
		j loopParseInt
		endParseInt:
			addi a0, t3, 0
			lw ra, 0(sp)
			addi sp,sp, 4
			jr ra


molt:
	beq a0, zero, returnZero	#controllo se a0==0, in tal caso non faccio calcoli superflui, dato che il risultato = 0!
	beq a1, zero, returnZero
	add t0, a0, zero #elemento che viene sommato (a1 volte)
	add a0, zero, zero #a0 resettato per partire da zero e poi sommare (a0) a1 volte
	loopMolt:
		add a0, a0, t0
		addi a1, a1, -1
		bne a1, zero, loopMolt

		jr ra	#fine ciclo
	returnZero:
		add a0, zero, zero
		jr ra


divisioneResto:		#nota -> entrambi input a 0 o a0 > a1 = 0 genera un loop infinito!  Il metodo ritorna il quoziente e il resto rispettivamente in a1 e a0
	add t0,zero,zero
	loopDivisioneResto:
		sub a0, a0, a1
		blt a0, zero, calcolaResto #sono arrivato a numero negativo, devo recuperare il resto
		addi t0,t0,1
		j loopDivisioneResto

	calcolaResto:
		add a0, a0, a1 #dal numero negativo recupero il resto sommando ad a0, a1
		blt a0,zero,calcolaResto # se e' ancora negativo
		add a1,t0,zero #metto il quoziente in a1
		jr ra

stampaStringa:
    # in a0 deve essere presente la stringa da stampare
    li a7, 4   # codice necessario all'ecall
    ecall
    jr ra

strlength:
	li t0, 0															
	strloop:
		add t1, t0, a0
		lb t2, 0(t1)												# Carattere corrente
		beq t2, zero, end_strlength		
		addi t0, t0, 1
		j strloop

	end_strlength:
		add a0, t0, zero
		jr ra


end:
