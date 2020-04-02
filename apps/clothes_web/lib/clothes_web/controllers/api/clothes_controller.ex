defmodule ClothesWeb.Api.ClothesController do
  use ClothesWeb, :controller

  def index(conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")

    items =
      user_id
      |> Clothes.Cache.server_process()
      |> Clothes.Server.all()

    render(conn, "all.json", items: items)
  end

  def create(conn, params) do
    IO.inspect(params["data"])
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")

    item =
      params["data"]
      |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)

    item_id =
      user_id
      |> Clothes.Cache.server_process()
      |> Clothes.Server.add_item(item)

    render(conn, "item.json", item_id: item_id)
  end

  def update(conn, params) do
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")

    item =
      params["data"]
      |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)

    user_id
      |> Clothes.Cache.server_process()
      |> Clothes.Server.update_item(item)

    render(conn, "item.json", item_id: item.id)
  end

  def delete(conn, %{"id" => id}) do
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")

    user_id
    |> Clothes.Cache.server_process()
    |> Clothes.Server.delete_item(String.to_integer(id))

    text(conn, "deleted (maybe?)")
  end
end
