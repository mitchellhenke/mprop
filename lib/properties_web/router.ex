defmodule PropertiesWeb.Router do
  use PropertiesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Phoenix.LiveView.Flash
    plug :put_layout, {PropertiesWeb.LayoutView, :app}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/webhooks", PropertiesWeb do
    pipe_through :api

    get "/twitter", TwitterController, :crc
    post "/twitter", TwitterController, :index
  end

  scope "/api", PropertiesWeb do
    pipe_through :api # Use the default browser stack

    get "/", AssessmentController, :index
    get "/assessments/:id", AssessmentController, :show
    get "/geocode", GeocodeController, :index
    get "/neighborhood", MapController, :neighborhood
    get "/neighborhood_random", MapController, :neighborhood_random
  end

  scope "/", PropertiesWeb do
    pipe_through :browser # Use the default browser stack

    live "/", PropertiesLiveView
    live "/parking_tickets", ParkingTicketsLiveView
    get "/map", MapController, :index
    get "/properties/:id", PropertyController, :show
    get "/transit", TransitController, :index
    get "/transit/:id", TransitController, :trips
    get "/transit/stop_times/:id", TransitController, :stop_times
    get "/transit/stop_times_cumulative/:id", TransitController, :stop_times_cumulative
    get "/transit/stop_times_comparison/:id", TransitController, :stop_times_comparison
  end
end
