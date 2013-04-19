##########################
# simulation 22 - spatial error 25% mean=0 sd=217  --accept all points
# Author: Shaun Langley
# Last Modified 3/25/2013


g.mapset -c expSim22_$rep
g.mremove rast=* -f
g.mremove vect=* -f
g.region Kenya 
r.mapcalc "distrib.tmp=initDistrib"

years="2004 2005 2006"

times=`seq -w 1 16 365`

for year in $years; do
	for i in $times; do
		r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o
		r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"
		
# normal reporter
# choose 20 points from sim 4

		v.extract input=sim5_$year_$i@results output=pts_selected random=90 --o
		v.perturb input=pts_selected output=pts_perturbed distribution=normal parameter=0,217
		v.to.rast input=pts_perturbed output=pts_selected column=value --o
		r.null pts_selected null=0 
		r.mapcalc "distrib.tmp=if(pts_selected==1,1,distrib.tmp)"

		
#  choose 5 points from sim 17

		v.extract input=sim17_$year_$i@results output=pts_selected random=10 --o
		v.perturb input=pts_selected output=pts_perturbed distribution=normal parameter=0,217
		v.to.rast input=pts_perturbed output=pts_selected column=value --o
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
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim22_$rep` output=sim22_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.200[4-6]* sep=, mapset=expSim22_$rep` output=sim22_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim22_$rep` output=sim22_2004_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2004.* sep=, mapset=expSim22_$rep` output=sim22_2004_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim22_$rep` output=sim22_2005_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2005.* sep=, mapset=expSim22_$rep` output=sim22_2005_run$rep\_sum method=sum
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim22_$rep` output=sim22_2006_run$rep\_average method=average
r.series input=`g.mlist pat=distrib.2006.* sep=, mapset=expSim22_$rep` output=sim22_2006_run$rep\_sum method=sum

r.mask -r


curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="HPCC" -F description="TED simulation 22, run $rep complete"

