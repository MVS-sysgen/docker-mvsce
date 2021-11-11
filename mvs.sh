#!/bin/bash
# This script will copy the config file, edit it and move dasd
# to the /config and /dasd volume if they don't already exist
# Then it will boot MVS/CE

if [ ! -f /config/local.cnf ]; then
    echo "[*] /config/local.cnf does not exist... generating"
    sed 's_DASD/_/dasd/_g' MVSCE/conf/local.cnf > /config/local.cnf
    sed -i 's_punchcards/_/punchcards/_g' /config/local.cnf
    sed -i 's_printers/_/printers/_g' /config/local.cnf
    sed -i 's_mvslog.txt_/logs/mvslog.txt_g' /config/local.cnf
    sed -i 's_localhost_0.0.0.0_g' /config/local.cnf
    echo 'HTTP   PORT 8888 AUTH ${HUSER:=hercules} ${HPASS:=hercules}' >> /config/local.cnf
    echo "HTTP   START" >> /config/local.cnf
fi

for disk in MVSCE/DASD/*; do
    if [ ! -f /dasd/$(basename $disk) ]; then
        echo "[*] Copying $disk"
        cp -v $disk /dasd/
    fi
done

if [ ! -f /certs/ftp.pem ]; then
    echo "[*] /certs/ftp.pem does not exist... generating"
    openssl req -x509 -nodes -days 365 \
    -subj  "/C=CA/ST=QC/O=FTPD Inc/CN=hercules.ftp" \
     -newkey rsa:2048 -keyout /certs/ftp.key \
     -out /certs/ftp.crt
     cat /certs/ftp.key /certs/ftp.crt > /certs/ftp.pem

fi


if [ ! -f /certs/3270.pem ]; then
    echo "[*] /certs/3270.pem does not exist... generating"
    openssl req -x509 -nodes -days 365 \
    -subj  "/C=CA/ST=QC/O=TN3270 Inc/CN=hercules.3270" \
     -newkey rsa:2048 -keyout /certs/3270.key \
     -out /certs/3270.crt
     cat /certs/3270.key /certs/3270.crt > /certs/3270.pem

fi

echo "[*] Starting encrypted FTP listener on port 21"
( socat -v openssl-listen:21,cert=/certs/ftp.pem,verify=0,reuseaddr,fork tcp4:127.0.0.1:2121 ) &
echo "[*] Starting encrypted TN3270 listener on port 23"
( socat -v openssl-listen:23,cert=/certs/3270.pem,verify=0,reuseaddr,fork tcp4:127.0.0.1:3270 ) &

cd MVSCE
echo "[*] Starting Hercules"
hercules -f /config/local.cnf -r conf/mvsce.rc --daemon > /logs/hercules.log