# Simulation 34 - consider the base model without the LULC input
# Author: Shaun Langley
# Last Modified 3/25/2013

years="2004 2005 2006"

times="001  017  033  049  065  081  097  113  129  145  161  177  193  209  225  241  257  273  289  305  321  337  353"

# The model will loop through each year and time value noted here.

g.mapset -c expSim34_$rep # create a seperate mapset for each simulation to isolate output from each other to prevent possible data overwrite
g.mremove rast=* -f
g.region Kenya
r.mapcalc "distrib.tmp=initDistrib"

for year in $years; do
	for i in $times; do
		NDVImap=`g.mlist type=rast pat="bin$year\_$i\_NDVI"`
		LSTDaymap=`g.mlist type=rast pat="bin$year\_$i\_Day_LST_250m_Terra_16day"`
		LSTNightmap=`g.mlist type=rast pat="bin$year\_$i\_Night_LST_250m_Aqua_16day"`
		r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap)"
		r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o 
		r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"
		g.copy distrib.tmp,distrib.$year.$i.run$rep
	done
done

g.remove distrib.tmp
g.remove distrib.grown.tmp

g.region zoom=studyarea	
r.mask studyarea
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim34_$rep` output=sim34_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim34_$rep` output=sim34_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim34_$rep` output=sim34_2004_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim34_$rep` output=sim34_2004_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim34_$rep` output=sim34_2005_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim34_$rep` output=sim34_2005_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim34_$rep` output=sim34_2006_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim34_$rep` output=sim34_2006_run$rep\_sum method=sum

r.mask -r

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F description="TED  simulation 34 run $rep complete"

	
