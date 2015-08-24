#!/bin/bash

#################################################
# Script by Stefano Di Pede Ver. 1.1.2          #
# Email: stefano@dipede.it                      #
#                                               #
# Script per distro Debian / Ubuntu		#
# che imposta un backup settimanale		#
# dello spazio web di una lista di siti.        #
#                                               #
# Lo script, installa i software necessari      #
# come curlftpfs e rsync,  monta lo directory   #
# remote  ftp in locale e le sincronizza nelle  #
# directory scelta.			        #
# Crea un file backup.sh che viene inserito in	#
# un cron settimanale. 				#
# Se si vuole aggiungere altri domini,	 	#
# bisogna richiamare questo script		#                                     
#						#
#################################################


intro () {

	#	Presentazione e spiegazione dello script all'utente.

	echo -e "\nQuesto script raccoglie i dati ftp dei domini di cui decidi di eseguire il backup."
	echo -e "Lo script utilizza curlftps per accedere e montare lo spazio ftp dei domini indicati."
	echo -e "Verrà poi scelta una directory locale su cui eseguire la sincronizzazione dei contenuti dello spazio web di ciascun dominio mediante rsync."
	echo -e "Se non sono installati, verranno installati i seguenti programmi necessari all'esecuzione dello script: curlftpfs e rsync."
	echo -e "Sarà possibile aggiungere ulteriori domini, semplicemente richiamando questo script. \n"
	echo -e "N.B. Assicuratevi di avere sufficiente spazio libero per ospitare i dati dei siti di cui si effettua il backup e di avere a disposizione \ni dati di accesso ftp corretti dei domini di cui volete eseguire un backup. \n"
	
	echo -e "Procedere? (S/n)"
	
	read START

	case $START in

	S|s|Y|y|Sì|Si|Yes|yes)
		echo -e "Proseguo."
	;;

	N|n|No|no)
		echo -e "Esco."
		exit 1
	;;

	*)
		echo -e "Scelta non valida."
		intro
	;;

	esac
}


check_root () {

	#	Controllo se si è root.

	WHO=$(whoami);
	ROOT="root"
	CURL=$(dpkg -l |grep curlftpfs);

	if [ "$WHO" = "$ROOT" ]; then 

		echo "Sei root, possiamo installare lo script."

        else

	        echo "Devi essere 'root' per poter eseguire questo script."
	        exit 1

	fi

}


check_curlftp () {

	#       Controllo se è installato curlftpfs. Eventualmente lo installo.

	CURL=$(dpkg -l |grep curlftpfs);

	if [  ! -z "$CURL" ]; then

		echo "cURLftp installato, tutto Ok."

	else
		echo "cURLftp non installato, lo installo."
		apt-get update && apt-get install curlftpfs && echo -e "Fatto."

	fi

}


check_rsync () {

	#	Controllo se è installato rsync. Eventualmente lo installo.

        RSYNC=$(dpkg -l |grep rsync);

        if [  ! -z "$RSYNC" ]; then

        	echo "rsync installato, tutto Ok."

        else
                echo "rsync non installato, lo installo."
                apt-get update && apt-get install rsync && echo -e "Fatto."

        fi

}



check_dir () {

	#	Scelta della directory in cui verranno salvati i backup.	

	echo "Specificare il percorso completo in cui effettuare il backup (es. /home/backup/):"

	read DIR

	if [ -d "$DIR" ]; then
		
		echo -e "La procedura continuerà in questa directory: $DIR"
  
	else
	
		echo -e "La directory non esiste, la creo: $DIR"
		mkdir $DIR

	fi

}



initialize () {

	#	Inizializzazione del backup. Si sceglie il numero di domini da configurare e si inseriscono le rispettive credenziali.

	echo -e "Di quanti domini devi fare il backup? (1-99)"

        read NUMERODOMINI

	case $NUMERODOMINI in

	[1-9]|[1-9][0-9])
	
		echo -e "Verranno aggiunti $NUMERODOMINI di cui fare il backup."	
		echo -e "Assicurati che i dati inseriti siano corretti, altrimenti lo script fallirà."	

        	CONT=1

	        let NUMERODOMINI=NUMERODOMINI+1

	        while [  $CONT -lt $NUMERODOMINI ]; do

			echo -e "Inserisci il nome del dominio $CONT (senza www)"

                	read DOMAIN

	                echo -e "Inserisci l'username del dominio $CONT"
        	        read USER

                	echo -e "Inserisci la password del dominio $CONT"
	                read PASS

			#	Controllo se esistono già delle directory create per gli stessi domini.
		
			if [ ! -d "$DIR/$DOMAIN" ] && [ ! -d "/mnt/$DOMAIN" ]; then

			#	Le directory NON esistono.

				create
		
			else

			#	Le directory esistono.

				echo -e "Esiste già una directory chiamata $DOMAIN. Continuo in questa directory? (S)ì, proseguo, (n)o esco."
	
				read CONTINUE 

				case $CONTINUE in

			        S|s|Y|y|Sì|Si|Yes|yes)
                			echo -e "Proseguo."
					create_sync
		 	        ;;

			        N|n|No|no)
                			echo -e "Esco."
		        	        exit 1
	        		;;

			        *)
                			echo -e "Scelta non valida."
	                		initialize
        			;;

        			esac
			
			fi

			let CONT=CONT+1

		done
	;;


	*)
		echo -e "Scelta non valida."
		initialize
	;;

	esac

}

create () {

	# Funzione di creazione delle cartelle degli script del backup.

create_dir
create_sync

}


create_dir () {

	#	Crea le directory dei backup dei singoli domini.

	mkdir $DIR/$DOMAIN
        mkdir /mnt/$DOMAIN

}

create_sync () {

	#	Funzione che si connette con curlftpfs allo spazio ftp del dominio, e la monta in /mnt/.

	#	Controllo le credenziali, se sono corrette vado avanti, altrimenti, richiama l'inserimento dei dati.
	
        curlftpfs -o nonempty -o user=$USER:$PASS ftp.$DOMAIN /mnt/$DOMAIN || (echo "Dati non corretti. Dominio non aggiunto. Ricominciamo." &&  initialize;)

	#	Scrive il comando dell'rsynck nello script.

       	echo "rsync -arvHu --progress --delete --stats /mnt/$DOMAIN/ $DIR/$DOMAIN" >> $SCRIPT
	
}		



configure () {

	#	Funzione di controllo e configurazione iniziale del backup.

	SCRIPT="$DIR/rsync.sh"

	#	Controllo che non esistra già una versione dello script di backup.

	if [ ! -f "$SCRIPT" ]; then

		echo -e "Prima configurazione nel backup."

		initialize
		set_cron

	else

		echo -e "Il backup è stato già configurato in questa directory."
		EXTDOM=$(cat $SCRIPT |awk '{print$6}' |cut -f3 -d / );
		echo -e "Sono già configurati i backup per i seguenti domini: \n$EXTDOM"

		echo -e "Vuoi (A)ggiungere nuovi domini? Vuoi (R)esettare la configurazione del backup? Oppure (E)sci"
		read SCELTA

		case $SCELTA in

		A|a) 
			initialize
		   	set_cron
		;; 

		R|r) 
			rm -f $SCRIPT
		   	echo -e "Tutti i dati sui precedenti backup sono stati cancellati."
		   	initialize
		   	set_cron
		;;

		E|e) 	
			echo -e "Ok, esco."
			exit 1;
		;;


		*) 
			echo -e "Scelta non valida, scegli tra questi valorii (A/R/E)."
		   	configure
		;;

		esac


	fi


}


cron_day () {

	#	Si sceglie il giorno in cui eseguire il backup.
	
	echo -e "Quale giorno dell settimana vuoi schedulare il backup? \n(L)unedì, (Ma)rdetì, (Me)rcoledì, (G)iovedì, (V)enerdì, (S)abato, (D)omenica, (O)gni giorno."

	read DAY

	case $DAY in

	L|l)
		CRONDAY="1"
	;;

        Ma|MA|ma)
                CRONDAY="2"
        ;;

        Me|ME|me)
                CRONDAY="3"
        ;;

        G|g)
                CRONDAY="4"
        ;;

        V|v)
                CRONDAY="5"
        ;;

        S|s)
                CRONDAY="6"
        ;;

        D|d)
                CRONDAY="0"
        ;;

	O|o)
		CRONDAY="*"
	;;

	*)
		echo -e "Scelta non valida"
		cron_day
		
	esac

}

cron_hour () {

	#	Si sceglie l'ora in cui eseguire il backup.

        echo -e "A che ora vuoi schedulare il backup (Scegli solo l'ora, i minuti vengono scelti successivamente? (0-23), oppure (O)gni ora."

        read HOUR

        case $HOUR in

        [0-9]|1[0-9]|2[0-3])
                CRONHOUR="$HOUR"
        ;;

	O|o)
		CRONHOUR="*"
	;;

        *)
                echo -e "Scelta non valida"
                cron_hour
	;;

        esac

}


cron_minute () {

	#	Si sceglie il minuto in cui eseguire il backup.

        echo -e "Hai scelto $CRONHOUR come ora. A che minuto vuoi schedulare il backup? (0-59)."

        read MINUTE

        case $MINUTE in

        [0-9]|[1-5][0-9])
                CRONMINUTE="$MINUTE"
        ;;

        *)
                echo -e "Scelta non valida"
                cron_minute
        ;;

        esac

}


cron_email () {
	
	#	Si sceglie se e a quale email inviare le notifiche dei backup

	echo -e "Vuoi settare una mail per l'invio dei report dei backup? (S/n)"

	read SETMAIL

	case $SETMAIL in

        S|s|Y|y|Sì|Si|Yes|yes)
		echo -e "A quale email vuoi inviare i report? Inserire email completa (es. mario@gmail.com)"
		read MAIL
        	echo -e "Proseguo. I report verranno inviati a $MAIL"
                CRONMAIL="1> /dev/null 2>&1 | mail -s \"Report Esecuzione Site-Backup\" $MAIL"
        ;;

        N|n|No|no)
                echo -e "Ok, non verrà settata alcuna email per il report."
          	CRONMAIL="2&1>/dev/null"
        ;;

        *)
                echo -e "Scelta non valida."
                cron_email
        ;;
	
	esac

}


set_cron () {

	#	Imposto il backup con la scelta dell'utente delle singole funzioni.	

	CRON="/etc/cron.d/mybackup"
	UMOUNT="&& umount -a -t fuse"
	
	echo -e "Quasi finito. Ora bisogna configurare l'esecuzione automatica."

	cron_day
	cron_hour
	cron_minute
	cron_email

	echo -e "A quale email vuoi inviare il report dei backup?"

	#	Salvo le scelte dell'utente nel file /etc/cron.d/mybackup
	
	crontab -l | { cat; echo "$CRONMINUTE $CRONHOUR * * $CRONDAY $SCRIPT $UMOUNT $CRONMAIL"; } | crontab -
	#	echo "$CRONMINUTE $CRONHOUR * * $CRONDAY $SCRIPT $UMOUNT $CRONMAIL" > $CRON

	#	Aggiungere umount alla fine?

	# 	Riavvio il servizio cron e stampa riepilogo schedulazione.

	chmod +x $CRON && chmod +x $SCRIPT && /etc/init.d/cron stop && /etc/init.d/cron start && \
	echo -e "Sistema di backup installato con successo!"
	echo -e "\nIl primo backup è schedulato per il giorno $CRONDAY della settimana alle ore $CRONHOUR e $CRONMINUTE. (*) Sta per (tutti/e)."
	echo -e "\nPer lanciare prima il backup, esegui $SCRIPT \n"

}


intro
check_root
check_curlftp
check_rsync
check_dir
configure
