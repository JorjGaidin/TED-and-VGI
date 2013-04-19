g.region rast=2003_001_Night_LST_1km_Aqua_16day -p
for i in $(g.mlist pat=200[3-6]*Night_LST*); do
r.mapcalc "bin$i=if($i >= 10. & $i <= 40., 1, 0)"
done

g.region res=250 -ap
for i in $(g.mlist pat=bin200[3-6]*Night_LST*); do
r.resamp.interp input=$i output=${i%%1km_Aqua_16day}250m_Aqua_16day method=nearest
done

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F event="process completed" -F description="LST Night done"

g.region rast=2003_001_Day_LST_1km_Terra_16day -p
for i in $(g.mlist pat=200[3-6]*Day_LST_1km_Terra_16day); do
r.mapcalc "bin$i=if($i >= 17. & $i <= 40., 1, 0)"
done

g.region res=250 -ap
for i in $(g.mlist pat=bin200[3-6]*Day_LST_1km_Terra_16day); do
r.resamp.interp input=$i output=${i%%1km_Terra_16day}250m_Terra_16day method=nearest --o
done

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F event="process completed" -F description="LST Day done"

g.region rast=2003_LULC_Type_1_500m -p
for i in $(g.mlist pat=*LULC_Type_1_500m); do
cat LULCreclass.txt | r.reclass input=$i output=bin$i
done

g.region res=250 -ap
for i in $(g.mlist pat=bin*LULC_Type_1_500m); do
r.resamp.interp input=$i output=${i%%500m}250m method=nearest
done

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F event="process completed" -F description="LULC done"

g.region rast=2003_001_NDVI -p
for i in $(g.mlist pat=*_NDVI); do
r.mapcalc "bin$i=if($i >= 0.39, 1, 0)"
done

curl https://prowlapp.com/publicapi/add -F apikey=2daeeaf780b2e94281d1089752c6698da81434a9 -F application="GRASS" -F event="process completed" -F description="NDVI done"

