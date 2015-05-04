defmodule ElistrixRemote.Router do
  use ElistrixRemote.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ElistrixRemote do
     pipe_through :api

     get "/lossy", ApiController, :lossy
  end
end
