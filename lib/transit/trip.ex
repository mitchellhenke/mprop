defmodule Transit.Trip do
  defstruct [:id, :route_id, :service_id, :headsign, :direction_id, :block_id, :shape_id, :stop_times]
end
