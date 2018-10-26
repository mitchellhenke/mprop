defmodule PropertiesWeb.Router do
  use PropertiesWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PropertiesWeb do
    pipe_through :api # Use the default browser stack

    get "/", AssessmentController, :index
    get "/assessments/:id", AssessmentController, :show
  end
end
