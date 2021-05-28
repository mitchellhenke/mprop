defmodule Properties.Repo.Migrations.Gtfs do
  use Ecto.Migration

  def change do
    execute("CREATE SCHEMA IF NOT EXISTS gtfs")

    create table("feeds", prefix: "gtfs") do
      add(:date, :date)
    end

    create table("calendar_dates", prefix: "gtfs") do
      add(:feed_id, references(:feeds, prefix: "gtfs"), null: false)
      add(:service_id, :text)
      add(:date, :date)
      add(:exception_type, :integer)
    end

    # delete from gtfs.calendar_dates where feed_id = 14;
    # delete from gtfs.routes where feed_id = 14;
    # delete from gtfs.trips where feed_id = 14;
    # delete from gtfs.stops where feed_id = 14;
    # delete from gtfs.stop_times where feed_id = 14;
    # delete from gtfs.shapes where feed_id = 14;
    # delete from gtfs.shape_geoms where feed_id = 14;

    create table("routes", prefix: "gtfs") do
      add(:feed_id, references(:feeds, prefix: "gtfs"), null: false)
      add(:route_id, :text)
      add(:route_short_name, :text)
      add(:route_long_name, :text)
      add(:route_desc, :text)
      add(:route_type, :integer)
      add(:route_url, :text)
      add(:route_color, :text)
      add(:route_text_color, :text)
    end

    create table("trips", prefix: "gtfs") do
      add(:feed_id, references(:feeds, prefix: "gtfs"), null: false)
      add(:route_id, :text)
      add(:trip_id, :text)
      add(:service_id, :text)
      add(:trip_headsign, :text)
      add(:direction_id, :integer)
      add(:block_id, :text)
      add(:shape_id, :text)
      add(:length_seconds, :integer)
      add(:start_time, :interval)
      add(:end_time, :interval)
    end

    create table("stops", prefix: "gtfs") do
      add(:feed_id, references(:feeds, prefix: "gtfs"), null: false)
      add(:stop_id, :text)
      add(:stop_name, :text)
      add(:stop_lat, :float)
      add(:stop_lon, :float)
      add(:zone_id, :text)
      add(:stop_url, :text)
      add(:stop_desc, :text)
      add(:stop_code, :text)
      add(:timepoint, :text)
      add(:route_ids, {:array, :text})
    end

    create table("stop_times", prefix: "gtfs") do
      add(:feed_id, references(:feeds, prefix: "gtfs"), null: false)
      add(:stop_id, :text)
      add(:trip_id, :text)
      add(:arrival_time, :interval)
      add(:departure_time, :interval)
      add(:stop_sequence, :integer)
      add(:stop_headsign, :text)
      add(:pickup_type, :integer)
      add(:drop_off_type, :integer)
      add(:timepoint, :integer)
      add(:shape_dist_traveled, :float)
    end

    create table("shapes", prefix: "gtfs") do
      add(:feed_id, references(:feeds, prefix: "gtfs"), null: false)
      add(:shape_id, :text)
      add(:shape_pt_lat, :float)
      add(:shape_pt_lon, :float)
      add(:shape_pt_sequence, :integer)
      add(:shape_dist_traveled, :float)
    end

    create table("shape_geoms", prefix: "gtfs") do
      add(:feed_id, references(:feeds, prefix: "gtfs"), null: false)
      add(:shape_id, :text)
      add(:length_meters, :float)
    end

    create table("rt_vehicle_positions", prefix: "gtfs") do
      add(:timestamp, :utc_datetime)
      add(:vehicle_id, :text)
      add(:latitude, :float)
      add(:longitude, :float)
      add(:bearing, :float)
      add(:progress, :integer)
      add(:trip_start_date, :date)
      add(:trip_id, :text)
      add(:block, :text)
      add(:stop_id, :text)
      add(:route_id, :text)
      add(:dist_along_route, :float)
      add(:dist_from_stop, :float)
    end

    create table("rt_vehicle_predictions", prefix: "gtfs") do
      add(:timestamp, :utc_datetime)
      add(:prediction_timestamp, :utc_datetime)
      add(:vehicle_id, :text)
      add(:route_id, :text)
      add(:trip_id, :text)
      add(:stop_id, :text)
      add(:dist_from_stop, :float)
      add(:delay, :boolean)
      add(:block_id, :text)
    end

    create(unique_index(:rt_vehicle_positions, [:timestamp, :vehicle_id], prefix: "gtfs"))
    create(index(:rt_vehicle_positions, [:trip_id], prefix: "gtfs"))
    create(index(:rt_vehicle_positions, [:vehicle_id], prefix: "gtfs"))

    create(unique_index(:rt_vehicle_predictions, [:timestamp, :vehicle_id], prefix: "gtfs"))
    create(index(:rt_vehicle_predictions, [:trip_id], prefix: "gtfs"))
    create(index(:rt_vehicle_predictions, [:vehicle_id], prefix: "gtfs"))

    create(unique_index(:calendar_dates, [:feed_id, :service_id, :date], prefix: "gtfs"))
    create(unique_index(:routes, [:feed_id, :route_id], prefix: "gtfs"))

    create(unique_index(:stop_times, [:feed_id, :trip_id, :stop_sequence], prefix: "gtfs"))
    create(unique_index(:trips, [:feed_id, :trip_id, :service_id], prefix: "gtfs"))
    create(index(:trips, [:feed_id, :service_id], prefix: "gtfs"))
    create(index(:trips, [:feed_id, :route_id, :direction_id], prefix: "gtfs"))
    create(unique_index(:stops, [:feed_id, :stop_id], prefix: "gtfs"))
    create(index(:stop_times, [:feed_id, :stop_id], prefix: "gtfs"))
    create(index(:stop_times, [:feed_id, :stop_id, :arrival_time], prefix: "gtfs"))
    create(unique_index(:shapes, [:feed_id, :shape_id, :shape_pt_sequence], prefix: "gtfs"))
    create(unique_index(:shape_geoms, [:feed_id, :shape_id], prefix: "gtfs"))
    execute("alter table gtfs.stops add column geom_point geometry(Point, 4326)")
    execute("alter table gtfs.shapes add column geom_point geometry(Point, 4326)")
    execute("alter table gtfs.shape_geoms add column geom_line geometry(LineString, 4326)")

    create(index(:stops, ["feed_id", "geography(geom_point)"], prefix: "gtfs", using: :gist))
    create(unique_index(:feeds, [:date], prefix: "gtfs"))
  end
end
