#!/bin/sh
echo "enter sim #"
read FILE


for (( ID = 1; ID <= 100; ID++ ))
do

FILE_NAME=expSim$FILE\_$ID.sh
rm -f $FILE_NAME
touch $FILE_NAME

echo "rep=$ID" >> $FILE_NAME

cat expSim$FILE.sh >> $FILE_NAME


done
