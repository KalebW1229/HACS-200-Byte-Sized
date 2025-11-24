#!/bin/bash
if [ $# -ne 2 ]
then
echo "usage: ./hw10.txt [CONTAINER_NAME] [EXTERNAL_IP]"
exit 1
fi
sudo forever -l ~/mitm_log start -a /home/student/MITM/mitm.js -n $1 -i `sudo lxc-info -n $1 -iH` -p 1111 --auto-access --auto-access-fixed 3 --debug
sudo ip addr add $2/16 brd + dev eth0
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $2 --jump DNAT --to-destination `sudo lxc-info -n $1 -iH`
sudo iptables --table nat --insert POSTROUTING --source `sudo lxc-info -n $1 -iH` --destination 0.0.0.0/0 --jump SNAT --to-source $2
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $2 --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:1111
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

THIS ONLY CHECKS ONE CONTAINER AND PUTS THE LOG IN "mitm_log" (can change this variable). 

Using README for comments:

- Checking the conditions for the recycling within the recycling script
- ^Due to this, the cronjob which runs the script will run every minute.
- Start the timer *after* the attacker connects
----------------------------------------------------------------------------------
Josh's notes
PRE SETUP:
1. Manually set up all containers (container1, container2, container4, container4)
2. Manually implement the 4 configurations into a container and take a snapshot for each configuration (do for each container)
3. Manually assign a given IP address to each of the containers and set up NAT rules and everything

RECYCLING:
1. Checks if any of the containers have surpassed the given lifespan (doesn't countdown until it's accessed by attacker)
	1.a Checks if it surpasses 5 minute idle time or 30 minute lifespan
2. If given lifespan is surpassed, randomly choose 1 of the 4 configurations and restore the container with a snapshot of the random configuration and send any necessary log files for data collection to a given directory on the home VM and reply with a message saying "Recycling x"
3. If given lifespan has NOT been surpassed, reply with a message saying "x is not ready to be Recycled"
4. Repeat every minute.

HOW ?
1. Cronjob and MITM

WHAT DOES PRE SETUP ACHIEVE?
1. Cuts down many unnecessary lines in script making it run faster
2. Prevents any mishaps with ip addresses and the like
---------------------------------------------------------------------------
MADE CHANGES 
1. replaced the config names with snap0 snap 1 snap 2 snap3 (CAN'T CHANGE SNAPSHOT NAMES IDK WHY)
2. recycle_container() {
    local container="$1"
    local ip="$2"
    
    assign_random_config
    sudo lxc-stop -n $container
    sudo lxc-snapshot -n $container -r "$RandConfig"  # Restore random config snapshot to container
    sudo lxc-start -n $container
    TEST_START=$(date '+%m/%d/%Y %H:%M:%S')
    echo "$container - $RandConfig started at $TEST_START" >> timer_$container.log
    apply_nat_rules "$container" "$ip"
    echo "$container started with $RandConfig at IP $ip"
}
3. Tested the script and it works. The only problem are the errors setting up the ip rules and such and fixing the time check. It's better to set up the stuff I mentioned above manually rather than putting it into the script. We don't need to randomize the ip's and everything - ALSO asked the TAs something on Slack too for clarification if you wanted to check it out

