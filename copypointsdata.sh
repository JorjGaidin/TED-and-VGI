echo "Enter Simulation #: "
read sim

g.mapset results


years="2004 2005 2006"
times=`seq -w 1 16 365`
runs=`seq 1 1 100`

for year in $years; do
	for ptime in $times; do
		for i in $runs; do
			if [ $i -eq 1 ]; then
    			g.copy vect=sim${sim}_pts_${year}_${ptime}_run${i}@expSim${sim}_${i},sim${sim}_pts_${year}_${ptime}
   			fi
   			if [ $i -gt  1 ]; then  
    		v.patch input=sim${sim}_pts_${year}_${ptime}_run${i}@expSim${sim}_${i} output=sim${sim}_pts_${year}_${ptime} -e -a --o
   			fi
  		done
 	done
done

	
