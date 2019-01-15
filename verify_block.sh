#!/bin/bash

COINSERVICE='evos'
DAEMON='evosd'
CLI='evos-cli'
FOLDER='.evos'
BOOTSTRAP='https://www.dropbox.com/s/n4avqa5ziby06kg/evos_bootstrap.zip'
BOOTSTRAP_FILE='evos_bootstrap.zip'
GETBLOCKHASH='0eea2673e8617769d6d6121eba6a53e074693adeed604429eb570837afca0275'
a=$($CLI getblockhash 122250)

echo $a

if [ $a = 0eea2673e8617769d6d6121eba6a53e074693adeed604429eb570837afca0275 ]
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
  wget $BOOTSTRAP
  unzip $BOOTSTRAP_FILE
  rm $BOOTSTRAP_FILE
  systemctl start $COINSERVICE.service
  sleep 60
  $CLI getinfo
fi
