#!/bin/bash

a=$(logiscoin-cli getblockhash 127788)

echo $a

if [ $a = 264f283d8aaafc21ba0ef0d5bd1dc90756f853b26947833125a8c8454eb00acb ]
then echo "Esta na blockchain certa"

else echo "Vamos colocar na blockchain correta"
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
