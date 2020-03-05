defmodule ClothesWeb.Api.ClothesController do
  use ClothesWeb, :controller

  def all(conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")

    items =
      user_id
      |> Clothes.Cache.server_process()
      |> Clothes.Server.all()

    render(conn, "all.json", items: items)
  end

  def add_item(conn, params) do
    IO.inspect(params["data"])
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")

    item = params["data"]
     |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)

     item_id =
      user_id
      |> Clothes.Cache.server_process()
      |> Clothes.Server.add_item(item)

    render(conn, "item.json", item_id: item_id)
  end
end
