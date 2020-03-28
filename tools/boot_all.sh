!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Please tell me what coin you want${NC}"
read -e COIN

echo -e "${GREEN}Tell me the bootstrap file${NC}"
read -e ZIPFILE

dupmn systemctlall $COIN stop
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/blocks
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/chainstate
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/database
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/backups
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/sporks
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/zerocoin
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/*.pid
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/*.log
bash dupmn_all.sh $COIN rm -rf DUPFOLDER/*.dat
bash dupmn_all.sh $COIN unzip -oq $ZIPFILE -d DUPFOLDER
dupmn systemctlall $COIN start

rm $ZIPFILE

echo -e "${GREEN}All dupes were bootstrapped${NC}"