defmodule Rumbl.Router do
  use Rumbl.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Rumbl.Auth, repo: Rumbl.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Rumbl do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/users", UserController, only: [:index, :show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    get "/watch/:id", WatchController, :show
    resources "/videos", VideoController
    get "/user-videos", VideoController, :list
  end

  scope "/manage", Rumbl do
    pipe_through [:browser, :authenticate_user]
    resources "/videos", VideoController
    resources "/feeds", FeedController
    get "/feeds/:id", FeedController, :show
  end

  scope "/feeds", Rumbl do
    pipe_through [:browser, :authenticate_user]
    get "/", FeedController, :list
  end

  # Other scopes may use custom stacks.
  # scope "/api", Rumbl do
  #   pipe_through :api
  # end
end
