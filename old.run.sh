g.mapset expSim01

g.region studyarea
r.series input=`g.mlist pat=distrib.2004* sep=,` method=average output='distrib.series.2004'
d.erase
d.rast.leg distrib.series.2004


# I'm trying to fix errors of ommision without contributing to errors of commission
