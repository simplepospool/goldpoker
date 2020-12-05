#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='1x2coin.conf'
CONFIGFOLDER='/root/.1x2coin'
COIN_DAEMON='1x2coind'
COIN_CLI='1x2coin-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/1X2coin/1X2coin/releases/download/v1.0.0/1x2coin-1.0.0-x86_64-linux-gnu.tar.gz'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='1x2coin'
COIN_PORT=9214
RPC_PORT=9215
BOOTSTRAP='http://164.68.112.107/1x2-bootstrap.zip'
BOOTSTRAP_FILE=$(echo $BOOTSTRAP | awk -F'/' '{print $NF}')

NODEIP=$(curl -s4 icanhazip.com)

BLUE=""
YELLOW=""
CYAN="" 
PURPLE=""
RED=''
GREEN=""
NC=''
MAG=''

function find_port() {
        # <$1 = initial_check>

        function port_check_loop() {
                for (( i=$1; i<=$2; i++ )); do
                        if [[ ! $(lsof -Pi :$i -sTCP:LISTEN -t) ]]; then
                                echo $i
                                return
                        fi
                done
        }
        local port=$(port_check_loop $1 $RPC_PORT)
        [[ $port ]] && echo $port || echo $(port_check_loop 1024 $1)
}

purgeOldInstallation() {
    echo -e "${GREEN}Searching and removing old $COIN_NAME files and configurations${NC}"
    #kill wallet daemon
	sudo killall $COIN_DAEMON > /dev/null 2>&1
    #remove old ufw port allow
    sudo ufw delete allow $COIN_PORT/tcp > /dev/null 2>&1
    #remove old files
    sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1
    sudo rm -rf ~/.$COIN_NAME > /dev/null 2>&1
    #remove binaries and $COIN_NAME utilities
    cd /usr/local/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
    echo -e "${GREEN}* Done${NONE}";
}

function download_bootstrap() {
  rm -rf $CONFIGFOLDER/blocks >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/chainstate >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/sporks >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/zerocoin >/dev/null 2>&1
  rm -rf $CONFIGFOLDER/database >/dev/null 2>&1
  rm $CONFIGFOLDER/*.pid >/dev/null 2>&1
  rm $CONFIGFOLDER/*.dat >/dev/null 2>&1
  rm $CONFIGFOLDER/*.log >/dev/null 2>&1
  wget -q $BOOTSTRAP
  unzip -oq $BOOTSTRAP_FILE -d $CONFIGFOLDER
  rm $BOOTSTRAP_FILE
 
  clear
    #echo -e "{\"success\":\""$COIN_NAME bootstraped"\"}"
  #clear

}
function install_sentinel() {
  echo -e "${GREEN}Installing sentinel.${NC}"
  apt-get -y install python-virtualenv virtualenv >/dev/null 2>&1
  git clone $SENTINEL_REPO $CONFIGFOLDER/sentinel >/dev/null 2>&1
  cd $CONFIGFOLDER/sentinel
  virtualenv ./venv >/dev/null 2>&1
  ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
  echo  "* * * * * cd $CONFIGFOLDER/sentinel && ./venv/bin/python bin/sentinel.py >> $CONFIGFOLDER/sentinel.log 2>&1" > $CONFIGFOLDER/$COIN_NAME.cron
  crontab $CONFIGFOLDER/$COIN_NAME.cron
  rm $CONFIGFOLDER/$COIN_NAME.cron >/dev/null 2>&1
}

function download_node() {
  echo -e "${GREEN}Downloading and Installing VPS $COIN_NAME Daemon${NC}"
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  compile_error
  tar xvf $COIN_ZIP || unzip $COIN_ZIP >/dev/null 2>&1
  mv $(find ./ -mount -name $COIN_DAEMON) $COIN_PATH >/dev/null 2>&1
  mv $(find ./ -mount -name $COIN_CLI) $COIN_PATH >/dev/null 2>&1
  chmod +x $COIN_PATH$COIN_DAEMON >/dev/null 2>&1
  chmod +x $COIN_PATH$COIN_CLI >/dev/null 2>&1
  strip $COIN_PATH$COIN_DAEMON >/dev/null 2>&1
  strip $COIN_PATH$COIN_CLI >/dev/null 2>&1
  cd - >/dev/null 2>&1
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
rpcport=$(find_port $RPC_PORT)
rpcallowip=127.0.0.1
nodebuglogfile=1
#------------------
listen=1
txindex=1
server=1
daemon=1
port=$COIN_PORT
#------------------
EOF
}

function create_key() {
  echo -e "${YELLOW}Enter your ${RED}$COIN_NAME Masternode GEN Key${NC}. Or Press enter generate New Genkey"
  read -t 10 -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  while [[ ! $($COIN_CLI getblockcount 2> /dev/null) =~ ^[0-9]+$ ]]; do 
    sleep 1
  done
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   echo -e "{\"error\":\"$COIN_NAME server couldn not start. Check /var/log/syslog for errors.\",\"errcode\":1098}"
   exit 1
  fi
  COINKEY=$(try_cmd $COIN_PATH$COIN_CLI "createmasternodekey" "masternode genkey")
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the GEN Key${NC}"
    echo -e "{\"error\":\"Wallet not fully loaded. Let us wait and try again to generate the GEN Key.\",\"errcode\":1099}"
	while [[ ! $($COIN_CLI getblockcount 2> /dev/null) =~ ^[0-9]+$ ]]; do 
    sleep 1
    done
    COINKEY=$(try_cmd $COIN_PATH$COIN_CLI "createmasternodekey" "masternode genkey")
  fi
  $COIN_PATH$COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=256
#bind=$NODEIP
#-----------------------------
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
#-----------------------------
#$COIN_NAME addnodes


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
  echo -e "{\"error\":\"Impossible to locate the daemon\",\"errcode\":1100}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  echo -e "{\"error\":\"You´re not using Ubuntu 16.04\",\"errcode\":1101}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   echo -e "{\"error\":\"$0 must be run as root\",\"errcode\":1103}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC} Please Run again.."
  echo -e "{\"error\":\"$COIN_NAME is already installed. Please Run again..\",\"errcode\":1104}"
  exit 1
fi
}

function prepare_system() {
echo -e "Preparing the VPS to setup. ${CYAN}$COIN_NAME${NC} ${RED}Masternode${NC}"
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${PURPLE}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install libzmq3-dev -y >/dev/null 2>&1
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y >/dev/null 2>&1
apt-get update -y >/dev/null 2>&1
apt-get upgrade -y >/dev/null 2>&1
apt-get install --only-upgrade libstdc++6 -y >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
	echo -e "{\"error\":\"Not all required packages were installed properly. Try to install them manually by running the following commands\",\"errcode\":1105}"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
 exit 1
fi
clear
}

function important_information() {
 echo
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${GREEN}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "Check Status: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "VPS_IP:PORT ${GREEN}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE GENKEY is: ${RED}$COINKEY${NC}"
 echo -e "Check ${RED}$COIN_CLI getblockcount${NC} and compare to ${GREEN}$COIN_EXPLORER${NC}."
 echo -e "Check ${GREEN}Collateral${NC} already full confirmed and start masternode."
 echo -e "Use ${RED}$COIN_CLI masternode status${NC} to check your MN Status."
 echo -e "Use ${RED}$COIN_CLI help${NC} for help."
 if [[ -n $SENTINEL_REPO  ]]; then
 echo -e "${RED}Sentinel${NC} is installed in ${RED}/root/sentinel_$COIN_NAME${NC}"
 echo -e "Sentinel logs is: ${RED}$CONFIGFOLDER/sentinel.log${NC}"
 fi
 
 clear
  echo -e "{\"success\":\""TRUE"\", \"coin\":\""$COIN_NAME"\", \"port\":\""$COIN_PORT"\", \"ip\":\""$NODEIP"\", \"mnip\":\""$NODEIP:$COIN_PORT"\", \"privatekey\":\""$COINKEY"\", \"startmn\":\""$COIN_DAEMON -daemon"\", \"stopmn\":\""$COIN_CLI stop"\", \"getinfomn\":\""$COIN_CLI getinfo"\", \"statusmn\":\""$COIN_CLI masternode status"\", \"startservice\":\""systemctl start $COIN_NAME.service"\", \"stopservice\":\""systemctl stop $COIN_NAME.service"\", \"configfolder\":\""$CONFIGFOLDER"\"}"
 clear
}

function try_cmd() {
    # <$1 = exec> | <$2 = try> | <$3 = catch>
    exec 2> /dev/null
    local check=$($1 $2)
    [[ "$check" ]] && echo $check || echo $($1 $3)
    exec 2> /dev/tty
}

function setup_node() {
  get_ip
  create_config
  download_bootstrap
  create_key
  update_config
  enable_firewall
  #install_sentinel
  important_information
  configure_systemd
}


##### Main #####
clear

#purgeOldInstallation
checks
prepare_system
download_node
setup_node

#169echo -e "{\"error\":\"$COIN_NAME server couldn not start. Check /var/log/syslog for errors.\",\"errcode\":1098}"
#176echo -e "{\"error\":\"Wallet not fully loaded. Let us wait and try again to generate the GEN Key.\",\"errcode\":1099}"
#243echo -e "{\"error\":\"Impossible to locate the daemon\",\"errcode\":1100}"
#252echo -e "{\"error\":\"You´re not using Ubuntu 16.04\",\"errcode\":1101}"
#258echo -e "{\"error\":\"$0 must be run as root\",\"errcode\":1103}"
#264echo -e "{\"error\":\"$COIN_NAME is already installed. Please Run again..\",\"errcode\":1104}"
#287echo -e "{\"error\":\"Not all required packages were installed properly. Try to install them manually by running the following commands\",\"errcode\":1105}"
