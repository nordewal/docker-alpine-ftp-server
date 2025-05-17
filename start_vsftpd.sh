#!/bin/sh

#Remove all ftp users
grep '/ftp/' /etc/passwd | cut -d':' -f1 | xargs -r -n1 deluser

#Create users
#USERS='name1|password1|[folder1][|uid1][|gid1] name2|password2|[folder2][|uid2][|gid2]'
#may be:
# user|password foo|bar|/home/foo
#OR
# user|password|/home/user/dir|10000
#OR
# user|password|/home/user/dir|10000|10000
#OR
# user|password||10000|82

#Default user 'ftp' with password 'alpineftp'

if [ -z "$USERS" ]; then
  USERS="alpineftp|alpineftp"
fi

for i in $USERS; do
  NAME=$(echo $i | cut -d'|' -f1)
  GROUP=$NAME
  PASS=$(echo $i | cut -d'|' -f2)
  FOLDER=$(echo $i | cut -d'|' -f3)
  UID=$(echo $i | cut -d'|' -f4)
  # Add group handling
  GID=$(echo $i | cut -d'|' -f5)

  if [ -z "$FOLDER" ]; then
    FOLDER="/ftp/$NAME"
  fi

  if [ ! -z "$UID" ]; then
    UID_OPT="-u $UID"
    if [ -z "$GID" ]; then
      GID=$UID
    fi
    #Check if the group with the same ID already exists
    GROUP=$(getent group $GID | cut -d: -f1)
    if [ ! -z "$GROUP" ]; then
      GROUP_OPT="-G $GROUP"
    elif [ ! -z "$GID" ]; then
      # Group don't exist but GID supplied
      addgroup -g $GID $NAME
      GROUP_OPT="-G $NAME"
    fi
  fi

  echo -e "$PASS\n$PASS" | adduser -h $FOLDER -s /sbin/nologin $UID_OPT $GROUP_OPT $NAME
  mkdir -m 750 -p $FOLDER
  chown $NAME:$GROUP $FOLDER
  unset NAME PASS FOLDER UID GID
done

if [ -z "$MIN_PORT" ]; then
  MIN_PORT=21000
fi

if [ -z "$MAX_PORT" ]; then
  MAX_PORT=21010
fi

if [ ! -z "$ADDRESS" ]; then
  ADDR_OPT="-opasv_address=$ADDRESS"
fi

openssl req -x509 -nodes -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -days 9999 -newkey rsa:4096 -keyout /tmp/vsftpd.pem -out /tmp/vsftpd.pem
TLS_OPT="-orsa_cert_file=/tmp/vsftpd.pem -ossl_enable=YES -oallow_anon_ssl=NO -oforce_local_data_ssl=YES -oforce_local_logins_ssl=YES -ossl_tlsv1=NO -ossl_sslv2=NO -ossl_sslv3=NO -ossl_ciphers=HIGH"

vsftpd -opasv_min_port=$MIN_PORT -opasv_max_port=$MAX_PORT $ADDR_OPT $TLS_OPT /etc/vsftpd/vsftpd.conf
