defmodule Clothes.Cache do
  use GenServer

  def start do
    GenServer.start(__MODULE__, nil)
  end

  def server_process(cache_pid, user_id) do
    GenServer.call(cache_pid, {:server_process, user_id})
  end

  @impl GenServer
  def init(_) do
    Clothes.Database.start()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, user_id}, _, clothes_servers) do
    case Map.fetch(clothes_servers, user_id) do
      {:ok, clothes_server} ->
        {:reply, clothes_server, clothes_servers}

      :error ->
        {:ok, new_server} = Clothes.Server.start(user_id)
        {:reply, new_server, Map.put(clothes_servers, user_id, new_server)}
    end
  end
end
