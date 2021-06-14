#!/bin/bash
#
# Script Name: config_generator.sh
#
# Author: Fernando Homem da Costa, Thiago Bastos
# Date : 12/06/2021
#
# Description: The following script reads in a text file called /path/to/file 
#              and creates a new file called /path/to/newfile
#
# Run Information: This script is run automatically every Monday of every week at 20:00hrs from
#                  a crontab entry. 
#
# Error Log: Any errors or output associated with the script can be found in /path/to/logfile
#

while getopts n: flag
do
    case "${flag}" in
        n) nodes=${OPTARG};;
    esac
done

for i in $(seq 1 $nodes);
    do eval 'love . $i $nodes' & 
done
echo "Number of nodes: $nodes";
wait
