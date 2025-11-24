#!/bin/bash

# Base firewall rules
sudo modprobe br_netfilter
sudo sysctl -p /etc/sysctl.conf
sudo /home/student/firewall_rules.sh

# Remove container log and text files
sudo rm /home/student/container1.log /home/student/container2.log /home/student/container3.log /home/student/container4.log /home/student/container5.log
sudo rm /home/student/container1date.txt /home/student/container2date.txt /home/student/container3date.txt /home/student/container4date.txt /home/student/container5date.txt
sudo rm /home/student/container1.txt /home/student/container2.txt /home/student/container3.txt /home/student/container4.txt /home/student/container5.txt

# Assigning random configuration
CONFIG_POOL=("snap0" "snap1" "snap2" "snap3")

assign_random_config() {
  RandConfig=$(shuf -e -n1 "${CONFIG_POOL[@]}")
}

# External IP set up
sudo ip link set dev eth3 up
sudo ip addr add 128.8.238.72/24 brd + dev eth3
sudo ip addr add 128.8.238.91/24 brd + dev eth3
sudo ip addr add 128.8.238.123/24 brd + dev eth3
sudo ip addr add 128.8.238.136/24 brd + dev eth3
sudo ip addr add 128.8.238.217/24 brd + dev eth3

# Starting containers
sudo lxc-start container1
sudo lxc-start container2
sudo lxc-start container3
sudo lxc-start container4
sudo lxc-start container5
sleep 10

# Applying random configurations
assign_random_config
sudo lxc-snapshot -n container1 -r $RandConfig
sudo lxc-snapshot -n container2 -r $RandConfig
sudo lxc-snapshot -n container3 -r $RandConfig
sudo lxc-snapshot -n container4 -r $RandConfig
sudo lxc-snapshot -n container5 -r $RandConfig
sleep 15

# Giving permissions
sudo lxc-attach -n container1 -- chmod ugo+rwx /home/UMDHealthcare
sudo lxc-attach -n container2 -- chmod ugo+rwx /home/UMDHealthcare
sudo lxc-attach -n container3 -- chmod ugo+rwx /home/UMDHealthcare
sudo lxc-attach -n container4 -- chmod ugo+rwx /home/UMDHealthcare
sudo lxc-attach -n container5 -- chmod ugo+rwx /home/UMDHealthcare
sleep 5

# Call mitmNat script
sudo /home/student/mitmNAT.sh container1 128.8.238.72 1111
sudo /home/student/mitmNAT.sh container2 128.8.238.91 1112
sudo /home/student/mitmNAT.sh container3 128.8.238.123 1113
sudo /home/student/mitmNAT.sh container4 128.8.238.136 1114
sudo /home/student/mitmNAT.sh container5 128.8.238.217 1115
sleep 10

# Echo assigned config
echo "Assigned configuration: $RandConfig" >> /home/student/container1.log
echo "Assigned configuration: $RandConfig" >> /home/student/container2.log
echo "Assigned configuration: $RandConfig" >> /home/student/container3.log
echo "Assigned configuration: $RandConfig" >> /home/student/container4.log
echo "Assigned configuration: $RandConfig" >> /home/student/container5.log