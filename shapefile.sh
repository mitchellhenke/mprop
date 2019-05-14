# https://city.milwaukee.gov/DownloadMapData3497.htm
# https://itmdapps.milwaukee.gov/gis/mapdata/parcelbase.zip
shp2pgsql -s 32054 ~/Downloads/parcelbase/parcelbase.shp shapefiles > parcel.sql
psql -d milwaukee_properties -f parcel.sql

shp2pgsql -s 32054 ./off_street_paths/OffStreetPathsMilwaukeeCo.shp off_street_path_shpaefiles > off_street_paths.sql
psql -d milwaukee_properties -f off_street_paths.sql

shp2pgsql -s 32054 .data/bike_lanes/Milwaukee_BikeLanesDIME_2019.shp bike_lane_shapefiles > bike_lanes.sql
psql -d milwaukee_properties -f bike_lanes.sql
