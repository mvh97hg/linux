#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# send_alert.sh - Bash shell script
# Copyright 2012-2020, Tam Do Minh <dominhtam.94@gmail.com> - Skype <dominhtam.94>

# This program is free software: you can redistribute it and/or modify 
# it under the terms of GNU General Public License as plblished by 
# the Free Software Foundation,either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# Revision history:
# 2022-03-31	Created
# 2022-04-15    Add feature check TBW based on Brands(Corsair, INTEL, SAMSUNG, SANDISK) with 2 functions: checkSizeStorage, checkTBW
# ---------------------------------------------------------------------------
PROGNAME=${0##*/}
VERSION="3.5"

# global variable
DATE=$(date "+%T, %d-%B, %Y")
HOME_FOLDER="/vinahost"
Attribute=("HDD Device" "HDD Model" "HDD Size" "Temperature" "Highest Temp" "Health" "Performance" "Est. lifetime" "Total written" "Bad sector")

# function isEmptyString()
# {
#     local -r string="${1}"

#     if [[ "$(trimString "${string}")" = '' ]]
#     then
#         echo 'true' && return 0
#     fi

#     echo 'false' && return 1
# }

# function isPositiveInteger()
# {
#     local -r string="${1}"

#     if [[ "${string}" =~ ^[1-9][0-9]*$ ]]
#     then
#         echo 'true' && return 0
#     fi

#     echo 'false' && return 1
# }

# function trimString()
# {
#     local -r string="${1}"

#     sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
# }

# function printTable()
# {
#     local -r delimiter="${1}"
#     local -r tableData="$(removeEmptyLines "${2}")"
#     local -r colorHeader="${3}"
#     local -r displayTotalCount="${4}"

#     if [[ "${delimiter}" != '' && "$(isEmptyString "${tableData}")" = 'false' ]]
#     then
#         local -r numberOfLines="$(trimString "$(wc -l <<< "${tableData}")")"

#         if [[ "${numberOfLines}" -gt '0' ]]
#         then
#             local table=''
#             local i=1

#             for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
#             do
#                 local line=''
#                 line="$(sed "${i}q;d" <<< "${tableData}")"

#                 local numberOfColumns=0
#                 numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

#                 # Add Line Delimiter

#                 if [[ "${i}" -eq '1' ]]
#                 then
#                     table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
#                 fi

#                 # Add Header Or Body

#                 table="${table}\n"

#                 local j=1

#                 for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
#                 do
#                     table="${table}$(printf '#|  %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
#                 done

#                 table="${table}#|\n"

#                 # Add Line Delimiter

#                 if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
#                 then
#                     table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
#                 fi
#             done

#             if [[ "$(isEmptyString "${table}")" = 'false' ]]
#             then
#                 local output=''
#                 output="$(echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1')"

#                 if [[ "${colorHeader}" = 'true' ]]
#                 then
#                     echo -e "\033[1;32m$(head -n 3 <<< "${output}")\033[0m"
#                     tail -n +4 <<< "${output}"
#                 else
#                     echo "${output}"
#                 fi
#             fi
#         fi

#         if [[ "${displayTotalCount}" = 'true' && "${numberOfLines}" -ge '0' ]]
#         then
#             echo -e "\n\033[1;36mTOTAL ROWS : $((numberOfLines - 1))\033[0m"
#         fi
#     fi
# }

# function removeEmptyLines()
# {
#     local -r content="${1}"

#     echo -e "${content}" | sed '/^\s*$/d'
# }

# function repeatString()
# {
#     local -r string="${1}"
#     local -r numberToRepeat="${2}"

#     if [[ "${string}" != '' && "$(isPositiveInteger "${numberToRepeat}")" = 'true' ]]
#     then
#         local -r result="$(printf "%${numberToRepeat}s")"
#         echo -e "${result// /${string}}"
#     fi
# }


function get_hdsentinel()
{
    # local -r URL="http://210.211.122.233/files/Checkdisk/hdsentinel-019c-x64"
    local -r URL="https://github.com/tamdm/bash/raw/master/hdsentinel"
    if [[ ! -f "${HOME_FOLDER}/hdsentinel" ]]
    then
        $( curl -m 5 -L ${URL} --output ${HOME_FOLDER}/hdsentinel && chmod +x "${HOME_FOLDER}/hdsentinel"  ) ||  (sendMessageToTelegram "Error: ${URL} not found. Please manual check!" && exit 1)
    fi

    cd "${HOME_FOLDER}" && ./hdsentinel > report
    
}
function sendMessageToTelegram() 
{
    local IP=$(curl -s https://ip.vinahost.vn || (hostname -I | awk '{print $1}'))
    local token_id="1126087523:AAG38a7Fm_ZJDey1LXFgdJZLH_WLYpUeWtk"
    local group_id="-1001728646671"
    local -r URL="https://api.telegram.org/bot$token_id/sendMessage"

    curl -s -X POST $URL -d chat_id=$group_id -d text="

    ########### ALERT MESSAGE ###########

    PLEASE CALL ADMIN OR NETWORK FOR CHECK !!!
    
    ###################################### 
    IP Adress: "${IP}"
    ######################################
    
    $(echo "${1}")
    
    ######################################
    Thời gian: ${DATE}
    ######################################" > /dev/null

}
function formatData() 
{
    while IFS= read -r line;
    do
        for val in "${Attribute[@]}";
        do
            case "${line}" in 
                *"${val}"*)
                    echo "${line}" >> "${HOME_FOLDER}/disk.txt"
                ;;
            esac
        done    
        case "${line}" in 
            *"PERFECT"*)
                echo "Bad sector   : 0" >> disk.txt
            ;;
            *"bad sectors"*)
                local num=$(echo "$line" | sed 's/[^0-9]*\([0-9]\+\).*/\1/')
                echo "Bad sector   : "${num}"" >> "${HOME_FOLDER}/disk.txt"
            ;;
        esac
    done < "${HOME_FOLDER}/report"

    cd "${HOME_FOLDER}" && split -l 10 disk.txt -a 1 sd && rm -f "${HOME_FOLDER}/disk.txt"
    [[ "$(grep "Unknown" ${HOME_FOLDER}/sd* | cut -d":" -f1 | head -n1)" ]] && rm -f "${HOME_FOLDER}/$(grep "Unknown" sd* | cut -d":" -f1 | head -n1)"
}

function checkProblemAttribute()
{
    while IFS= read -r line;
    do
        case "${line}" in

            *"Model"*)
                local -r brand_SSD=$(echo $line | awk '{print $5}')
                ;;
            *"Size"*)
                local num_size=$(echo "$line" | sed 's/[^0-9]*\([0-9]\+\).*/\1/')
                checkSizeStorage
                ;;
            *"Highest Temp"*)
                local -r num_temp=$(echo "$line" | sed 's/[^0-9]*\([0-9]\+\).*/\1/')
                ;;
            *"Health"*)
                local -r num_health=$(echo "$line" | sed 's/[^0-9]*\([0-9]\+\).*/\1/')
                ;;
            *"Performance"*)
                local -r num_perform=$(echo "$line" | sed 's/[^0-9]*\([0-9]\+\).*/\1/')
                ;;
            *"Est. lifetime"*)
                local -r num_lifetime=$(echo "$line" | sed 's/[^0-9]*\([0-9]\+\).*/\1/')
                ;;
            *"Total written"*)
                local -r data_IEC=$(echo "$line" | awk '{print $4}') # Phân loại SSD đã ghi GB hay tới TB
                local -r num_totalwritten=$(echo "$line" | sed 's/[^0-9]*\([0-9]\+\).*/\1/') # Lấy số lượng GB or TB đã ghi được
                checkTBW
                ;;
            *"Bad sector"*)
                local -r num_badsector=$(echo "$line" | sed 's/[^0-9]*\([0-9]\+\).*/\1/')
                ;;
        esac

    done < "${HOME_FOLDER}/${1}"

    local trigger_TBW="false" 
    if [[ "${data_IEC}" == "TB" && "${num_totalwritten}" -ge "${threshold}" ]]
    then
        trigger_TBW="true"
    fi

    if [[ "${num_temp}" -ge 60 || "${num_health}" -le 50 || "${num_perform}" -le 50 || "${num_lifetime}" -le 100 || "${trigger_TBW}" == "true" || "${num_badsector}" -ge 1 ]] 
    then
        local content=$(cat "${HOME_FOLDER}/${1}")
        sendMessageToTelegram "${content}"
    fi
}

function checkSizeStorage()
{   
    num_size=$((num_size/1000))
    if [[ "${num_size}" -le 200 ]]
    then
        ssd_size=120
    elif [[ "${num_size}" -le 300 ]]
    then
        ssd_size=248
    elif [[ "${num_size}" -le 600 ]]
    then
        ssd_size=512
    elif [[ "${num_size}" -le 1100 ]]
    then
        ssd_size=1024
    elif [[ "${num_size}" -le 2100 ]]
    then 
        ssd_size=2048
    else
        ssd_size=4906
    fi 
}

function checkTBW()
{
    if [[ "${brand_SSD}" == "Corsair" ]]
    then
        if [[ "${ssd_size}" -eq 120 || "${ssd_size}" -eq 248 ]]
        then
            threshold=$(( 87*80/100 ))
        elif [[ "${ssd_size}" -eq 512 ]] 
        then 
            threshold=$((200*80/100))
        elif [[ "${ssd_size}" -eq 1024 ]] 
        then
            threshold=$((400*80/100))
        elif [[ "${ssd_size}" -eq 2048 || "${ssd_size}" -eq 4096 ]]
        then 
            threshold=$((500*80/100))
        fi
    fi    
    
    if [[  "${brand_SSD}" == "INTEL" ]]
    then
        if [[ "${ssd_size}" -eq 120 || "${ssd_size}" -eq 248 ]]
        then
            threshold=$((900*80/100 ))
        elif [[ "${ssd_size}" -eq 512 ]] 
        then 
            threshold=$((1200*80/100))
        elif [[ "${ssd_size}" -eq 1024 ]] 
        then
            threshold=$((3400*80/100))
        elif [[ "${ssd_size}" -eq 2048 ]]
        then 
            threshold=$((7100*80/100))
        elif [[ "${ssd_size}" -eq 4096 ]]
        then 
            threshold=$((13100*80/100))
        fi
    fi    

    if [[ "${brand_SSD}" == "SAMSUNG" ]]
    then
        if [[ "${ssd_size}" -eq 120 || "${ssd_size}" -eq 248 ]]
        then
            threshold=$((150*80/100 ))
        elif [[ "${ssd_size}" -eq 512 ]] 
        then 
            threshold=$((300*80/100))
        elif [[ "${ssd_size}" -eq 1024 ]] 
        then
            threshold=$((600*80/100))
        elif [[ "${ssd_size}" -eq 2048 || "${ssd_size}" -eq 4096 ]]
        then 
            threshold=$((1200*80/100))
        fi
    fi    

    if [[ "${brand_SSD}" == "SanDisk" ]]
    then
        if [[ "${ssd_size}" -eq 120 || "${ssd_size}" -eq 248 ]]
        then
            threshold=$((100*80/100 ))
        elif [[ "${ssd_size}" -eq 512 ]] 
        then 
            threshold=$((200*80/100))
        elif [[ "${ssd_size}" -eq 1024 ]] 
        then
            threshold=$((400*80/100))
        elif [[ "${ssd_size}" -eq 2048 || "${ssd_size}" -eq 4096 ]]
        then 
            threshold=$((500*80/100))
        fi
    fi    
}
function checkProblemDisk() 
{
    local -r disk_array=$(cd "${HOME_FOLDER}"; ls sd*)
    for disk in ${disk_array[@]};
        do 
           checkProblemAttribute "${disk}" 
        done
}

function CheckRaid() 
{
    Raid_Failed="false"
    MDADM=$(df -h | grep "/md" | wc -l)
    ZFS=$(mount | grep zfs | wc -l)

    if [[ "${MDADM}" -ge 1 ]]
    then
        condition=$(/usr/bin/grep "\[.*_.*\]" /proc/mdstat)
        if [[ "${condition}" ]]
        then
            Raid_Failed="true"
            /usr/bin/cat /proc/mdstat > "${HOME_FOLDER}/raid" 
        fi
    fi

    if [[ "${ZFS}" -ge 1 ]]
    then
        condition=$(/sbin/zpool status | egrep -w -i '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')
        errors=$(/sbin/zpool status | grep ONLINE | grep -v state | awk '{print $3 $4 $5}' | grep -v 000)
        if [[ "${condition}" || "${errors}" ]] 
        then
            Raid_Failed="true"
            zpool status > "${HOME_FOLDER}/raid" 
        fi
    fi

    if [[ "${Raid_Failed}" == "true" ]]
    then
        local content=$(cat "${HOME_FOLDER}/raid")
        sendMessageToTelegram "${content}"
    fi
}

function checkCable()
{
    sata_fail="false"
    while IFS= read -r line;
    do
        case "${line}" in 
            *"Problems occurred"*)
                sata_fail="true"
                ;;
            *"crash"*)
                sata_fail="true"   
                ;;
            *"blue-screen-of-death"*)
                sata_fail="true"
                ;;
        esac
    done < "${HOME_FOLDER}/report"

    if [[ "${sata_fail}" == "true" ]]
    then
        content=$(grep "Problems occurred\|crash\|blue-screen-of-death" "${HOME_FOLDER}/report")
        sendMessageToTelegram "${content}"
    fi

}
function main() 
{
    [[ $EUID -ne 0 ]] && sendMessageToTelegram "Error: ${0} must be run as root!" && exit 1
    get_hdsentinel    
    formatData
    checkProblemDisk
    CheckRaid
    checkCable
    cd "${HOME_FOLDER}" && rm -f sd* report raid &>/dev/null
}
main "${@}"
