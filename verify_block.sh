#!/bin/bash

COINSERVICE='cruxcoin'
DAEMON='cruxcoind'
CLI='cruxcoin-cli'
FOLDER='.cruxcoin'
BOOTSTRAP='https://www.dropbox.com/s/weh6e6us0qwa94h/cux_bootstrap.zip'
BOOTSTRAP_FILE='cux_bootstrap.zip'
GETBLOCKHASH='764376dddccd779a50a1f2842e6f2864668775a640e179acfdf04e86e538db18'
a=$($CLI getblockhash 68485)

echo $a

if [ $a = 764376dddccd779a50a1f2842e6f2864668775a640e179acfdf04e86e538db18 ]
  then echo "You´re on the right chain"
  $CLI masternode status
 

else
  echo "You´re on the wrong chain"
  systemctl stop $COINSERVICE.service
  killall $DAEMON
  cd $FOLDER
  rm -rf backups
  rm -rf chainstate
  rm *.dat
  rm -rf database
  rm -rf zerocoin
  rm -rf blocks
  rm -rf sporks
  rm *.log
  rm *.pid
  rm masternode.conf
  # wget $BOOTSTRAP
  # unzip $BOOTSTRAP_FILE
  # rm $BOOTSTRAP_FILE
  systemctl start $COINSERVICE.service
  sleep 60
  $CLI getinfo
fi
