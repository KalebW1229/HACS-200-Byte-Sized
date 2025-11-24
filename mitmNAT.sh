#!/bin/bash

if [ $# -ne 3 ]
then
  echo "usage: ./mitmNAT.sh [CONTAINER_NAME] [EXTERNAL_IP] [MITM_PORT]"
  exit 1
fi

sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo forever -l /home/student/$1.log start -a /home/student/MITM/mitm.js -n $1 -i `sudo lxc-info -n $1 -iH` -p $3 --auto-access --auto-access-fixed 3 --debug --mitm-ip "127.0.0.1"
sudo ip addr add $2/24 brd + dev eth3
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $2 --jump DNAT --to-destination `sudo lxc-info -n $1 -iH`
sudo iptables --table nat --insert POSTROUTING --source `sudo lxc-info -n $1 -iH` --destination 0.0.0.0/0 --jump SNAT --to-source $2
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $2 --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:$3