# estimated time: 45min (laptop), 72min (dev node)
##########################
# 100 points - accept those that fall on unsuitable habitat
# Author: Shaun Langley
# Last Modified 3/25/2013


g.mapset -c expSim17_$rep
g.mremove rast=* -f
g.mremove vect=* -f
g.region Kenya
r.mapcalc "distrib.tmp=initDistrib"

years="2004 2005 2006"

times="001  017  033  049  065  081  097  113  129  145  161  177  193  209  225  241  257  273  289  305  321  337  353"

for year in $years; do
	for i in $times; do
		NDVImap=bin$year\_$i\_NDVI
		LSTDaymap=bin$year\_$i\_Day_LST_250m_Terra_16day
		LSTNightmap=bin$year\_$i\_Night_LST_250m_Aqua_16day
		LULCmap=bin$year\_LULC_Type_1_250m
		r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap * $LULCmap)"
		r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o --quiet --quiet
		r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"
		r.mapcalc "unsuitable=if(suitable.$year.$i == 1, 0,1)"
		r.mapcalc "ptsarea=unsuitable*studyarea"
		r.null ptsarea setnull=0
		r.random input=ptsarea raster_output=pts n=100 vector_output=sim17_pts_$year\_$i\_run$rep --o --quiet
		r.null pts null=0
		# this keeps only those points that fall on suitable habitat
		sum=$(r.sum pts | sed 's/^SUM = //' | sed 's/\..*//')
		# this calculates how many points remain
		echo "There are $sum points"
		r.mapcalc "distrib.tmp=if(pts == 1, 1, distrib.tmp)"
		g.copy distrib.tmp,distrib.$year.$i.run$rep --quiet
		g.remove suitable.$year.$i --quiet
		g.remove pts --quiet
		g.remove ptsarea --quiet
	done
done

g.remove distrib.tmp
g.remove distrib.grown.tmp

g.region zoom=studyarea	
r.mask studyarea
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim17_$rep` output=sim17_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim17_$rep` output=sim17_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim17_$rep` output=sim17_2004_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim17_$rep` output=sim17_2004_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim17_$rep` output=sim17_2005_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim17_$rep` output=sim17_2005_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim17_$rep` output=sim17_2006_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim17_$rep` output=sim17_2006_run$rep\_sum method=sum

r.mask -r


curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="HPCC" -F description="TED simulation 17, run $rep complete"
