#Site-Backup
Esegue in backup dei propri spazi ftp su un server Debian / Ubuntu

DESCRIZIONE

Script interattivo che imposta un backup settimanale dello spazio web di una lista di siti.

Lo script installa i software necessari come curlfts e rsync, aquisisce i dati dei siti che volete configurare acquisendoli dalla shell, monta lo directory remote ftp tramite curlfts in locale e crea un file rsync.sh che viene inserito in un cron settimanale che sincronizza tramite rsync i dati remoti nella directory scelta.

PREREQUISITI

1) Ambiente Debian / Ubuntu

2) Privilegi di Root

3) (Opzionale) Deve essere installato un software per l'invio delle email (Es. Exim4, Sendmail, Postfix, ecc..).

INSTALLAZIONE e CONFIGURAZIONE.

1) Scaricare il file set_backup.sh in una directory della macchina su cui volete salvare i backup dei vostri siti web.

2) Chmod +x di set_backup.sh

3) Eseguire il file dalla cartella in cui è stato salvato: ./set_backup.sh

4) Seguire le istruzioni a video.

Il programma è interattivo, e vi chiederà tutte le informazioni per configurare il vostro backup (Cartella di destinazione, numero di domini, pianificazione del backup, email di alert, ecc...). Le informazioni necessarie alla configurazione, sono semplicemnte i dai ftp dei domini di cui volete eseguire il backup.

Se volete aggiungere altri domini una volta completata la prima configurazione, è sufficiente richiamare questo script. Potete richiamare lo script ogni volta che volete, ed eventualmente azzerare la configurazione o aggiungere nuovi domini.

NOTE:

Gli script presenti in questo repository non sono supportati. Gli script vengono forniti così come sono senza garanzie di alcun tipo. Si declinano tutte le garanzie implicite, compresi, senza limitazione, qualsiasi garanzia di commerciabilità o idoneità per uno scopo particolare, ed eventuale perdita / modifica dei dati. L'intero rischio derivante dall'utilizzo o le prestazioni degli script e documentazione rimane con te. In nessun i relativi autori o chiunque coinvolto nella creazione, produzione, o recapito degli script saranno ritenuti responsabili per eventuali danni di qualsiasi tipo (inclusi, senza limitazione, danni per perdita di profitti, interruzione dell'attività, perdita di informazioni aziendali o altre perdite economiche) derivanti dall'utilizzo di o dall'incapacità di utilizzare gli script o documentazione, anche se l'autore è stato avvertito della possibilità di tali danni.
