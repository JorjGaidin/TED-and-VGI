##########################
# simulation 18 - the normal reporter --accept all points
# Author: Shaun Langley
# Last Modified 3/25/2013


g.mapset -c expSim18_$rep
g.mremove rast=* -f
g.mremove vect=* -f
g.region Kenya 
r.mapcalc "distrib.tmp=initDistrib"

years="2004 2005 2006"

times=`seq -w 1 16 365`

for year in $years; do
	for i in $times; do
		NDVImap=bin$year\_$i\_NDVI
		LSTDaymap=bin$year\_$i\_Day_LST_250m_Terra_16day
		LSTNightmap=bin$year\_$i\_Night_LST_250m_Aqua_16day
		LULCmap=bin$year\_LULC_Type_1_250m
		r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap * $LULCmap)"
		r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o
		r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"

# choose 90 points from sim 4

		v.extract input=sim5_${year}_${i}@results output=pts_selected random=90 --o
		v.to.rast input=pts_selected output=pts_selected column=value --o
		r.null pts_selected null=0 
		r.mapcalc "distrib.tmp=if(pts_selected==1,1,distrib.tmp)"
		
#  choose 10 points from sim 17

		v.extract input=sim17_${year}_${i}@results output=pts_selected random=10 --o
		v.to.rast input=pts_selected output=pts_selected column=value --o
		r.null pts_selected null=0
		r.mapcalc "distrib.tmp=if(pts_selected==1,1,distrib.tmp)"
		
		g.copy distrib.tmp,distrib.$year.$i
		g.remove vect=pts_selected
		g.remove pts_selected
	done
done

g.remove distrib.tmp
g.remove distrib.grown.tmp

g.region zoom=studyarea	
r.mask studyarea
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim18_$rep` output=sim18_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim18_$rep` output=sim18_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim18_$rep` output=sim18_2004_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim18_$rep` output=sim18_2004_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim18_$rep` output=sim18_2005_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim18_$rep` output=sim18_2005_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim18_$rep` output=sim18_2006_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim18_$rep` output=sim18_2006_run$rep\_sum method=sum

r.mask -r


curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="HPCC" -F description="TED simulation 18, run $rep complete"

