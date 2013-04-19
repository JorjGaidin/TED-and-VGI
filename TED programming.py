###################
## Boundary Area ##
###################

v.in.ogr dsn=TED_data output=Kenya_Official_Polygon
v.to.rast input=Kenya_Official_Polygon column=cat

################
## MODIS Data ##
################

## This is done for LST day and night from Terra.  It needs to be redone so that day is from aqua and night is from terra.

for i in $dirs; do cd $i; HDFFILES=$(ls *.hdf); echo $HDFFILES > mosaicinput.txt; mrtmosaic -i mosaicinput.txt -o mosaic_tmp.hdf; resample -p ~salangley/convert.prm -i mosaic_tmp.hdf -o MOD112_2004_$i.tif; cd ..

for i in *.tif; do gdalwarp -s_srs EPSG:32636 -t_srs EPSG:32736 $i $i.rp ; done #reproject MODIS all files in a directory to a new directory defined

for i in *.tif; do r.in.gdal input=$i output=${i%%.tif}; done # import of MODIS file

files=`g.mlist type=rast pat="MOD*"` # to process LST_Day maps

for i in $files; do r.mapcalc "$i=if($i==0,null(),$i)"; done # change 0 values to null values

for i in $files; do r.mapcalc "$i.celcius=($i * 0.02)-273.15"; echo $i; done # convert from Kelvin to Celcius

r.mask Kenya_Official_Polygon
r.fillnulls input=$foo output=$foo.filled # fill null values in the MODIS data but only within the defined mask

r.colors $foo.filled color=grey
d.rast $foo.filled # visualize the result

g.region rast=$foo.filled -p
g.region res=250 -ap
r.resamp.interp input=$i output=${i%%_1km.filled}_250m method=nearest


##########
## LULC ##
##########

r.in.gdal Mode_LULC_T1_500m.tif out=Mode_LULC_T1_500m

d.rast Mode_LULC_T1_500m # visualize the result

r.cats Mode_LULC_T1_500m # return category values (choosing 10 for demo)
g.region Mode_LULC_T1_500m -p
g.region res=250 -ap
r.resamp.interp input=Mode_LULC_T1_500m output=Mode_LULC_T1_250m method=nearest

cat LULCreclass.txt | r.reclass input=Mode_LULC_T1_250m out=Mode_LULC_T1_250m_RC

#################################
## initial Tsetse Distribution ##
#################################

v.in.ogr dsn=1973 output=Tsetse_1973
v.to.rast input=Tsetse_1973 out=Tsetse_1973 column=cat


##########
## NDVI ##
##########

for i in *.tif; do r.in.gdal input=$i out=${i%%.img.tif}; done

####################################
## Create binary suitability maps ##
####################################

# This section provides general code.  Some of the actual computations are done on the fly.  Not all maps have the same naming scheme as referenced here.

# LST Day images named as MOD112.$year.$i.LST.Day.250m where $year is year and $i is day number.
# LST Night images named as MYD11A2.A$year.$i.LST.Night.250m
# NDVI images named $year.$i.NDVI.250m
# Landcover images named MODIS.T1.$year.500m (or 250m if it's been resampled).

# MODIS LST DAY
# this creates a binary map where cells with LST values between (and including) 17-40 are given a value of 1; all other cells are set to 0.
map="MOD112_2003001.LST_Day_250m"
r.mapcalc "binLST_Day=if($map >= 17. & $map <= 40., 1, 0)"

# MODIS LST NIGHT
# this creates a binary map with cells between (and including) 10-40 are set to 1; all others set to 0
map="MOD112_2003001.LST_Night_250m"
r.mapcalc "binLST_Night=if($map >= 10. & $map <= 40., 1, 0)"

# NDVI
# this creates a binary map where NDVI values greater than (and including) 0.39 are set to 1; others set to 0.
map="2003_001_NDVI_250m"
r.mapcalc "binNDVI=if($map >= 0.39, 1, 0)"

# Landcover
# this creates a binary map where category values (1-9,11) in the LULC map are set to 1; others are set to 0
map="Mode_LULC_T1_250m"
cat LULCreclass.txt | r.reclass input=Mode.LULC.T1.250m output=binMode.LULC.T1.250m # My new implementation uses the 500m MODIS Type 1 because the resampling of the data caused it to be rescaled to 255 instead of preserving the old values.  Raster arithmetic is not affected because GRASS resamples on the fly without the rescaling problem.


# Compute aggregate suitablility
# the product of the binary maps are computed as an overall suitability map for the time period. These maps are computed for each 16day interval in the model.  
r.mapcalc "suitable=(binLST_Day * binLST_Night * binNDVI * binLULC)"



##############################
## Expand Tsetse population ##
##############################

years="2003 2004"

times="001  017  033  049  065  081  097  113  129  145  161  177  193  209  225  241  257  273  289  305  321  337  353"

# The model will loop through each year and time value noted here.

g.mapset -c baseSim01 # create a seperate mapset for each simulation to isolate output from each other to prevent possible data overwrite

r.mapcalc "distrib.tmp=initTsetseDistrib_250m" # initialize the tsetse distribution with a map of Kenya, filled with 1s. Essentially every cell stats out as occupied.
g.region rast=initTsetseDistrib_250m # define the region the model will use.

for year in $years; do
for i in $times; do

NDVImap=`g.mlist type=rast pat="bin$year\_$i\_NDVI"`
LSTDaymap=`g.mlist type=rast pat="bin$year\_$i\_Day_LST_250m_Terra_16day"`
LSTNightmap=`g.mlist type=rast pat="bin$year\_$i\_Night_LST_250m_Aqua_16day"`
LULCmap=`g.mlist type=rast pat="bin$year\_LULC_Type_1_250m"`
r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap * $LULCmap)"

r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o 
# If any cell within a 5x5 neighborhood is occupied, then the target cell becomes occupied.  The maximum method is used so it doesn't matter how many neighboring cells are occupied and thus eliminates the need to run an additional set to reset all the values back to 1. A 5x5 neighborhood corresponds with a kernel 2 cells wide around the target.

r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"
# prune back all occupied cells such that only those that correspond with suitable habitat will remain occupied.  If an occupied cells (1) is multiplied by unsuitable habitat (0) it is set to 0, unoccupied.

g.copy distrib.tmp,distrib.$year.$i
# the temporary distribution map is saved such that the temp map can be reused as the input for the next time step.

d.erase
d.rast distrib.$year.$i
d.title -d distrib.$year.$i
# visualize the results for each time step on the fly so I can kill the process if I note something is wrong.

done
done

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F description="TED simulation complete"

	
########################
## simulate reporting ##
########################


# 100 randomly located points -- accept all of them
# explanations offered only if different from the previous model run

g.mapset -c expSim01
g.region kenya zoom=Kenya_Official_Polygon
r.mapcalc "distrib.tmp=initTsetseDistrib_250m"

for year in $years; do
for i in $times; do
NDVImap=`g.mlist type=rast pat="bin$year\_$i\_NDVI"`
LSTDaymap=`g.mlist type=rast pat="bin$year\_$i\_Day_LST_250m_Terra_16day"`
LSTNightmap=`g.mlist type=rast pat="bin$year\_$i\_Night_LST_250m_Aqua_16day"`
LULCmap=`g.mlist type=rast pat="bin$year\_LULC_Type_1_250m"`
r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap * $LULCmap)"
r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o 
r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"

r.random input=studyarea raster_output=pts.tmp n=100 --o
# randomly pick 100 points that are located within the bounds of the defined study area.  Future model runs will rely on a polygon of the Kajiado district. Currently,the polygon was defined manually.

r.mapcalc "pts.reclass=if(isnull(pts.tmp),0,pts.tmp)"
# the output from r.random is a raster map where cells are 1 if selected, but NULL otherwise.  To be able to perform computations, I need to convert the NULL values to 0, otherwise anything multiplied by NULL becomes NULL.

r.mapcalc "distrib.tmp=if(pts.reclass == 1, 1, distrib.tmp)"
# the expanded distribution is multiplied by the points such that if the pts map is a 1, then the distribution cell becomes a 1.  If the pts cell was 0, the value reverts to what it was originally in the distrib.tmp map; nothing is changed.

g.copy distrib.tmp,distrib.$year.$i
# copy the resulting distribution map so that the distrib.tmp map can be used as the input for the next time step.

g.copy pts.tmp,pts.$year.$i
# save the pts map so that I have a record of which cells were selected in each time step.  This will be needed later when I treat each as a reporter.

done
done	

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F description="TED simulation complete"


##########################
# 100 randomly located points - accept those that fall on suitable habitat

g.mapset -c expSim02
g.region kenya zoom=Kenya_Official_Polygon
r.mapcalc "distrib.tmp=initTsetseDistrib_250m"

for year in $years; do
for i in $times; do
NDVImap=`g.mlist type=rast pat="bin$year\_$i\_NDVI"`
LSTDaymap=`g.mlist type=rast pat="bin$year\_$i\_Day_LST_250m_Terra_16day"`
LSTNightmap=`g.mlist type=rast pat="bin$year\_$i\_Night_LST_250m_Aqua_16day"`
LULCmap=`g.mlist type=rast pat="bin$year\_LULC_Type_1_250m"`
r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap * $LULCmap)"
r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o --quiet
r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"
r.random input=studyarea raster_output=pts n=100 --o --quiet
r.mapcalc "pts=if(isnull(pts),0,pts)"
r.mapcalc "pts=if(suitable.$year.$i==1,pts,0)"
# this keeps only those points that fall on suitable habitat

sum=$(r.sum pts | sed 's/^SUM = //' | sed 's/\..*//')
# this calculates how many points remain

while [ $sum -lt 100 ]; do
	r.random input=studyarea raster_output=pts.tmp n=100 --o --quiet
	r.mapcalc "pts.tmp=if(isnull(pts.tmp),0,pts.tmp)"
	r.mapcalc "pts.tmp=if(suitable.$year.001==1,pts.tmp,0)"
	r.mapcalc "pts=if(pts==1 ||| pts.tmp==1,1,0)"
	sum=$(r.sum pts | sed 's/^SUM = //' | sed 's/\..*//')
	echo "There are now $sum points"
done

# create a loop that repeats the selection of random points until enough have been selected that fall on suitable habitat

r.mapcalc "distrib.tmp=if(pts == 1, 1, distrib.tmp)"
g.copy distrib.tmp,distrib.$year.$i
g.copy pts,pts.$year.$i
done
done

####################################
# 100 randomly selected points with at least 1 neighbor

g.mapset -c expSim03
g.region kenya zoom=Kenya_Official_Polygon
r.mapcalc "distrib.tmp=initTsetseDistrib_250m"

for year in $years; do
for i in $times; do
NDVImap=`g.mlist type=rast pat="bin$year\_$i\_NDVI"`
LSTDaymap=`g.mlist type=rast pat="bin$year\_$i\_Day_LST_250m_Terra_16day"`
LSTNightmap=`g.mlist type=rast pat="bin$year\_$i\_Night_LST_250m_Aqua_16day"`
LULCmap=`g.mlist type=rast pat="bin$year\_LULC_Type_1_250m"`
r.mapcalc "suitable.$year.$i=($NDVImap * $LSTDaymap * $LSTNightmap * $LULCmap)"
r.neighbors input=distrib.tmp output=distrib.grown.tmp size=5 method=maximum --o --quiet
r.mapcalc "distrib.tmp=(distrib.grown.tmp * suitable.$year.$i)"
r.random input=studyarea raster_output=pts n=100 --o --quiet
r.mapcalc "pts=if(isnull(pts),0,pts)"
r.neighbors input=distrib.tmp output=neighborsum size=3 method=sum --o --quiet
# this computes the total number of neighboring cells that are occupied

r.mapcalc "pts=if(neighborsum>=1,pts,0)"
# keeps only those points that fall within 1 cell of another occupied cell.

sum=$(r.sum pts | sed 's/^SUM = //' | sed 's/\..*//')

while [ $sum -lt 100 ]; do
	r.random input=studyarea raster_output=pts.tmp n=100 --o --quiet
	r.mapcalc "pts.tmp=if(isnull(pts.tmp),0,pts.tmp)"
	r.neighbors input=distrib.tmp output=neighborsum size=3 method=sum --o --quiet
	r.mapcalc "pts.tmp=if(neighborsum>=1,pts.tmp,0)"
	r.mapcalc "pts=if(pts==1 ||| pts.tmp==1,1,0)"
	sum=$(r.sum pts | sed 's/^SUM = //' | sed 's/\..*//')
	echo "There are now $sum points"
done

# repeat the process until enough points have been identified.

r.mapcalc "distrib.tmp=if(pts == 1, 1, distrib.tmp)"
g.copy distrib.tmp,distrib.$year.$i
g.copy pts,pts.$year.$i
d.erase
d.rast distrib.$year.$i
d.title -d distrib.$year.$i
done
done

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F description="TED simulation complete"


