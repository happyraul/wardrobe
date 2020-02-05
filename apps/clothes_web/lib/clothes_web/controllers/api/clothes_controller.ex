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
end
