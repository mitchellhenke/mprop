# https://city.milwaukee.gov/DownloadMapData3497.htm
# https://itmdapps.milwaukee.gov/gis/mapdata/parcelbase.zip
shp2pgsql -s 32054 ~/Downloads/parcelbase/parcelbase.shp shapefiles > parcel.sql
psql -d milwaukee_properties -f parcel.sql
