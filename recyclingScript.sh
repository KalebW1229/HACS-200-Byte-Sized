#!/bin/bash

# Define IP pool and container pool
CONFIG_POOL=("snap0" "snap1" "snap2" "snap3")
IDLE_LIMIT=300
LIMIT=1800

# Function to randomly assign configurations to containers on recycle
if [[ "$1" == container1 ]]
then
  IP=128.8.238.72
  MITMPORT=1111
fi
if [[ "$1" == container2 ]]
then
  IP=128.8.238.91
  MITMPORT=1112
fi
if [[ "$1" == container3 ]]
then
  IP=128.8.238.123
  MITMPORT=1113
fi
if [[ "$1" == container4 ]]
then
  IP=128.8.238.136
  MITMPORT=1114
fi
if [[ "$1" == container5 ]]
then
  IP=128.8.238.217
  MITMPORT=1115
fi

assign_random_config() {
  RandConfig=$(shuf -e -n1 "${CONFIG_POOL[@]}")
}

# Function to recycle the container (restore snapshot and apply new config)
recycle_container() {
    assign_random_config
    /home/student/importFile.sh $1
    sudo iptables --delete INPUT -s "$attackerip" -d 127.0.0.1 -p tcp --jump ACCEPT
    sudo iptables --delete INPUT -d 127.0.0.1 -p tcp --dport "$MITMPORT" --jump DROP
    sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $IP --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:$MITMPORT
    sudo iptables --table nat --delete POSTROUTING --source "`sudo lxc-info -n $1 -iH`" --destination 0.0.0.0/0 --jump SNAT --to-source $IP
    sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $IP --jump DNAT --to-destination "`sudo lxc-info -n $1 -iH`"
    sudo ip addr delete $IP/24 brd + dev eth3
    forever_index=$(sudo forever list | grep "mitm.js -n $1" | awk '{print $2}' | tr -d '[]')
    sudo forever stop $forever_index
    sudo lxc-stop -n $1
    sudo lxc-snapshot -n $1 -r "$RandConfig" # Restore random config snapshot to container
    sudo lxc-start -n $1
    sleep 5
    /home/student/mitmNAT.sh $1 $IP $MITMPORT
    echo "Assigned configuration: $RandConfig" >> /home/student/$1.log
    sudo lxc-attach -n $1 -- chmod ugo+rwx /home
    sudo lxc-attach -n $1 -- chmod ugo+rwx /home/UMDHealthcare
    rm -r /home/student/$1.txt
    exit 0
}

if [[ -f /home/student/$1.txt ]]
then
  current_time=`date +%s`
  start_time=`tail -n 1 /home/student/$1.txt`
  time_difference=$((current_time - start_time))
  last_command_time=$(date -d "$(cat /home/student/$1.log | colrm 1 11 | colrm 9 | tail -n 1)" +%s)
  idle_time_difference=$((current_time - last_command_time))
  if [[ $time_difference -ge $LIMIT ]]
  then
    echo "RECYCLE REASON: 30 minutes haves passed" >> /home/student/$1.log
    recycle_container $1
  fi
  if [[ $idle_time_difference -ge $IDLE_LIMIT ]]
  then
      echo "RECYCLE REASON: Idle for 5 min" >> /home/student/$1.log
      recycle_container $1
  fi
  if [[ `cat /home/student/$1.log | grep "OpenSSH server closed connection" -c` -ge 1 ]]
  then
    echo "RECYCLE REASON: Attacker exited" >> /home/student/$1.log
    recycle_container $1
  fi
else
  if [[ `cat /home/student/$1.log | grep "Attacker\ authenticated" -c` -ge 1 ]]
  then
    echo `date +%s` > /home/student/$1.txt
    sleep 2
    attackerip=`cat /home/student/$1.log | grep "Attacker connected" | head -n 1 | cut -d' ' -f8`
    sudo iptables --insert INPUT -d 127.0.0.1 -p tcp --dport "$MITMPORT" --jump DROP
    sudo iptables --insert INPUT -s "$attackerip" -d 127.0.0.1 -p tcp --jump ACCEPT
  else
    exit 0
  fi
fi

# Retrying recycle if previous MITM did not stop fast enough
#if [[ `cat /home/student/$1.log | grep "Another MITM instance or another program" -c` -ge 1 ]]
#then
#  rm $1.log
#  /home/student/mitmNAT.sh $1 $IP $MITMPORT
#fi

#Retrying recycle if port isn't specifed (for some reason)
#if [[ `cat /home/student/$1.log | grep "error: required option '-p, --mitm-port <number>' not specified" -c` -ge 1 ]]
#then
#  rm $1.log
#  /home/student/mitmNAT.sh $1 $IP $MITMPORT
#fi
#exit 0