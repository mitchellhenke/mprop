defmodule Properties.ParkingTicket do
  use PropertiesWeb, :model

  # CREATE TABLE parking_tickets (id SERIAL, issue_number TEXT, issue_date TEXT, issue_time TEXT, location TEXT, license_plate TEXT, license_plate_state TEXT, make TEXT, violation_code TEXT, violation_description TEXT, fine TEXT);
  # COPY parking_tickets(issue_number, issue_date, issue_time, location, license_plate, license_plate_state, make, violation_code, violation_description, fine) FROM '/Users/mitchellhenke/Documents/elixir/properties/data/parking_tickets/all.csv' DELIMITER ',' CSV HEADER;
  # ALTER TABLE parking_tickets ADD COLUMN date date;
  # CREATE INDEX ON parking_tickets (license_plate, license_plate_state);
  # UPDATE parking_tickets SET date = to_date(issue_date, 'YYYY/MM/DD');
  # ALTER TABLE parking_tickets DROP COLUMN issue_date;
  # CREATE INDEX ON parking_tickets (date, time);
  # ALTER TABLE parking_tickets ADD COLUMN time time;
  # UPDATE parking_tickets SET time = to_timestamp(issue_time, 'HH24:MI:SS') WHERE issue_time IS NOT NULL AND issue_time <> '12/30/1899';
  # ALTER TABLE parking_tickets DROP COLUMN issue_time;
  # CREATE INDEX ON parking_tickets (issue_number);
  # UPDATE parking_tickets SET fine = NULL WHERE fine IN ('PARKED WITHIN 4 FEET OF DRIVE OR ALLEY', '346.53(4)', 'PARKED LESS THAN 15 FEET FROM CROSSWALK');
  # ALTER TABLE parking_tickets ALTER COLUMN fine TYPE integer USING fine::integer;

  schema "parking_tickets" do
    field(:issue_number, :string)
    field(:date, :date)
    field(:time, :time)
    field(:location, :string)
    field(:license_plate, :string)
    field(:license_plate_state, :string)
    field(:make, :string)
    field(:violation_code, :string)
    field(:violation_description, :string)
    field(:fine, :integer)
  end

  def filter_by_license_plate_state(query, nil), do: query
  def filter_by_license_plate_state(query, ""), do: query

  def filter_by_license_plate_state(query, license_plate_state) do
    from(p in query, where: p.license_plate_state == ^license_plate_state)
  end

  def filter_by_license_plate(query, nil), do: query
  def filter_by_license_plate(query, ""), do: query

  def filter_by_license_plate(query, license_plate) do
    from(p in query, where: p.license_plate == ^license_plate)
  end

  def filter_by_date(query, nil), do: query

  def filter_by_date(query, date) do
    from(p in query, where: p.date == ^date)
  end

  def filter_greater_than(query, _, nil), do: query

  def filter_greater_than(query, field, number) do
    from(p in query,
      where: field(p, ^field) >= ^number
    )
  end

  def filter_less_than(query, _, nil), do: query

  def filter_less_than(query, field, number) do
    from(p in query,
      where: field(p, ^field) <= ^number
    )
  end
end
