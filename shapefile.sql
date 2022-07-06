ALTER TABLE shapefiles
 ALTER COLUMN geom TYPE geometry(MultiPolygon, 4326)
   USING ST_Transform(geom, 4326);

ALTER TABLE shapefiles ADD COLUMN geom_point geometry(Point,4326);
update shapefiles SET geom_point = ST_Centroid(geom);

ALTER TABLE neighborhood_shapefiles
 ALTER COLUMN geom TYPE geometry(MultiPolygon, 4326)
   USING ST_Transform(geom, 4326);

ALTER TABLE bike_lane_shapefiles
 ALTER COLUMN geom TYPE geometry(MultiLineString, 4326)
   USING ST_Transform(geom, 4326);

ALTER TABLE off_street_path_shapefiles
 ALTER COLUMN geom TYPE geometry(MultiLineString, 4326)
   USING ST_Transform(geom, 4326);

ALTER TABLE west_bend_storm_shapefiles
 ALTER COLUMN geom TYPE geometry(Point, 4326)
   USING ST_Transform(geom, 4326);

ALTER TABLE mke_inlets
 ALTER COLUMN geom TYPE geometry(Point, 4326)
   USING ST_Transform(geom, 4326);

ALTER TABLE mke_poly_inlets
 ALTER COLUMN geom TYPE geometry(MultiPolygon, 4326)
   USING ST_Transform(geom, 4326);

CREATE INDEX shapefiles_geom_point_index on shapefiles using GIST (geography(geom_point));
CREATE INDEX shapefiles_geom_index on shapefiles using GIST (geom);

CREATE INDEX bike_lane_shapefiles_geom_index on bike_lane_shapefiles using GIST (geography(geom));

CREATE INDEX shapefiles_geom_index on shapefiles using GIST (geom);
CREATE INDEX shapefiles_taxkey_index on shapefiles (taxkey);
/* alter table shapefiles drop column geom; */
/* alter table assessments drop column geom; */

create index lol on assessments (last_assessment_amount DESC) WHERE year = 2020;
create index lol2 on assessments USING gin (full_address_vector) WHERE year = 2020;

/* regular */
create materialized view mitchells_material_view as SELECT s0."geom", ST_AsGeoJSON(s0."geom") as geo_json, a1."last_assessment_land", a1."lot_area", a1."tax_key", a1."zoning", a1."land_use" FROM "shapefiles" AS s0 LEFT OUTER JOIN "assessments" AS a1 ON (a1."tax_key" = s0."taxkey") AND (a1."year" = 2020);

/* adjacent */
create materialized view mitchells_adjacent_material_view as SELECT s0."geom", (select EXISTS(SELECT taxkey from shapefiles s1 where s0.geom = s1.geom AND s0.taxkey <> s1.taxkey))::int4 as nonunique_plot, ST_AsGeoJSON(s0."geom")::jsonb as geo_json, a1."last_assessment_land" + a1."last_assessment_land_exempt", a1."lot_area", a1."tax_key", a1."zoning", a1."land_use" FROM "shapefiles" AS s0 LEFT OUTER JOIN "assessments" AS a1 ON (a1."tax_key" = s0."taxkey") AND (a1."year" = 2020);

CREATE EXTENSION btree_gist;
CREATE INDEX CONCURRENTLY adjacent_materialized_view_geom_index on mitchells_adjacent_material_view using GIST (geom, nonunique_plot);
CREATE INDEX CONCURRENTLY materialized_view_geom_zoning_index on mitchells_adjacent_material_view using GIST (geom, nonunique_plot, zoning);

/* change in assessment */
create materialized view change_in_assessment_material_view as select a1.tax_key, s.geom, ST_AsGeoJSON(s."geom")::jsonb as geo_json, a1.last_assessment_amount as "2019_total", a2.last_assessment_amount as "2020_total", a2.last_assessment_amount - a1.last_assessment_amount  as absolute_assessment_change, round(((a2.last_assessment_amount - a1.last_assessment_amount::float)/a1.last_assessment_amount)::numeric, 2) as "percent_assessment_change" from assessments a1
INNER JOIN assessments a2 on a2.tax_key  = a1.tax_key and a2.year = 2020
INNER JOIN shapefiles s on s.taxkey = a1.tax_key
where a1.year = 2019 and a1.last_assessment_amount > 0;

CREATE INDEX CONCURRENTLY mitchells_materialized_view_geom_index on mitchells_material_view using GIST (geom);

create materialized view lol_material_view as SELECT house_number_low || ' ' || street_direction || ' ' || street || ' ' || street_type || ' Milwaukee, WI' as address FROM "assessments" WHERE ("year" = 2020);
