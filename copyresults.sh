echo "Enter Simulation #: "
read sim

g.mapset results

for i in `seq 1 1 100`; do

	file=sim$sim\_run$i\_sum
	g.copy $file\@expSim$sim\_$i,$file

	file=sim$sim\_run$i\_average
	g.copy $file\@expSim$sim\_$i,$file

	for year in `seq 2004 1 2006`; do	

		file=sim$sim\_$year\_run$i\_sum
		g.copy $file\@expSim$sim\_$i,$file

		file=sim$sim\_$year\_run$i\_average
		g.copy $file\@expSim$sim\_$i,$file

	done
done

	
