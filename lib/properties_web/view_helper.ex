defmodule PropertiesWeb.ViewHelper do
  use Phoenix.HTML
  @number_regex ~r/\B(?=(\d{3})+(?!\d))/

  def number_with_commas(number) do
    number = to_string(number)
    Regex.replace(@number_regex, number, ",")
  end

  def air_conditioning(ac) when ac == 1, do: "Yes"
  def air_conditioning(_), do: "No"
  def parking_type(nil), do: "None"
  def parking_type(parking_type), do: parking_type

  def mapbox_static(latitude, longitude) do
    "https://api.mapbox.com/styles/v1/mapbox/streets-v10/static/geojson(%7B%22type%22%3A%22Point%22%2C%22coordinates%22%3A%5B#{
      longitude
    }%2C#{latitude}%5D%7D)/#{longitude},#{latitude},14/500x300?access_token=pk.eyJ1IjoibWl0Y2hlbGxoZW5rZSIsImEiOiJjam5ybXN5ZnQwOXpkM3BwYXo3ZDY4aHJzIn0.ktVRbqOVQpj75MqJPZueCA"
  end

  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error),
        class: "help-block",
        data: [phx_error_for: input_id(form, field)]
      )
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext "errors", "is invalid"
    #
    #     # Translate the number of files with plural rules
    #     dngettext "errors", "1 file", "%{count} files", count
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(PropertiesWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PropertiesWeb.Gettext, "errors", msg, opts)
    end
  end
end
