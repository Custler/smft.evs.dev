#!/usr/bin/env bash

# (C) Sergey Tyurin  2023-02-15 10:00:00

# Disclaimer
##################################################################################################################
# You running this script/function means you will not blame the author(s)
# if this breaks your stuff. This script/function is provided AS IS without warranty of any kind. 
# Author(s) disclaim all implied warranties including, without limitation, 
# any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you.
# In no event shall author(s) be held liable for any damages whatsoever 
# (including, without limitation, damages for loss of business profits, business interruption, 
# loss of business information, or other pecuniary loss) arising out of the use of or inability 
# to use the script or documentation. Neither this script/function, 
# nor any part of it other than those parts that are explicitly copied from others, 
# may be republished without author(s) express written permission. 
# Author(s) retain the right to alter this disclaimer at any time.
##################################################################################################################

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/functions.shinc"

echo
echo "################################# All networks configs update script ###################################"
echo "+++INFO: $(basename "$0") BEGIN $(date +%s) / $(date)"

echo "Current network is $NETWORK_TYPE"

MAIN_GLB_URL="https://raw.githubusercontent.com/tonlabs/main.ton.dev/master/configs/ton-global.config.json"
NET_GLB_URL="https://raw.githubusercontent.com/tonlabs/net.ton.dev/master/configs/ton-global.config.json"
FLD_GLB_URL="https://raw.githubusercontent.com/Custler/main.evs.dev/main/configs/fld.evs.dev/ton-global.config.json"
RFLD_GLB_URL="https://raw.githubusercontent.com/Custler/main.evs.dev/main/configs/rfld.evs.dev/ton-global.config.json"
SMFT_GLB_URL="https://raw.githubusercontent.com/Custler/smft.evs.dev/main/configs/smft.evs.dev/ton-global.config.json"

MAIN_CFG_DIR="$CONFIGS_DIR/main.evs.dev"
NET_CFG_DIR="$CONFIGS_DIR/net.evs.dev"
FLD_CFG_DIR="$CONFIGS_DIR/fld.evs.dev"
RFLD_CFG_DIR="$CONFIGS_DIR/rfld.evs.dev"
SMFT_CFG_DIR="$CONFIGS_DIR/smft.evs.dev"

[[ ! -d $HOME/logs ]] && mkdir -p $HOME/logs

declare -a net_list=($MAIN_CFG_DIR $NET_CFG_DIR $FLD_CFG_DIR $RFLD_CFG_DIR $SMFT_CFG_DIR)
declare -a g_url_list=($MAIN_GLB_URL $NET_GLB_URL $FLD_GLB_URL $RFLD_GLB_URL $SMFT_GLB_URL)
declare -a dir_list=($MAIN_CFG_DIR $NET_CFG_DIR $FLD_CFG_DIR $RFLD_CFG_DIR $SMFT_CFG_DIR)

for i in $(seq 0 $((${#g_url_list[@]} - 1)) )
do
    [[ ! -d ${dir_list[i]} ]] && mkdir -p ${dir_list[i]}
    echo -n "Update global config for ${net_list[i]##*/} network... "
    curl -o ${dir_list[i]}/$NET_GLOBAL_CONFIG_FILE ${g_url_list[i]}  &>/dev/null
    echo " ..DONE"
done

ParentScript="$(ps -o command= $PPID |awk -F'/' '{print $2}')"
if [[ "${ParentScript}" != "Setup.sh" ]];then
    cp -f "${CONFIGS_DIR}/${NETWORK_TYPE}/${NET_GLOBAL_CONFIG_FILE}" "${R_CFG_DIR}/"
fi

echo
echo "+++INFO: $(basename "$0") FINISHED $(date +%s) / $(date)"
echo "================================================================================================"

exit 0
