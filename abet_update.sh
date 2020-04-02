#!/bin/bash#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='abet.conf'
CONFIGFOLDER='/root/.abet'
COIN_DAEMON='abetd'
COIN_CLI='abet-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/altbet/abet/releases/download/v3.4.1.0/abet-v3.4.1.0-linux.tar.gz'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='abet'
COIN_NAME1='abet'
COIN_PORT=55002
RPC_PORT=30556
BOOTSTRAP='http://164.68.112.107/abet-bootstrap.zip'
BOOTSTRAP_FILE=$(echo $BOOTSTRAP | awk -F'/' '{print $NF}')

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function verify_dupm_all() {
	if [[ -f dupmn_all.sh ]]; then
		echo -e "dupmn_all is installed in this VPS :)"
	else
		wget https://raw.githubusercontent.com/simplepospool/goldpoker/master/tools/dupmn_all.sh
	fi
}

function update_dupm() {
	dupmn update
	sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y  >/dev/null 2>&1
	apt-get update -y  >/dev/null 2>&1
	apt-get upgrade -y  >/dev/null 2>&1
	apt-get install --only-upgrade libstdc++6 -y  >/dev/null 2>&1
}

function verify_dup_privkey() {
	if [[ -f dup_privkey.sh ]]; then
		echo -e "dupmn_privkey is installed in this VPS :)"
	else
		wget https://raw.githubusercontent.com/simplepospool/goldpoker/master/tools/dup_privkey.sh
	fi
}

function bootstrap() {

	if [[ -f /etc/systemd/system/$COIN_NAME-1.service ]]; then 
		rm $BOOTSTRAP_FILE >/dev/null 2>&1
		wget -q $BOOTSTRAP
		systemctl stop $COIN_NAME.service
		dupmn systemctlall $COIN_NAME stop 
		bash dupmn_install.sh >/dev/null 2>&1
		cd $CONFIGFOLDER
		rm -rf blocks >/dev/null 2>&1
		rm -rf chainstate >/dev/null 2>&1
		rm -rf sporks >/dev/null 2>&1
		rm -rf database >/dev/null 2>&1
		rm -rf zerocoin >/dev/null 2>&1
		rm *.log >/dev/null 2>&1
		rm *.dat >/dev/null 2>&1
		rm *.pid >/dev/null 2>&1
		cd
		bash dupmn_all.sh $COIN_NAME rm -rf DUPFOLDER/blocks >/dev/null 2>&1
		bash dupmn_all.sh $COIN_NAME rm -rf DUPFOLDER/chainstate >/dev/null 2>&1
		bash dupmn_all.sh $COIN_NAME rm -rf DUPFOLDER/sporks >/dev/null 2>&1
		bash dupmn_all.sh $COIN_NAME rm -rf DUPFOLDER/database >/dev/null 2>&1
		bash dupmn_all.sh $COIN_NAME rm -rf DUPFOLDER/zerocoin >/dev/null 2>&1
		bash dupmn_all.sh $COIN_NAME rm -rf DUPFOLDER/*.log >/dev/null 2>&1
		bash dupmn_all.sh $COIN_NAME rm -rf DUPFOLDER/*.dat >/dev/null 2>&1
		bash dupmn_all.sh $COIN_NAME rm -rf DUPFOLDER/*.pid  >/dev/null 2>&1
		cd
		unzip -oq $BOOTSTRAP_FILE -d $CONFIGFOLDER
		bash dupmn_all.sh $COIN_NAME unzip -oq $BOOTSTRAP_FILE -d DUPFOLDER
		systemctl start $COIN_NAME.service
		dupmn systemctlall $COIN_NAME start
		echo -e "${GREEN}Bootstrap em varios $COIN_NAME ${NC}"
      else
		rm $BOOTSTRAP_FILE  >/dev/null 2>&1
		cd $CONFIGFOLDER
		wget -q $BOOTSTRAP
		systemctl stop $COIN_NAME.service		
		rm -rf blocks
		rm -rf chainstate
		rm -rf sporks
		rm -rf database
		rm *.log
		rm *.dat 
		rm *.pid
		unzip -oq $BOOTSTRAP_FILE
		systemctl start $COIN_NAME.service
		echo -e "${GREEN}Bootstrap numa moeda $COIN_NAME ${NC}"
	fi
}

function update_daemon() {

	if [[ -f /etc/systemd/system/$COIN_NAME-1.service ]]; then 
		cd
		sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y >/dev/null 2>&1
		sudo apt-get update -y >/dev/null 2>&1
		sudo apt-get upgrade -y >/dev/null 2>&1
		sudo apt-get install --only-upgrade libstdc++6 -y >/dev/null 2>&1
		systemctl stop $COIN_NAME.service || systemctl stop $COIN_NAME1.service
		dupmn systemctlall $COIN_NAME stop
		killall $COIN_DAEMON
		sleep 2
		cd
		rm $COIN_PATH$COIN_DAEMON
		rm $COIN_PATH$COIN_CLI
		cd $TMP_FOLDER >/dev/null 2>&1
		wget $COIN_TGZ  >/dev/null 2>&1
		tar xvf $COIN_ZIP || unzip $COIN_ZIP >/dev/null 2>&1
		mv $(find ./ -mount -name $COIN_DAEMON) $COIN_PATH >/dev/null 2>&1
		mv $(find ./ -mount -name $COIN_CLI) $COIN_PATH >/dev/null 2>&1
		chmod +x $COIN_PATH$COIN_DAEMON >/dev/null 2>&1
		chmod +x $COIN_PATH$COIN_CLI >/dev/null 2>&1
		strip $COIN_PATH$COIN_DAEMON 
		strip $COIN_PATH$COIN_CLI 
		cd
		rm -rf $TMP_FOLDER
		systemctl start $COIN_NAME.service || systemctl start $COIN_NAME1.service
		dupmn systemctlall $COIN_NAME start
		echo -e "${GREEN}Todos os daemon $COIN_NAME atualizado${NC}" 
	else 
		cd
		sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y >/dev/null 2>&1
		sudo apt-get update -y >/dev/null 2>&1
		sudo apt-get upgrade -y >/dev/null 2>&1
		sudo apt-get install --only-upgrade libstdc++6 -y >/dev/null 2>&1
		systemctl stop $COIN_NAME.service || systemctl stop $COIN_NAME1.service
		killall $COIN_DAEMON
		sleep 2
		cd
		rm $COIN_PATH$COIN_DAEMON
		rm $COIN_PATH$COIN_CLI
		cd $TMP_FOLDER >/dev/null 2>&1
		wget $COIN_TGZ  >/dev/null 2>&1
		tar xvf $COIN_ZIP || unzip $COIN_ZIP >/dev/null 2>&1
		mv $(find ./ -mount -name $COIN_DAEMON) $COIN_PATH >/dev/null 2>&1
		mv $(find ./ -mount -name $COIN_CLI) $COIN_PATH >/dev/null 2>&1
		chmod +x $COIN_PATH$COIN_DAEMON >/dev/null 2>&1
		chmod +x $COIN_PATH$COIN_CLI >/dev/null 2>&1
		strip $COIN_PATH$COIN_DAEMON
		strip $COIN_PATH$COIN_CLI
		cd
		rm -rf $TMP_FOLDER
		systemctl start $COIN_NAME.service || systemctl start $COIN_NAME1.service
		echo -e "${GREEN}Foi atualizado apenas 1 daemon $COIN_NAME${NC}"  
	fi
}

function info() {

	if [[ -f /etc/systemd/system/$COIN_NAME-1.service ]]; then 
		#$COIN_NAME-cli-all masternode debug
		$COIN_NAME-cli-all getinfo
		#$COIN_NAME-cli-all getblockhash 179922
	else
		#$COIN_NAME-cli masternode debug
		$COIN_NAME-cli getinfo
		#$COIN_NAME-cli getblockhash 179922 
	fi
}

function restart() {

	if [[ -f /etc/systemd/system/$COIN_NAME-1.service ]]; then 
		dupmn systemctlall $COIN_NAME restart || dupmn systemctlall $COIN_NAME1 restart
	else
		systemctl restart $COIN_NAME.service || systemctl restart $COIN_NAME1.service
	fi
}

function remove() {

	if [[ -f /etc/systemd/system/$COIN_NAME-1.service ]]; then 
		cd
		dupmn profdel $COIN_NAME >/dev/null 2>&1
		rm $COIN_NAME.dmn
		rm *.zip 
		systemctl stop $COIN_NAME.service
		rm -rf $CONFIGFOLDER
		rm /etc/systemd/system/$COIN_NAME.service
		rm $COIN_PATH$COIN_DAEMON
		rm $COIN_PATH$COIN_CLI
        ufw delete allow $COIN_PORT/tcp
		echo -e "${GREEN}Foram removidos vários daemon $COIN_NAME${NC}"
	else 
		cd
		systemctl stop $COIN_NAME.service
		rm *.zip 
		rm -rf $CONFIGFOLDER
		rm /etc/systemd/system/$COIN_NAME.service
		rm $COIN_PATH$COIN_DAEMON
		rm $COIN_PATH$COIN_CLI
        ufw delete allow $COIN_PORT/tcp
		echo -e "${GREEN}Foi removido apenas 1 daemon $COIN_NAME${NC}"  
	fi
}

function stop_service() {

	if [[ -f /etc/systemd/system/$COIN_NAME-1.service ]]; then 
		cd
		dupmn systemctlall $COIN_NAME stop 
		echo -e "${GREEN}Foram parados todos os servicos de $COIN_NAME${NC}"
	else 
		cd
		systemctl stop $COIN_NAME.service
		echo -e "${GREEN}Foi parado apenas um servico $COIN_NAME${NC}"  
	fi
}

function bootstrap_pac() {

	cd
		systemctl stop $COIN_NAME.service
		cd $CONFIGFOLDER
		rm -rf blocks >/dev/null 2>&1
		rm -rf chainstate >/dev/null 2>&1
		rm -rf database >/dev/null 2>&1
		rm -rf evodb >/dev/null 2>&1
		rm -rf llmq >/dev/null 2>&1
		rm *.dat >/dev/null 2>&1
		rm *.log >/dev/null 2>&1
		rm *.pid >/dev/null 2>&1
		wget -q $BOOTSTRAP
		unzip -oq $BOOTSTRAP_FILE
		rm $BOOTSTRAP_FILE
		systemctl start $COIN_NAME.service
	echo -e "${GREEN}Bootstrap em $COIN_NAME concluido com sucesso${NC}"  
	
}


function run() {
	update_dupm
	#apt-get install dos2unix -y
	verify_dupm_all
	verify_dup_privkey
	update_daemon
	bootstrap
	rm $BOOTSTRAP_FILE
	#bootstrap_pac
	#info
	#restart
	rm abet_update.sh
	#remove
	#stop_service
	
	
}

run