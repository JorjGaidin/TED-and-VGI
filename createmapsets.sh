#!/bin/sh

echo "Sim runs to create:"
read SIM

mkdir output/expSim$SIM

for (( ID = 1; ID <= 100; ID++ ))
do

g.mapset -c expSim$SIM\_$ID

done 


