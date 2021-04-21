defmodule Properties.Twilio do
  def create_conversation do
    body = [
      {"FriendlyName", "Civ 6 Test Game"}
    ]

    :hackney.post(
      "https://conversations.twilio.com/v1/Conversations",
      [auth_header()],
      {:form, body}
    )
  end

  def add_participant(conversation_sid, phone_number) do
    body = [
      {"MessagingBinding.Address", phone_number},
      {"MessagingBinding.ProxyAddress", twilio_number()}
    ]

    :hackney.post(
      "https://conversations.twilio.com/v1/Conversations/#{conversation_sid}/Participants",
      [auth_header()],
      {:form, body}
    )
  end

  def send_message(body) do
    Enum.each(phone_numbers(), fn number ->
      body = [
        {"Body", body},
        {"From", twilio_number()},
        {"To", number}
      ]

      account_sid = System.get_env("TWILIO_ACCOUNT_SID")
      url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages"

      :hackney.post(
        url,
        [auth_header()],
        {:form, body}
      )
    end)
  end

  defp auth_header do
    account_sid = System.get_env("TWILIO_ACCOUNT_SID")
    auth_token = System.get_env("TWILIO_AUTH_TOKEN")
    authorization = Base.encode64("#{account_sid}:#{auth_token}")
    {"Authorization", "Basic #{authorization}"}
  end

  defp twilio_number do
    "+15413591561"
  end

  defp phone_numbers do
    [
      "+14147596611",
      "+12622259396",
      "+12628127094",
      "+14145318991",
      "+14145340089"
    ]
  end
end
