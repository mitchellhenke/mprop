defmodule Properties.Repo.Migrations.Gtfs do
  use Ecto.Migration

  def change do
    execute "CREATE SCHEMA IF NOT EXISTS gtfs"
    create table("calendar_dates", prefix: "gtfs") do
      add :service_id, :text
      add :date, :date
      add :exception_type, :integer
    end

    create table("routes", prefix: "gtfs") do
      add :route_id, :text
      add :route_short_name, :text
      add :route_long_name, :text
      add :route_desc, :text
      add :route_type, :integer
      add :route_url, :text
      add :route_color, :text
      add :route_text_color, :text
    end

    create table("trips", prefix: "gtfs") do
      add :route_id, :text
      add :trip_id, :text
      add :service_id, :text
      add :trip_headsign, :text
      add :direction_id, :integer
      add :block_id, :text
      add :shape_id, :text
      add :length_meters, :float
    end

    create table("stops", prefix: "gtfs") do
      add :stop_id, :text
      add :stop_name, :text
      add :stop_lat, :float
      add :stop_lon, :float
      add :zone_id, :text
      add :stop_url, :text
      add :stop_desc, :text
      add :stop_code, :text
      add :timepoint, :text
    end

    create table("stop_times", prefix: "gtfs") do
      add :stop_id, :text
      add :trip_id, :text
      add :arrival_time, :interval
      add :departure_time, :interval
      add :stop_sequence, :integer
      add :stop_headsign, :text
      add :pickup_type, :integer
      add :drop_off_type, :integer
      add :timepoint, :integer
    end

    create table("shapes", prefix: "gtfs") do
      add :shape_id, :text
      add :shape_pt_lat, :float
      add :shape_pt_lon, :float
      add :shape_pt_sequence, :integer
    end

    create index(:stop_times, [:trip_id], prefix: "gtfs")
    create index(:trips, [:trip_id], prefix: "gtfs")
    create index(:stops, [:stop_id], prefix: "gtfs")
    create index(:shapes, [:shape_id], prefix: "gtfs")
  end
end
