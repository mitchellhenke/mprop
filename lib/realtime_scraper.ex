defmodule Transit.RealtimeScraper do
  import NimbleParsec
  use GenServer

  # 52 seconds

  # @routes1 ["BLU","GOL","GRE","PUR","RED","RR1","RR2","RR3","12","14"]
  # @routes2 ["15","17","19","21","22","23","28","30","30X","31"]
  # @routes3 ["33","35","40","40U","42U","43","44","44U","46","48"]
  # @routes4 ["49","49U","51","52","53","54","55","56","57","60"]
  # @routes5 ["63","64","67","76","79","80","137","143","219","223"]
  # @routes6 ["276"]

  # @all_routes [@routes1, @routes2, @routes3, @routes4, @routes5, @routes6]

  @detailed_routes1 ["GRE", "PUR", "BLU", "GOL", "RED", "12", "15", "19", "21", "22", "30", "30X", "51", "54", "57", "35", "67"]

  def start_link(_ \\ nil) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_state) do
    Process.send_after(self(), :get_all_positions, 0)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:get_all_positions, state) do
    start_time = System.monotonic_time()
    Enum.chunk_every(@detailed_routes1, 10)
    |> Enum.each(fn(routes) ->
      request_locations(routes)
    end)
    end_time = System.monotonic_time()

    diff = System.convert_time_unit(end_time - start_time, :native, :millisecond)
    time_to_wait = max(2_000 - diff, 0)

    Process.send_after(self(), :get_all_positions, time_to_wait)
    {:noreply, state}
  end

  defparsec :parse_datetime,
            integer(4)
            |> integer(2)
            |> integer(2)
            |> ignore(string(" "))
            |> integer(2)
            |> ignore(string(":"))
            |> integer(2)
            |> ignore(string(":"))
            |> integer(2)

  def request_locations(route_ids) do
    rt = Enum.join(route_ids, ",")

    params =
      %{
        rt: rt,
        tmres: "s",
        format: "json",
        key: Application.fetch_env!(:properties, :mcts_key)
      }
      |> URI.encode_query()

    with {:ok, 200, _headers, client_ref} <-
           :hackney.get("http://realtime.ridemcts.com/bustime/api/v3/getvehicles?#{params}"),
         {:ok, body} <- :hackney.body(client_ref),
         {:ok, json} <- Jason.decode(body),
         {:ok, bustime_response} <- Map.fetch(json, "bustime-response"),
         {:ok, vehicles} <- Map.fetch(bustime_response, "vehicle") do
      Enum.map(vehicles, fn vehicle ->
        %{
          "rt" => route,
          "pid" => _pattern_id,
          "vid" => vehicle_id,
          "tmstmp" => timestamp,
          "pdist" => dist_along_route,
          "tablockid" => block_id,
          "tatripid" => trip_id,
          "lat" => lat,
          "lon" => lon,
          "hdg" => bearing
        } = vehicle

        {:ok, [year, month, day, hour, minute, second], _, _, _, _} = parse_datetime(timestamp)

        {:ok, datetime} = DateTime.now("America/Chicago")

        datetime = %{
          datetime | year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        }

        attrs = %{
          timestamp: datetime,
          vehicle_id: vehicle_id,
          latitude: lat,
          longitude: lon,
          trip_start_date: DateTime.to_date(datetime),
          trip_id: trip_id,
          bearing: bearing,
          block: block_id,
          route_id: route,
          dist_along_route: dist_along_route
        }

        Transit.RealtimePosition.changeset(%Transit.RealtimePosition{}, attrs)
        |> Properties.Repo.insert()
      end)
      |> Enum.reduce(MapSet.new(), fn result, set ->
        case result do
          {:ok, %Transit.RealtimePosition{vehicle_id: vehicle_id}} ->
            MapSet.put(set, vehicle_id)

          _ ->
            set
        end
      end)
      |> Enum.chunk_every(10)
      |> Enum.each(fn vehicle_ids ->
        vid = Enum.join(vehicle_ids, ",")

        params =
          %{
            vid: vid,
            tmres: "s",
            format: "json",
            key: Application.fetch_env!(:properties, :mcts_key)
          }
          |> URI.encode_query()

        with {:ok, 200, _headers, client_ref} <-
               :hackney.get(
                 "http://realtime.ridemcts.com/bustime/api/v3/getpredictions?#{params}"
               ),
             {:ok, body} <- :hackney.body(client_ref),
             {:ok, json} <- Jason.decode(body),
             {:ok, bustime_response} <- Map.fetch(json, "bustime-response"),
             {:ok, predictions} <- Map.fetch(bustime_response, "prd") do

          predictions = Enum.group_by(predictions, fn(%{"vid" => vid}) ->
            vid
          end)
          |> Enum.map(fn({_vid, predictions}) ->
            Enum.sort_by(predictions, fn(pred) ->
              Map.get(pred, "tmstmp")
            end)
            |> List.first()
          end)

          Enum.each(predictions, fn prediction ->
            %{
              "rt" => route,
              "vid" => vehicle_id,
              "tmstmp" => timestamp,
              "prdtm" => prediction_timestamp,
              "tatripid" => trip_id,
              "stpid" => stop_id,
              "dstp" => dist_from_stop,
              "dly" => delay,
              "tablockid" => block_id,
            } = prediction

            {:ok, [year, month, day, hour, minute, second], _, _, _, _} =
              parse_datetime(timestamp)

            {:ok, datetime} = DateTime.now("America/Chicago")

            datetime = %{
              datetime
              | year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            }

            {:ok, [year, month, day, hour, minute, second], _, _, _, _} =
              parse_datetime(prediction_timestamp)

            {:ok, prediction_datetime} = DateTime.now("America/Chicago")

            prediction_datetime = %{
             prediction_datetime
              | year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            }

            attrs = %{
              timestamp: datetime,
              prediction_timestamp: prediction_datetime,
              vehicle_id: vehicle_id,
              trip_id: trip_id,
              block_id: block_id,
              route_id: route,
              stop_id: stop_id,
              dist_from_stop: dist_from_stop,
              delay: delay
            }

            Transit.RealtimePrediction.changeset(%Transit.RealtimePrediction{}, attrs)
            |> Properties.Repo.insert()
          end)
        end
      end)
    end
  end
end
