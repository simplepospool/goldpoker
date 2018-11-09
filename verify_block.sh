#!/bin/bash

a=$(logiscoin-cli getblockhash 132367)

echo $a

if [ $a = 844c98115bdd20b4c507f1497ff4a8c0ce587acf073ded6568912b240dc56813 ]
  then echo "Esta na blockchain certa"
  logiscoin-cli masternode status
  sleep 3
  ~.

else
  echo "Vamos colocar na blockchain correta"
  systemctl stop LogisCoin.service
  killall logiscoind
  cd .logiscoin
  rm -rf backups
  rm -rf chainstate
  rm *.dat
  rm -rf database
  rm -rf zerocoin
  rm -rf blocks
  rm *.log
  rm logiscoind.pid
  rm masternode.conf
  rm -rf sporks
  wget https://www.dropbox.com/s/6bletncz1bnupv9/lgs_bootstrap.zip
  unzip lgs_bootstrap.zip
  rm lgs_bootstrap.zip
  systemctl start LogisCoin.service
  sleep 60
  logiscoin-cli getinfo
      
fi
