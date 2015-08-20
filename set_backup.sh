#!/bin/bash

#################################################
# Script by Stefano Di Pede Ver. 1.1            #
# Email: stefano@dipede.it                      #
#                                               #
# Script che imposta un backup settimanale	#
# dello spazio web di una lista di siti.        #
#                                               #
# Lo script, installa i software necessari      #
# come curlfts e rsync,  monta lo directory     #
# remote  ftp in locale e le sincronizza nelle  #
# directory scelta.			        #
# Crea un file backup.sh che viene inserito in	#
# un cron settimanale. 				#
# Se si vuole aggiungere altri domini,	 	#
# bisogna richiamare questo script		#                                     
#						#
#################################################


intro () {

	echo -e "\nQuesto script raccoglie i dati ftp dei domini di cui decidi di eseguire il backup."
	echo -e "Lo script utilizza curlftps per accedere e montare lo spazio ftp dei domini indicati."
	echo -e "Verrà poi scelta una directory locale su cui eseguire la sincronizzazione dei contenuti dello spazio wen di ciascun dominio mediante rsync."
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

	WHO=(`whoami`)
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

	CURL=$(dpkg -l |grep curlftpfs);

		if [  ! -z "$CURL" ]; then

			echo "cURLftp installato, tutto Ok."

		else
			echo "cURLftp non installato, lo installo."
			apt-get update && apt-get install curlftpfs && echo -e "Fatto."

		fi

}


check_rsync () {

        RSYNC=$(dpkg -l |grep rsync);

                if [  ! -z "$RSYNC" ]; then

                        echo "rsync installato, tutto Ok."

                else
                        echo "rsync non installato, lo installo."
                        apt-get update && apt-get install rsync && echo -e "Fatto."

                fi

}



check_dir () {

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

	echo -e "Di quanti domini devi fare il backup?"

        read NUMERODOMINI

        CONT=1

        let NUMERODOMINI=NUMERODOMINI+1

        while [  $CONT -lt $NUMERODOMINI ]; do

		echo -e "Inserisci il nome del dominio $CONT (senza www)"

                read DOMAIN

                echo -e "Inserisci l'username del dominio $CONT"
                read USER

                echo -e "Inserisci la password del dominio $CONT"
                read PASS

		# Aggiungere check directory o sito esistente
		
		if [ ! -d "$DIR/$DOMAIN" ] && [ ! -d "/mnt/$DOMAIN" ]; then

			configure
		
		else

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

}

create () {

create_dir
create_sync

}


create_dir () {

	mkdir $DIR/$DOMAIN
        mkdir /mnt/$DOMAIN

}

create_sync () {

        curlftpfs -o nonempty -o user=$USER:$PASS ftp.$DOMAIN /mnt/$DOMAIN
        echo "rsync -arvHu --progress --delete --stats /mnt/$DOMAIN/ $DIR/$DOMAIN" >> $SCRIPT

}		



configure () {

	SCRIPT="$DIR/rsync.sh"

	if [ ! -f "$SCRIPT" ]; then

		echo -e "Prima configurazione nel backup."

		configure
		crontab

	else

		echo -e "Il backup è stato già configurato in questa directory."
		EXTDOM=$(cat $SCRIPT |awk '{print$6}' |cut -f3 -d / );
		echo -e "Sono già configurati i backup per i seguenti domini: \n$EXTDOM"

		echo -e "Vuoi (A)ggiungere nuovi domini? Vuoi (R)esettare la configurazione del backup? Oppure (E)sci"
		read SCELTA

		case $SCELTA in

		A|a) 
			initialize
		   	crontab
		;; 

		R|r) 
			> $SCRIPT
		   	echo -e "Tutti i dati sui precedenti backup sono stati cancellati."
		   	initialize
		   	crontab
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


crontab () {

	# Aggiungere quando eseguire il backup ed email di alert

	echo "* 1 * * 1 $SCRIPT 2&1>/dev/null" > /etc/cron.d/mybackup
        /etc/init.d/cron stop && /etc/init.d/cron start && \
	echo -e "Sistema di backup installato con successo! \nIl primo backup è schedulato per il prossimo Lunedì alle 01:00. \n\nPer lanciare prima il backup, esegui $SCRIPT"

}


intro
check_root
check_curlftp
check_rsync
check_dir
configure
