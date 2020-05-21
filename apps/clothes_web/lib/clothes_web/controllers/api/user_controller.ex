defmodule ClothesWeb.Api.UserController do
  use ClothesWeb, :controller

  # def create(conn, params) do
  #   # IO.inspect(params["data"])
  #   conn = Plug.Conn.fetch_query_params(conn)

  #   user_params =
  #     params["data"]
  #     |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)

  #   case Clothes.insert_user(user_params) do
  #     {:ok, user} ->
  #     {:error, user} ->
  #   end

  #    render(conn, "item.json", item_id: item_id)
  # end
end
