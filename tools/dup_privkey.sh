#!/bin/bash

# <$1 = prof_name> | <$2 = priv_key>

function get_conf() {
	# <$1 = conf_file>
	local str_map="";
	for line in `sed '/^$/d' $1`; do
		str_map+="[${line%=*}]=${line#*=} "
	done
	echo -e "( $str_map )"
}
function conf_get_value() {
	# <$1 = conf_file> | <$2 = key> | [$3 = limit]
	[[ "$3" == "0" ]] && grep -ws "^$2" "$1" | cut -d "=" -f2 || grep -ws "^$2" "$1" | cut -d "=" -f2 | head $([[ -z "$3" ]] && echo "-1" || echo "-$3")
}

cd ~

[[ ! -f .dupmn/$1 ]] && exit

declare -A conf=$(get_conf .dupmn/dupmn.conf)
declare -A prof=$(get_conf .dupmn/$1)
coin_folder="${prof[COIN_FOLDER]}"
coin_config="${prof[COIN_CONFIG]}"
dup_count=$((${conf[$1]}))

for (( i=1; i<=$dup_count; i++ )); do
	if [[ $(conf_get_value $coin_folder$i/$coin_config masternodeprivkey) = $2 ]]; then
		echo "$i"
		exit
	fi
done
