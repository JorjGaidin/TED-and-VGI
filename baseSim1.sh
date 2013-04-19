# Base TED simulation model
# Author: Shaun Langley
# Last Modified 3/25/2013

years="2003 2004 2005 2006"

times="001  017  033  049  065  081  097  113  129  145  161  177  193  209  225  241  257  273  289  305  321  337  353"

# The model will loop through each year and time value noted here.

g.mapset -c baseSim1 # create a seperate mapset for each simulation to isolate output from each other to prevent possible data overwrite
g.mremove rast=* -f
g.region Kenya
r.mapcalc "distrib.tmp=initDistrib"

for year in $years; do
	for i in $times; do
		NDVImap=`g.mlist type=rast pat="bin${year}_${i}_NDVI"`
		LSTDaymap=`g.mlist type=rast pat="bin${year}_${i}_Day_LST_250m_Terra_16day"`
		LSTNightmap=`g.mlist type=rast pat="bin${year}_${i}_Night_LST_250m_Aqua_16day"`
		LULCmap=`g.mlist type=rast pat="bin${year}_LULC_Type_1_250m"`
		r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap * $LULCmap)"
		r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o 
		r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"
		g.copy distrib.tmp,distrib.$year.$i
	done
done

g.remove distrib.tmp
g.remove distrib.grown.tmp

g.region zoom=studyarea	
r.mask studyarea

r.series input=`g.mlist pat=distrib.200[4-6].* sep=,` output=baseSim_average method=average
r.series input=`g.mlist pat=distrib.200[4-6].* sep=,` output=baseSim_sum method=sum
r.series input=`g.mlist pat=distrib.2004.* sep=,` output=baseSim_2004_average method=average
r.series input=`g.mlist pat=distrib.2004.* sep=,` output=baseSim_2004_sum method=sum
r.series input=`g.mlist pat=distrib.2005.* sep=,` output=baseSim_2005_average method=average
r.series input=`g.mlist pat=distrib.2005.* sep=,` output=baseSim_2005_sum method=sum
r.series input=`g.mlist pat=distrib.2006.* sep=,` output=baseSim_2006_average method=average
r.series input=`g.mlist pat=distrib.2006.* sep=,` output=baseSim_2006_sum method=sum

r.mask -r

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F description="TED base simulation complete"

	
