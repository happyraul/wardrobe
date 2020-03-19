defmodule ClothesWeb.Router do
  use ClothesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :elm do
    plug :put_layout, false
  end

  scope "/", ClothesWeb do
    pipe_through [:browser, :elm]

    get "/", PageController, :app
  end

  # Other scopes may use custom stacks.
  scope "/api", ClothesWeb.Api do
    pipe_through :api

    # get "/all", ClothesController, :all
    # post "/add_item", ClothesController, :add_item

    resources "/items", ClothesController, only: [:index, :create, :delete]
  end
end
