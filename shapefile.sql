ALTER TABLE shapefiles ADD COLUMN geom_point geometry(Point,32054);
update shapefiles SET geom_point = ST_Centroid(geom);

alter table shapefiles alter column geom_point TYPE geometry(Point, 4326) USING ST_Transform(ST_SetSRID(geom_point, 32054), 4326);


ALTER TABLE shapefiles
 ALTER COLUMN geom TYPE geometry(MultiPolygon, 4326)
   USING ST_Transform(geom, 4326);

CREATE INDEX shapefiles_geom_point_index on shapefiles using GIST (geography(geom_point));
CREATE INDEX shapefiles_geom_index on shapefiles using GIST (geom);
CREATE INDEX shapefiles_taxkey_index on shapefiles (taxkey);
/* alter table shapefiles drop column geom; */
/* alter table assessments drop column geom; */

create index lol on assessments (last_assessment_amount DESC) WHERE year = 2018;
create index lol2 on assessments USING gin (full_address_vector) WHERE year = 2018;

create materialized view mitchells_material_view as SELECT s0."geom", ST_AsGeoJSON(s0."geom") as geo_json, a1."last_assessment_land", a1."lot_area", a1."tax_key", a1."zoning", a1."land_use" FROM "shapefiles" AS s0 LEFT OUTER JOIN "assessments" AS a1 ON (a1."tax_key" = s0."taxkey") AND (a1."year" = 2018);

create materialized view mitchells_material_view as SELECT s0."geom", (select EXISTS(SELECT taxkey from shapefiles s1 where s0.geom = s1.geom AND s0.taxkey <> s1.taxkey))::int4 as nonunique_plot, ST_AsGeoJSON(s0."geom") as geo_json, a1."last_assessment_land", a1."lot_area", a1."tax_key", a1."zoning", a1."land_use" FROM "shapefiles" AS s0 LEFT OUTER JOIN "assessments" AS a1 ON (a1."tax_key" = s0."taxkey") AND (a1."year" = 2018);

CREATE EXTENSION btree_gist;
CREATE INDEX CONCURRENTLY materialized_view_geom_index on mitchells_material_view using GIST (geom, nonunique_plot);
CREATE INDEX CONCURRENTLY materialized_view_geom_zoning_index on mitchells_material_view using GIST (geom, nonunique_plot, zoning);
