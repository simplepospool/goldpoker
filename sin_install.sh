#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='sin.conf'
CONFIGFOLDER='/root/.sin'
COIN_DAEMON='sind'
COIN_CLI='sin-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://www.dropbox.com/s/su4xnsj8syk0z98/sin_daemon_1604.zip'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='sin'
COIN_PORT=20970
RPC_PORT=20971
BOOTSTRAP='https://www.dropbox.com/s/p2jao7n0q3i5jv1/sin_bootstrap.zip'
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
  # rm $BOOTSTRAP_FILE
 
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
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
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
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the GEN Key${NC}"
    while [[ ! $($COIN_CLI getblockcount 2> /dev/null) =~ ^[0-9]+$ ]]; do 
    sleep 1
    done
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
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
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY

#SIN addnodes
addnode=104.248.17.3:40692
addnode=46.101.152.7:46878
addnode=104.248.133.94:20970
addnode=46.101.227.238:20970
addnode=51.254.197.178:59367
addnode=176.98.42.202:57630
addnode=76.108.75.234:53099
addnode=217.240.105.26:52266
addnode=119.194.83.150:51834
addnode=5.157.115.132:45018
addnode=193.95.206.212:61478
addnode=92.255.202.33:49817
addnode=84.227.202.187:50920
addnode=96.76.132.58:62821
addnode=59.18.162.74:65302
addnode=87.227.207.234:56300
addnode=85.12.208.182:55373
addnode=95.31.251.80:20970
addnode=46.233.42.249:60174
addnode=92.187.112.30:20970
addnode=188.218.4.181:54858
addnode=79.18.67.18:64255
addnode=104.35.172.250:50710
addnode=188.186.76.31:24557
addnode=207.148.117.227:20970
addnode=1.215.154.59:58086
addnode=178.128.107.22:20970
addnode=78.160.28.77:58127
addnode=176.50.103.236:56126
addnode=212.112.121.123:56706
addnode=94.180.233.124:54477
addnode=142.93.138.172:47724
addnode=77.66.176.208:65163
addnode=202.149.101.114:65185
addnode=171.231.109.121:64447
addnode=37.232.173.42:50246
addnode=95.27.46.15:14404
addnode=109.172.25.193:61075
addnode=85.202.228.70:50165
addnode=171.100.141.106:49499
addnode=134.90.164.19:50142
addnode=76.242.25.250:4267
addnode=123.206.229.120:20970
addnode=185.153.179.10:51384
addnode=85.235.165.2:51886
addnode=95.87.203.47:64619
addnode=103.17.246.160:50414
addnode=128.82.17.5:35805
addnode=109.242.173.67:39352
addnode=68.44.41.64:53894
addnode=188.43.112.104:50366
addnode=109.92.193.54:63807
addnode=89.249.114.112:54044
addnode=198.27.74.99:20970
addnode=112.11.230.137:20193
addnode=72.83.232.107:60480
addnode=73.102.42.45:51906
addnode=49.228.246.228:64750
addnode=89.216.28.92:61131
addnode=89.3.178.185:43294
addnode=46.53.211.24:49688
addnode=109.106.139.185:57896
addnode=90.188.9.247:62514
addnode=36.65.91.3:7761
addnode=122.193.136.47:60494
addnode=121.184.2.236:62294
addnode=195.135.213.205:50904
addnode=185.50.24.206:60884
addnode=89.222.164.199:6690
addnode=188.234.213.120:51815
addnode=212.34.243.162:54130
addnode=185.65.134.169:56680
addnode=58.173.226.173:59209
addnode=37.79.203.164:65183
addnode=193.178.228.89:50551
addnode=95.87.223.188:55400
addnode=46.21.75.34:57572
addnode=37.79.41.243:1163
addnode=124.122.34.151:54720
addnode=85.198.130.43:50018
addnode=124.121.201.88:61299
addnode=80.92.235.238:51791
addnode=5.105.61.181:9475
addnode=14.116.68.60:3663
addnode=146.255.225.190:60760
addnode=91.225.48.32:55723
addnode=93.183.234.113:51207
addnode=81.108.229.40:54430
addnode=93.81.53.134:53998
addnode=109.194.51.104:53058
addnode=178.76.217.226:59722
addnode=84.194.181.38:57013
addnode=95.78.252.47:61048
addnode=171.233.208.198:52306
addnode=37.21.18.63:57139
addnode=80.220.139.129:53022
addnode=176.123.218.22:65467
addnode=5.18.214.195:2545
addnode=112.22.111.120:8533
addnode=96.52.142.0:54168
addnode=5.142.140.248:64643
addnode=93.151.221.198:4070
addnode=88.230.20.12:24675
addnode=115.73.1.239:53404
addnode=73.168.84.118:60179
addnode=96.23.125.159:57042
addnode=31.134.191.24:49911
addnode=176.112.163.7:64803
addnode=171.248.190.79:49946
addnode=79.145.72.38:59112
addnode=24.133.144.104:55483
addnode=113.100.38.186:32535
addnode=116.109.238.227:2051
addnode=184.22.22.178:52027
addnode=178.76.228.4:52485
addnode=183.128.191.35:52600
addnode=125.27.151.100:51973
addnode=85.15.69.230:62383
addnode=185.153.179.27:56051
addnode=68.44.41.64:56966
addnode=60.175.196.87:51281
addnode=46.147.193.168:52284
addnode=193.35.100.225:10400
addnode=14.161.34.33:54376
addnode=78.102.218.47:2469

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
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC} Please Run again.."
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
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
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

