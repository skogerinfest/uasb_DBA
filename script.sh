# =============================================================================================
# Procedimiento de Copia de Seguridad de Servidor de Postgres
#!/bin/bash
#=============================================================================================
# Script Backup Data
## BEGIN CONFIG ##
BACKUP_DIR="/home/skoger/backups/" #Dirección de ejemplo donde se guardaran los backups
USER= adminuser
FECHA=$(date +%d-%m-%Y)
FECHA_BORRADO=$(date +%d-%m-%Y --date='10 days ago')
BACKUP_DIR_TODAY=$BACKUP_DIR$FECHA/
## END CONFIG ##
export PGPASSWORD=chetebolas

if [ ! -d $BACKUP_DIR ]; then
mkdir -p $BACKUP_DIR
fi

echo $BACKUP_DIR_TODAY
if [ ! -d $BACKUP_DIR_TODAY ]; then
mkdir $BACKUP_DIR_TODAY
fi

#Leemos todas la bases de datos existente en Postgres, para despues realizar la copia una a una
POSTGRE_DBS=$(psql -U $USER -l | awk '(NR > 2) && (/[a-zA-Z0-9]+[ ]+[|]/) && ( $0 !~ /template[0-9]/) { print $1 }');
#Realizamos la copia de seguridad de cada una de ellas y las guardamos en un directorio de backups
for DB in $POSTGRE_DBS ; do
echo "* Backuping PostgreSQL data from $DB@$HOST ..."
pg_dump -U $USER --format=c -f $BACKUP_DIR_TODAY$DB.backup $DB

#Borramos las copias con una antiguedad mayor a 10 dias
rm -rf $BACKUP_DIR$FECHA_BORRADO
echo "finalizada $DB ..."
done

# Las empaquetamos y las copiamos en otro servidor de respaldo.
# Una vez realizado borramos el empaquetado.
cd $BACKUP_DIR_TODAY
echo "...empaquetamos las DBs del $FECHA..."
tar czvf dbs-$FECHA.tar.gz *.backup

echo "... enviamos una copia a un sitio distinto por scp..."

scp /home/skoger/backups/$FECHA/dbs-$FECHA.tar.gz usuarioservidor@ipservidor:/home/backup/Backups/dbs-$FECHA.tar.gz
