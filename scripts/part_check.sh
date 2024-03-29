#!/usr/bin/env bash

# (C) Sergey Tyurin  2021-10-19 10:00:00

# Disclaimer
##################################################################################################################
# You running this script/function means you will not blame the author(s).
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
echo
echo "#################################### Check participations script ########################################"
echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date  +'%F %T %Z')"

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/functions.shinc"

# #=================================================
# # for icinga
# if [[ -f "${partInElections}" ]]; then echo "" > "${partInElections}"; fi
# if [[ -f "${nodeStats}" ]]; then echo "" > "${nodeStats}"; fi

#=================================================
echo
echo -e "$(DispEnvInfo)"
echo
echo -e "$(Determine_Current_Network)"
echo

# =====================================================
Depool_addr=`cat ${KEYS_DIR}/depool.addr`
Validator_addr=`cat ${KEYS_DIR}/${VALIDATOR_NAME}.addr`

# =====================================================
elector_addr="$(Get_Elector_Address)"
elections_id="$(Get_Current_Elections_ID)"
echo "INFO: Elections ID: ${elections_id}"
echo "INFO: DePool Address:    $Depool_addr"
echo "INFO: Validator Address: $Validator_addr"

Engine_ADNL_Info="$(Get_Engine_ADNL)"
if [[ "$Engine_ADNL_Info" == "null" ]];then
    echo "+++-WARNING(line $LINENO): You have not participated in any elections yet!"
    echo
    exit 0
fi

ADNL_KEY="$1"
###### 
if [ "$elections_id" == "0" ]; then
    Curr_ADNL_Key=`echo $Engine_ADNL_Info|awk '{print $3}'`
    [[ -z $Curr_ADNL_Key ]] && Curr_ADNL_Key=`echo $Engine_ADNL_Info|awk '{print $1}'`
    ADNL_KEY=${ADNL_KEY:=$Curr_ADNL_Key}
    echo "INFO: Validator ADNL:    $ADNL_KEY"

    VALS_DEF="NEXT"
    echo
    date +"INFO: %F %T No current elections"
    Part_VAL="$(P36_ADNL_search $ADNL_KEY)"
    if [[ "${Part_VAL}" == "null" ]];then
        Part_VAL="$(P34_ADNL_search $ADNL_KEY)"
        VALS_DEF="CURRENT"
    fi
    
    FOUND_PUB_KEY=`echo "$Part_VAL" |awk '{print $1}'`
    if [[ "$FOUND_PUB_KEY" == "absent" ]];then
        echo "###-ERROR: Your ADNL Key NOT FOUND in current or next validators list!!!"
        "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server:" "$Tg_SOS_sign ###-ERROR: Your ADNL Key NOT FOUND in current or next validators list!!!" 2>&1 > /dev/null

        echo "-----------------------------------------------------------------------------------------------------"
        echo
        # for icinga
        echo "ERROR ADNL NOT FOUND IN P34 OR P36 CONFIG" > "${nodeStats}"
        exit 1
    fi

    VAL_WEIGHT=`echo "$Part_VAL" | awk '{print $2}'`
    echo
    echo "INFO: Found you in $VALS_DEF validators with weight $(echo "scale=3; ${VAL_WEIGHT} / 10000000000000000" | $CALL_BC)%"
    echo "INFO: Your public key: $FOUND_PUB_KEY"
    echo "INFO: Your   ADNL key: $(echo "$ADNL_KEY" | tr "[:upper:]" "[:lower:]")"
    echo "-----------------------------------------------------------------------------------------------------"
    echo
    exit 0
fi

Next_ADNL_Key=`echo $Engine_ADNL_Info|awk '{print $3}'`
[[ -z $Next_ADNL_Key ]] && Next_ADNL_Key=`echo $Engine_ADNL_Info|awk '{print $1}'`
ADNL_KEY=${ADNL_KEY:=$Next_ADNL_Key}
echo "INFO: Validator ADNL:    $ADNL_KEY"
echo
echo "Now is $(date +'%F %T %Z')"
new_val_round_date="$(echo "$elections_id" | gawk '{print strftime("%Y-%m-%d %H:%M:%S", $1)}')"

ADNL_FOUND="$(Elector_ADNL_Search $ADNL_KEY)"
if [[ "$ADNL_FOUND" == "absent" ]];then
    echo -e "${Tg_SOS_sign}###-ERROR: Can't find you in participant list in Elector. account: ${Depool_addr}"
    "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server:" "$Tg_SOS_sign ###-ALARM: Can't find you in participant list in Elector for elections $elections_id ($new_val_round_date). account: ${Depool_addr}" 2>&1 > /dev/null
    # for icinga
    echo "ERROR NOT IN PARTICIPANT LIST" > "${nodeStats}"
    exit 1
fi

Your_Stake=`echo "${ADNL_FOUND}" | awk '{print $1 / 1000000000}'`
You_PubKey=`echo "${ADNL_FOUND}" | awk '{print $4}'`
You_BLSKey=`echo "${ADNL_FOUND}" | awk '{print $5}'`

echo "---INFO: Your stake: $Your_Stake with ADNL: $(echo "$ADNL_KEY" | tr "[:upper:]" "[:lower:]")"
echo "You BLS key in Elector:    $You_BLSKey"
echo "You public key in Elector: $You_PubKey"
echo "You will start validate from $(TD_unix2human ${elections_id})"


TON_LIVE_URL=""
# "https://ton.live/validators?section=details&public_key=${You_PubKey}&key_block_num=undefined"
"${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server:" "$Tg_CheckMark We are successfully participate in elections $elections_id ($new_val_round_date) with stake $Your_Stake and ADNL:  $(echo "$ADNL_KEY" | tr "[:upper:]" "[:lower:]") ${TON_LIVE_URL}" 2>&1 > /dev/null
echo "-----------------------------------------------------------------------------------------------------"
echo $elections_id > ${ELECTIONS_WORK_DIR}/curent_elections_id.txt
# for icinga
echo "INFO
ELECTION ID ${elections_id} ;
DEPOOL ADDRESS $Depool_addr ;
VALIDATOR ADDRESS $Validator_addr ;
STAKE $Your_Stake ;
ADNL ${ADNL_KEY} ;
KEY IN ELECTOR $You_PubKey ;
" > "${nodeStats}"

# ==========================================
# Delete files older 7 days in elections log dirs
find "$ELECTIONS_WORK_DIR" -maxdepth 1 -type f -mtime +7 -name '*' -ls -exec rm {} \;  &>/dev/null
find "$ELECTIONS_HISTORY_DIR" -maxdepth 1 -type f -mtime +7 -name '*' -ls -exec rm {} \; &>/dev/null

# ==========================================

echo "+++INFO: $(basename "$0") FINISHED $(date +%s) / $(date  +'%F %T %Z')"
echo "================================================================================================"

exit 0
