defmodule Properties.Router do
  use Properties.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Properties do
    pipe_through :api # Use the default browser stack

    get "/", PropertyController, :index
  end
end
