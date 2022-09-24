#!/bin/bash -x
rootdir="$HOME/dev"
devin="$rootdir/devices.json"
infile="$rootdir/nmap.in"
fparse="$rootdir/nmap.parse"

nmap -sn 192.168.1.1/24 > $infile
dt=$(date '+%Y-%m-%d %H:%M:%S')
printf '{"job_date":"%s"\n' "$dt" > $devin
printf ',"devices":[\n' >> $devin

#printf 'parse_date:%s\n' "$dt" > $fparse
printf "" > $fparse 
while read y
do
  if [[ $y == *"192.168.1"* ]]; then 
    ip=$( echo "$y" |cut -d ' ' -f5 )
    if [[ $ip != *"192.168.1"* ]]; then 
      ip=$( echo "$y" |cut -d ' ' -f6 )
    fi
    ip=${ip/(/}
    ip=${ip/)/} 
    printf '%s\n' "$ip" >> $fparse 

    get=$(curl --max-time 5 "http://$ip/state") #--silent#--show-error
    if [[ $get == *"Shelly"* ]]; then
      printf "$get" >> $devin
      printf "," >> $devin
    fi
  fi
done < $infile
printf "]}" >> $devin
sed -i 's/,]}/]}/g' $devin

post =$(curl -vX POST http://localhost:8080/dev.json -d @$devin \--header "Content-Type: application/json")
