# Site-Backup
Backup all your ftp site on a Debian/Ubuntu server

Script che imposta un backup settimanale dello spazio web di una lista di siti. 

Lo script, installa i software necessari come curlfts e rsync,  monta lo directory remote  ftp in locale e le sincronizza nelle directory scelta.
Crea un file backup.sh che viene inserito in un cron settimanale.
Se si vogliono aggiungere altri domini, bisogna richiamare questo script.

Gli script presenti in questo repository non sono supportati. Gli script vengono forniti così come sono senza garanzie di alcun tipo. Si declinano tutte le garanzie implicite, compresi, senza limitazione, qualsiasi garanzia di commerciabilità o idoneità per uno scopo particolare, ed eventuale perdita / modifica dei dati. L'intero rischio derivante dall'utilizzo o le prestazioni degli script e documentazione rimane con te. In nessun i relativi autori o chiunque coinvolto nella creazione, produzione, o recapito degli script saranno ritenuti responsabili per eventuali danni di qualsiasi tipo (inclusi, senza limitazione, danni per perdita di profitti, interruzione dell'attività, perdita di informazioni aziendali o altre perdite economiche) derivanti dall'utilizzo di o dall'incapacità di utilizzare gli script o documentazione, anche se l'autore è stato avvertito della possibilità di tali danni.
