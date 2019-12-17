defmodule Clothes.Cache do
  use GenServer

  def start_link(_) do
    IO.puts("Starting clothes cache.")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(user_id) do
    GenServer.call(__MODULE__, {:server_process, user_id})
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, user_id}, _, clothes_servers) do
    case Map.fetch(clothes_servers, user_id) do
      {:ok, clothes_server} ->
        if Process.alive?(clothes_server) do
          {:reply, clothes_server, clothes_servers}
        else
          {:ok, new_server} = Clothes.Server.start_link(user_id)
          {:reply, new_server, Map.put(clothes_servers, user_id, new_server)}
        end

      :error ->
        {:ok, new_server} = Clothes.Server.start_link(user_id)
        {:reply, new_server, Map.put(clothes_servers, user_id, new_server)}
    end
  end
end
