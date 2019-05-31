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

  scope "/api", PropertiesWeb do
    pipe_through :api # Use the default browser stack

    get "/", AssessmentController, :index
    get "/assessments/:id", AssessmentController, :show
    get "/geocode", GeocodeController, :index
    get "/geojson", MapController, :geojson
    get "/neighborhood", MapController, :neighborhood
  end

  scope "/", PropertiesWeb do
    pipe_through :browser # Use the default browser stack

    live "/", PropertiesLiveView
    get "/map", MapController, :index
    get "/properties/:id", PropertyController, :show
  end
end
