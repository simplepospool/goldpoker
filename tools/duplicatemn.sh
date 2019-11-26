#!/bin/bash

echo -e "${GREEN}Please tell me what coin you want${NC}"
read -e COIN

echo -e "${GREEN}How many do you want?${NC}"
read -e AMOUNT

for ((n=0;n<$AMOUNT;n++))
do
 dupmn install $COIN --bootstrap
 sleep 20
done