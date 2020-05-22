defmodule PropertiesWeb.Router do
  use PropertiesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, {PropertiesWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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

    get "/assessments", AssessmentController, :index
    get "/assessments/:id", AssessmentController, :show
    get "/geocode", GeocodeController, :index
    get "/neighborhood", MapController, :neighborhood
    get "/neighborhood_random", MapController, :neighborhood_random
  end

  scope "/", PropertiesWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    live "/parking_tickets", ParkingTicketsLiveView

    get "/map", MapController, :index

    live "/properties", PropertiesLiveView
    get "/properties/:id", PropertyController, :show

    live "/transit/nearby_bus_stops", BusStopLiveView

    get "/transit", TransitController, :dashboard
    get "/transit/dashboard", TransitController, :index
    get "/transit/:id", TransitController, :trips
    get "/transit/stop_times/:id", TransitController, :stop_times
    get "/transit/route_headsign_shape/:id", TransitController, :route_headsign_shape
    get "/transit/stop_times_comparison/:id", TransitController, :stop_times_comparison
  end
end
