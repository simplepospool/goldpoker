#!/bin/bash
 
TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='trittium2.conf'
CONFIGFOLDER='/root/.trittium2'
COIN_DAEMON='trittiumd'
COIN_CLI='trittium-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/Trittium/trittium/releases/download/2.2.0.2/Trittium-2.2.0.2-Ubuntu-daemon.tgz'
COIN_NAME='Trittium'
COIN_PORT=30001
RPC_PORT=30002
BOOTSTRAP='https://www.dropbox.com/s/ivs69jvvj6qf934/trtt_bootstrap.zip'
BOOTSTRAP_ZIP='trtt_bootstrap.zip'
 
NODEIP=$(curl -s4 icanhazip.com)
 
 
RED=''
YELLOW=''
GREEN=''
NC=''

function download_bootstrap() {
  systemctl stop $COIN_NAME.service
  sleep 60
  cd
  cd $CONFIGFOLDER
  rm -rf blocks
  rm -rf chainstate
  rm peers.dat
  wget $BOOTSTRAP
  unzip $BOOTSTRAP_ZIP
  rm $BOOTSTRAP_ZIP
  cd
  systemctl start $COIN_NAME.service

  clear
    echo -e "{\"success\":\""bootstraped"\"}"
  clear

}
 
function download_node() {
  echo -e "Downloading and installing latest ${GREEN}$COIN_NAME${NC} coin daemon."
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -qO- $COIN_TGZ | tar xvz
  compile_error
  chmod +x *
  cp $COIN_DAEMON $COIN_PATH
  cp $COIN_CLI $COIN_PATH
  sleep 5
  cd ~ >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}
 
 
function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
 
[Service]
User=root
Group=root
 
Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid
 
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
 
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
 
[Install]
WantedBy=multi-user.target
EOF
 
  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1
 
  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}
 
 
function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF
}
 
function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -t 10 -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
    sleep 30
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  fi
  $COIN_PATH$COIN_CLI stop
fi
clear
}
 
function update_config() {
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
#bind=$NODEIP
gen=1
masternode=1
masternodeaddr=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
addnode=212.237.54.54
addnode=173.212.231.180
addnode=176.223.140.120
addnode=45.79.220.242
addnode=107.172.201.105
addnode=45.76.82.32
addnode=95.179.151.54
addnode=77.55.220.88
addnode=207.148.29.82
addnode=144.202.63.245
addnode=94.176.234.254
addnode=128.199.49.143
addnode=142.44.169.93
addnode=149.28.169.81
addnode=202.182.114.2
EOF
}
 
 
function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}
 
 
function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done
 
  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}
 
 
function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  clear
  echo -e "{\"success\":\""FALSE"\", \"message\":\""Failed to compile $COIN_NAME. Please investigate."\"}"
  clear
  exit 1
fi
}
 
 
function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  clear
  echo -e "{\"success\":\""FALSE"\", \"message\":\""You are not running Ubuntu 16.04. Installation is cancelled."\"}"
  clear
  exit 1
fi
 
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   clear
   echo -e "{\"success\":\""FALSE"\", \"message\":\""$0 must be run as root."\"}"
   clear
   exit 1
fi
 
if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMON" ] ; then
  echo -e "{\"success\":\""FALSE"\", \"message\":\""$COIN_NAME is already installed."\"}"
  exit 1
fi
}
 
function prepare_system() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} master node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev libzmq3-dev ufw pkg-config libevent-dev mc libdb5.3++ unzip >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libzmq3-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config mc libevent-dev libdb5.3++ unzip"
 exit 1
fi
clear
}
 
function important_information() {
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${YELLOW}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${YELLOW}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${YELLOW}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${YELLOW}systemctl stop $COIN_NAME.service${NC}"
 echo -e "VPS_IP:PORT ${YELLOW}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${YELLOW}$COINKEY${NC}"
 echo -e "Please check ${YELLOW}$COIN_NAME${NC} daemon is running with the following command: ${YELLOW}systemctl status $COIN_NAME.service${NC}"
 echo -e "Use ${YELLOW}$COIN_CLI masternode status${NC} to check your MN. A running MN will show ${YELLOW}Status 9${NC}."
 echo -e "Use ${YELLOW}$COIN_CLI getinfo${NC} to check your info about your MN.${NC}."
echo -e "================================================================================================================================"
 
 
clear
 echo -e "{\"success\":\""TRUE"\", \"coin\":\""$COIN_NAME"\", \"port\":\""$COIN_PORT"\", \"ip\":\""$NODEIP"\", \"mnip\":\""$NODEIP:$COIN_PORT"\", \"privatekey\":\""$COINKEY"\", \"startmn\":\""$COIN_DAEMON -daemon"\", \"stopmn\":\""$COIN_CLI stop"\", \"getinfomn\":\""$COIN_CLI getinfo"\", \"statusmn\":\""$COIN_CLI masternode status"\", \"startservice\":\""systemctl start $COIN_NAME.service"\", \"stopservice\":\""systemctl stop $COIN_NAME.service"\", \"configfolder\":\""$CONFIGFOLDER"\"}"
clear
}
function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  important_information
  configure_systemd
}
 
 
##### Main #####
clear
 
checks
prepare_system
download_node
setup_node
download_bootstrap
