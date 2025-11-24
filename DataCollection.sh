#!/bin/bash

# VERY BASIC BTW THIS JUST COUNTS THE NUMBER OF LINES ATTACKER HAS ENTERED SHOWS 
# I'll add more to this once I have more time and I'm not dying studying for CS - Nathan

# Variable names, since we've been receiving a lot of brute force attacks the number of "attacks" might be very inflated
attack_number = cat $1 | grep -c "Attacker connected"
uniq_attack_number = cat $1 | grep "Attacker connected" | cut -d " " -f 8 | sort -u | wc -l

# Output the vars we made
echo "Number of attacks on this container: $attack_number"
echo "Number of unique attackers: $uniq_attack_number"
