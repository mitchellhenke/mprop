defmodule PropertiesWeb.PageController do
  use PropertiesWeb, :controller
  import Phoenix.HTML

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def civ_webhook(conn, params) do
    %{"value1" => game_name, "value2" => player_name, "value3" => turn_number} =
      params

    new_row = [player_name, turn_number, NaiveDateTime.utc_now()]
    existing_turns = existing_turns(game_name)
    save_turns(game_name, [new_row | existing_turns])

    url = PropertiesWeb.Router.Helpers.page_url(conn, :civ_turns, %{game: game_name})

    Properties.Twilio.send_message(
      "It is #{player_name}'s turn in #{game_name}. The current turn number is #{turn_number}. See turns at #{url}."
    )

    send_resp(conn, 201, "")
  end

  def civ_turns(conn, params) do
    game_name = Map.get(params, "game", "My game")
    existing_turns = existing_turns(game_name)
    total_game_time = total_game_time(existing_turns)
    existing_turns = existing_turns
                     |> Enum.reverse()
                     |> Enum.chunk_every(2, 1)
                     |> Enum.reverse()
                     |> Enum.map(fn([[player, turn, time] | next_turn]) ->
                       turn_time = time_diff_seconds(time, next_turn)
                       [player, turn, time, turn_time]
                     end)

    player_averages = Enum.group_by(existing_turns, fn([player, _turn, _time, _turn_time]) ->
      player
    end)
    |> Enum.map(fn({player, turns}) ->
      average_seconds = if Enum.count(turns) == 0 do
        0
      else
        turn_times = Enum.map(turns, fn(turn) -> Enum.at(turn, 3) end)
        (Enum.sum(turn_times) / Enum.count(turns))
        |> round()
      end

      [player, average_seconds]
    end)
    html = ~E"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8"/>
      <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    </head>
    <body>
      <h1>
        <%= game_name %>
      </h1>
      <h2>
        <%= total_game_time %>
      </h2>
      <table>
          <thead>
              <tr>
                  <th>Player</th>
                  <th>Turn</th>
                  <th>Start Time</th>
                  <th>Turn Length</th>
              </tr>
          </thead>
          <tbody>
            <%= Enum.map(existing_turns, fn([player, turn, time, turn_time_seconds]) -> %>
              <tr>
              <td><%= player %></td>
              <td><%= turn %></td>
              <td><%= format_naive_date_time(time) %></td>
              <td><%= format_time_diff(turn_time_seconds) %></td>
              </tr>
            <% end) %>
          </tbody>
      </table>
      <table>
          <thead>
              <tr>
                  <th>Player</th>
                  <th>Average Turn Length</th>
              </tr>
          </thead>
          <tbody>
            <%= Enum.map(player_averages, fn([player, average_turn_time_seconds]) -> %>
              <tr>
              <td><%= player %></td>
              <td><%= format_time_diff(average_turn_time_seconds) %></td>
              </tr>
            <% end) %>
          </tbody>
      </table>
    </body>
    """
    |> safe_to_string()

    html(conn, html)
  end

  def existing_turns(game_name) do
    data = Redix.command!(:redix, ["GET", "#{game_name}_game_data"])
    if data do
      :zlib.uncompress(data)
      |> :erlang.binary_to_term()
      |> Enum.map(fn([player, turn, date_string]) ->
        [player, turn, NaiveDateTime.from_iso8601!(date_string)]
      end)
    else
      []
    end
  end

  def save_turns(game_name, turns) do
    turns_binary = turns
                   |> Enum.map(fn([player, turn, time]) ->
                     [player, turn, NaiveDateTime.to_iso8601(time)]
                   end)
                   |> :erlang.term_to_binary()
                   |> :zlib.compress()

    Redix.command!(:redix, ["SET", "#{game_name}_game_data", turns_binary])
  end

  defp format_naive_date_time(naive_date) do
    DateTime.from_naive!(naive_date, "Etc/UTC")
    |> DateTime.shift_zone!("America/Chicago")
    |> Calendar.strftime("%b %d, %I:%M:%S %p")
  end

  defp total_game_time([]) do
    ""
  end

  defp total_game_time(turns) do
    [_, _, first_turn_time] = List.last(turns)

    total_seconds = NaiveDateTime.diff(NaiveDateTime.utc_now(), first_turn_time)
    format_time_diff(total_seconds)
  end

  defp time_diff_seconds(old_time, [[_, _, new_time]]) do
    NaiveDateTime.diff(new_time, old_time)
  end

  defp time_diff_seconds(old_time, _) do
    NaiveDateTime.diff(NaiveDateTime.utc_now(), old_time)
  end

  defp format_time_diff(total_seconds) do
    days = div(total_seconds, 86400)

    hours = rem(total_seconds, 86400)
            |> div(3600)

    minutes = rem(total_seconds, 3600)
              |> div(60)
    seconds = rem(total_seconds, 3600)
              |> rem(60)

    cond do
      days > 0 ->
        "#{days} days, #{hours} hours, #{minutes} minutes"
      hours > 0 ->
        "#{hours} hours, #{minutes} minutes"
      minutes > 0 ->
        "#{minutes} minutes, #{seconds} seconds"
      true ->
      "#{seconds} seconds"
    end
  end
end
