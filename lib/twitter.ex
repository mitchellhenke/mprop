defmodule Properties.Twitter do
  alias Properties.ParkingTicket
  @regex ~r/\b[A-Z]{2}:[a-zA-Z0-9]{1}+[a-zA-Z0-9 -]{0,5}[a-zA-Z0-9]{0,1}\b/
  def license_plate(text) do
    Regex.run(@regex, text)
  end

  def reply(tweet, license_plate) do
    [state, license_plate] = String.split(license_plate, ":")
    license_plate = String.upcase(license_plate)
                    |> String.replace(" ", "")
                    |> String.replace("-", "")

    tickets = ParkingTicket.filter_by_license_plate(ParkingTicket, license_plate)
              |> ParkingTicket.filter_by_license_plate_state(state)
              |> IO.inspect(label: "QUERY")
              |> Properties.Repo.all()

    screen_name = get_in(tweet, ["user", "screen_name"])

    in_reply_to_status_id = Map.get(tweet, "id")
                            |> IO.inspect(label: "ID")

    tickets_by_year = Enum.group_by(tickets, fn(ticket) -> ticket.date.year end)
                      |> Enum.map(fn({year, tickets}) -> {year, Enum.count(tickets)} end)
                      |> Enum.sort_by(fn({year, _tickets}) -> year end)

    status = """
    @#{screen_name}
    license plate #{state}:#{license_plate} has been issued #{Enum.count(tickets)} parking tickets between 2014-2018.
    #{Enum.map(tickets_by_year, fn({year, count}) ->
      "#{year}: #{count}\n"
    end)}
    """
    |> String.trim()
    |> IO.inspect(label: "STATUS")

    authenticated_request("https://api.twitter.com/1.1/statuses/update.json",
      [{"status", status}, {"in_reply_to_status_id", in_reply_to_status_id}])
  end

  def handle_events(webhook_callback_body) do
    with tweets <- Map.get(webhook_callback_body, "tweet_create_events", []),
         tweets <- Enum.filter(tweets, fn(tweet) -> Map.get(tweet, "retweeted") == false && get_in(tweet, ["user", "protected"]) == false && get_in(tweet, ["user", "id"]) != 1157650398649507840 end) do
      Enum.each(tweets, fn(%{"text" => text} = tweet) ->
        case license_plate(text) do
          [license_plate] -> reply(tweet, license_plate)
          [] -> nil
        end
      end)
    end
  end

  def authenticated_request(url, parameters) do
    consumer_key = Application.get_env(:properties, :twitter_consumer_key)
    consumer_secret = Application.get_env(:properties, :twitter_consumer_secret)
    token = Application.get_env(:properties, :twitter_access_token)
    token_secret = Application.get_env(:properties, :twitter_access_token_secret)

    creds = OAuther.credentials(consumer_key: consumer_key, consumer_secret: consumer_secret,
      token: token, token_secret: token_secret)

    params = OAuther.sign("post", url, parameters, creds)
    {header, req_params} = OAuther.header(params)
    req_params = Enum.into(req_params, %{})
                 |> URI.encode_query()
    {_, _status, _headers, client} = :hackney.post(url,
      [header, {"Content-Type", "application/x-www-form-urlencoded"}], req_params)
      |> IO.inspect

    :hackney.body(client)
    |> IO.inspect
  end

  def register do
    authenticated_request("https://api.twitter.com/1.1/account_activity/all/dev/webhooks.json",
      [{"url", "https://mprop.mitchellhenke.com/webhooks/twitter"}])
  end

  def subscribe do
    authenticated_request("https://api.twitter.com/1.1/account_activity/all/dev/subscriptions.json",
      [])
  end
end
