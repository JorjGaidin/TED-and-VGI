# echo "Enter Simulation #: "
# read sim

sim=1

g.mapset results

# for i in `seq 1 1 100`; do
# 
# 	file=sim$sim\_run$i\_sum
# 	g.copy $file\@expSim$sim\_$i,$file
# 
# 	file=sim$sim\_run$i\_average
# 	g.copy $file\@expSim$sim\_$i,$file
# 
# 	for year in `seq 2004 1 2006`; do	
# 
# 		file=sim$sim\_$year\_run$i\_sum
# 		g.copy $file\@expSim$sim\_$i,$file
# 
# 		file=sim$sim\_$year\_run$i\_average
# 		g.copy $file\@expSim$sim\_$i,$file
# 
# 	done
	
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

