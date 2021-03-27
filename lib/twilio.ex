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

  def send_message(conversation_sid, body) do
    body = [
      {"Body", body}
    ]

    :hackney.post(
      "https://conversations.twilio.com/v1/Conversations/#{conversation_sid}/Messages",
      [auth_header()],
      {:form, body}
    )
  end

  defp auth_header do
    account_sid = System.get_env("TWILIO_ACCOUNT_SID")
    auth_token = System.get_env("TWILIO_AUTH_TOKEN")
    authorization =  Base.encode64("#{account_sid}:#{auth_token}")
    {"Authorization", "Basic #{authorization}"}
  end

  def test_game_conversation_sid do
    "CH27ea089ce6d840bea12279f49360f374"
  end

  def twilio_number do
    "+15413591561"
  end
end
