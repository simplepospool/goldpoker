#!/bin/bash

COINSERVICE='cruxcoin'
DAEMON='cruxcoind'
CLI='cruxcoin-cli'
FOLDER='.cruxcoin'
BOOTSTRAP='https://www.dropbox.com/s/weh6e6us0qwa94h/cux_bootstrap.zip'
BOOTSTRAP_FILE='cux_bootstrap.zip'
GETBLOCKHASH='ec550c8b3a80e30550c4756bd031ec3c136b238243780a61f389e349174d159b'
a=$($CLI getblockhash 65365)

echo $a

if [ $a = $GETBLOCKHASH ]
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
  rm *.log
  rm *.pid
  rm masternode.conf
  rm -rf sporks
  wget $BOOTSTRAP
  unzip $BOOTSTRAP_FILE
  rm $BOOTSTRAP_FILE
  systemctl start $COINSERVICE.service
  sleep 60
  $CLI getinfo
fi
