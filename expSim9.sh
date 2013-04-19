##########################
# simulation 9 - neighbors + occupied (t-1)
# Author: Shaun Langley
# Last Modified 3/25/2013


g.mapset -c expSim9_$rep
g.mapset addmapset=baseSim1
g.mremove rast=* -f
g.mremove vect=* -f
g.region Kenya 
r.mapcalc "distrib.tmp=initDistrib"

years="2004 2005 2006"

times=`seq -w 1 16 365`

lasttime=2003.353

for year in $years; do
	for i in $times; do
		NDVImap=`g.mlist type=rast pat="bin$year\_$i\_NDVI"`
		LSTDaymap=`g.mlist type=rast pat="bin$year\_$i\_Day_LST_250m_Terra_16day"`
		LSTNightmap=`g.mlist type=rast pat="bin$year\_$i\_Night_LST_250m_Aqua_16day"`
		LULCmap=`g.mlist type=rast pat="bin$year\_LULC_Type_1_250m"`
		r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap * $LULCmap)"
		r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o --quiet
		r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"
		echo "if portion of the loop"
		r.neighbors input=distrib.tmp output=neighbors size=3 method=maximum --o
		echo "t-1 is distrib.$lasttime"
		r.mapcalc "ptsarea=(distrib.$lasttime * neighbors * studyarea)"
		r.null ptsarea setnull=0
		r.random input=ptsarea raster_output=pts vector_output=sim9_pts_$year\_$i\_run$rep n=100 --o --quiet
		r.null pts null=0
		sum=$(r.sum pts | sed 's/^SUM = //' | sed 's/\..*//')
		echo "There are $sum points"
		r.mapcalc "distrib.tmp=if(pts ==1, 1,distrib.tmp)"
		g.copy distrib.tmp,distrib.$year.$i --quiet
		g.remove suitable.$year.$i --quiet
		g.remove pts --quiet
		g.remove ptsarea --quiet
		lasttime=$year.$i
	done
done


g.remove distrib.tmp
g.remove distrib.grown.tmp

g.region zoom=studyarea	
r.mask studyarea
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim9_$rep` output=sim9_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim9_$rep` output=sim9_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim9_$rep` output=sim9_2004_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim9_$rep` output=sim9_2004_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim9_$rep` output=sim9_2005_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim9_$rep` output=sim9_2005_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim9_$rep` output=sim9_2006_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim9_$rep` output=sim9_2006_run$rep\_sum method=sum


r.mask -r


curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="HPCC" -F description="TED simulation 9, run $rep complete"


