defmodule Clothes.Web do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  def child_spec(_arg) do
    Plug.Adapters.Cowboy.child_spec(
      scheme: :http,
      options: [port: Application.fetch_env!(:clothes, :http_port)],
      plug: __MODULE__
    )
  end

  post "/add_item" do
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")
    color = Map.fetch!(conn.params, "color")
    name = Map.fetch!(conn.params, "name")

    # IO.puts("adding #{color} #{name} to #{user_id}'s closet")

    user_id
    |> Clothes.Cache.server_process()
    |> Clothes.Server.add_item(%{color: color, name: name})

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(201, "OK")
  end

  get "/all" do
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")

    items =
      user_id
      |> Clothes.Cache.server_process()
      |> Clothes.Server.all()
      |> Enum.map(&"[#{&1.id}] #{&1.color} #{&1.name}")
      |> Enum.join("\n")

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, items)
  end

  delete "/delete_item" do
    conn = Plug.Conn.fetch_query_params(conn)
    user_id = Map.fetch!(conn.params, "user")
    item_id = Map.fetch!(conn.params, "id") |> String.to_integer()

    user_id
    |> Clothes.Cache.server_process()
    |> Clothes.Server.delete_item(item_id)

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "OK")
  end
end
