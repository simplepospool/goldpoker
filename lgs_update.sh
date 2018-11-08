#!/bin/bash

CONFIG_FILE='logiscoin.conf'
CONFIGFOLDER='/root/.logiscoin'
COIN_DAEMON='/usr/local/bin/logiscoind'
COIN_CLI='/usr/local/bin/logiscoin-cli'
COIN_REPO='https://github.com/lgsproject/LogisCoin/releases/download/2.0.1.0/logiscoin-2.0.1-x86_64-linux-gnu.tar.gz'
COIN_NAME='LogisCoin'
COIN_PORT=48484

function compile_node() {

  echo -e "Stop the $COIN_NAME wallet daemon"
  
    systemctl stop $COIN_NAME.service
    sleep 7
  
  echo -e "Remove the old $COIN_NAME wallet from the system"
  rm -f /usr/local/bin/logiscoin* >/dev/null 2>&1
  rm $CONFIGFOLDER/banlist.dat >/dev/null 2>&1
  rm $CONFIGFOLDER/mnpayments.dat >/dev/null 2>&1
  rm $CONFIGFOLDER/fee_estimates.dat >/dev/null 2>&1
  rm $CONFIGFOLDER/peers.dat >/dev/null 2>&1
  rm $CONFIGFOLDER/budget.dat >/dev/null 2>&1
  rm $CONFIGFOLDER/mncache.dat >/dev/null 2>&1
  rm $CONFIGFOLDER/debug.log >/dev/null 2>&1
  rm $CONFIGFOLDER/db.log >/dev/null 2>&1
  rm $CONFIGFOLDER/bootstrap.dat >/dev/null 2>&1
  rm $CONFIGFOLDER/bootstrap.dat.old >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/blocks >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/chainstate >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/backups >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/sporks >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/zerocoin >/dev/null 2>&1
  rm -f $CONFIGFOLDER/*.log >/dev/null 2>&1
  cd $CONFIGFOLDER
  wget --progress=bar:force https://www.dropbox.com/s/6bletncz1bnupv9/lgs_bootstrap.zip 2>&1 | progressfilt
  unzip lgs_bootstrap.zip
  rm lgs_bootstrap.zip
  cd
  sleep 5
  clear
  
  echo -e "Prepare to download a new wallet of $COIN_NAME"
  TMP_FOLDER=$(mktemp -d)
  cd $TMP_FOLDER
  wget --progress=bar:force $COIN_REPO 2>&1 | progressfilt
  compile_error
  COIN_ZIP=$(echo $COIN_REPO | awk -F'/' '{print $NF}')
  COIN_VER=$(echo $COIN_ZIP | awk -F'/' '{print $NF}' | sed -n 's/.*\([0-9]\.[0-9]\.[0-9]\).*/\1/p')
  COIN_DIR=$(echo ${COIN_NAME,,}-$COIN_VER)
  tar xvzf $COIN_ZIP --strip=2 ${COIN_DIR}/bin/${COIN_NAME,,}d ${COIN_DIR}/bin/${COIN_NAME,,}-cli>/dev/null 2>&1
  compile_error
  rm -f $COIN_ZIP >/dev/null 2>&1
  cp logiscoin* /usr/local/bin >/dev/null 2>&1
  compile_error
  strip $COIN_DAEMON $COIN_CLI
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
  
  echo -e "Start the $COIN_NAME wallet daemon"
  if (( $UBUNTU_VERSION == 16 || $UBUNTU_VERSION == 18 )); then
    systemctl start $COIN_NAME.service
  else
    /etc/init.d/$COIN_NAME start
  fi
  sleep 7
  clear
}


##### Main #####
clear

compile_node
