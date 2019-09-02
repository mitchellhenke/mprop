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
    get "/geojson", MapController, :geojson
    get "/neighborhood", MapController, :neighborhood
    get "/neighborhood_random", MapController, :neighborhood_random
  end

  scope "/", PropertiesWeb do
    pipe_through :browser # Use the default browser stack

    live "/", PropertiesLiveView
    live "/parking_tickets", ParkingTicketsLiveView
    get "/map", MapController, :index
    get "/map_live", MapController, :index_live
    get "/properties/:id", PropertyController, :show
  end
end
