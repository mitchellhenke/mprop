ALTER TABLE shapefiles ADD COLUMN geom_point geometry(Point,32054);
update shapefiles SET geom_point = ST_Centroid(geom);

alter table shapefiles alter column geom_point TYPE geometry(Point, 4326) USING ST_Transform(ST_SetSRID(geom_point, 32054), 4326);
CREATE INDEX shapefiles_geom_point_index on shapefiles using GIST (geography(geom_point));
CREATE INDEX shapefiles_taxkey_index on shapefiles (taxkey);
alter table shapefiles drop column geom;
alter table assessments drop column geom;
