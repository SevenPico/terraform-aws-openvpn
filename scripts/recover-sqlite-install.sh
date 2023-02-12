OPENVPNAS_DIR=/usr/local/openvpn_as
OPENVPNAS_BACKUP_DIR=/usr/local/openvpn_as/backup
OPENVPNAS_SERVICE=openvpnas
S3_BUCKET
BACKUP_NAME
BACKUP_VERSION_ID
REGION


service openvpnas stop

mkdir -p $OPENVPNAS_BACKUP_DIR
cd $OPENVPNAS_BACKUP_DIR
aws s3api get-object --bucket $S3_BUCKET --key $BACKUP_NAME --REGION --version-id $BACKUP_VERSION_ID
tar -xf $BACKUP_NAME

cd ./etc/db
DB_FILES="*.db"
for f in $DB_FILES
do
  echo "Restoring $f."
  rm -f $OPENVPNAS_DIR/etc/db/"$f"
  sqlite3 <$OPENVPNAS_BACKUP_DIR/etc/db"$f" $OPENVPNAS_DIR/etc/db/"$f"
done
rm -f $OPENVPNAS_DIR/etc/as.conf
echo "Restoring as.conf"
cp $OPENVPNAS_BACKUP_DIR/etc/as.conf $OPENVPNAS_DIR/etc/as.conf

cd $OPENVPNAS_DIR
rm -Rf /usr/local/openvpn_as/backup

service openvpnas start
