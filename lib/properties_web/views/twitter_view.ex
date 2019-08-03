defmodule PropertiesWeb.TwitterView do
  use PropertiesWeb, :view

  def render("crc.json", %{response_token: response_token}) do
    %{
      response_token: response_token
    }
  end
end
