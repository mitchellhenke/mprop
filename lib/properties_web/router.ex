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

  scope "/web", PropertiesWeb do
    pipe_through :browser

    get "/", PageController, :index
    live "/properties", PropertiesLiveView
  end

  scope "/", PropertiesWeb do
    pipe_through :api # Use the default browser stack

    get "/", AssessmentController, :index
    get "/assessments/:id", AssessmentController, :show
    get "/geocode", GeocodeController, :index
  end
end
