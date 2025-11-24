#!/bin/bash

# Define the current configuration
config=$(grep "Assigned configuration: " /home/student/$1.log | awk '{print $NF}')
date '+%m-%d-%Y-%I:%M:%S-%p' > /home/student/$1date.txt
date=`cat /home/student/$1date.txt | tail -n 1`

# Start with an increment of 1
counter=1

# Loop to find the next available file name
while [[ -e "/home/student/$config/$config.log$counter*" ]]; do
    ((counter++))
done

# Move or copy your file to the target directory with the incremented name
mv /home/student/$1.log "/home/student/$config/$config.log$counter-$date"
rm $1date.txt