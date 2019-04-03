defmodule PropertiesWeb.Router do
  use PropertiesWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", PropertiesWeb do
    pipe_through :api # Use the default browser stack

    get "/", AssessmentController, :index
    get "/assessments/:id", AssessmentController, :show
    get "/geocode", GeocodeController, :index
  end

  scope "/web", PropertiesWeb do
    pipe_through :api # Use the default browser stack

    get "/", MapController, :index
  end
end
