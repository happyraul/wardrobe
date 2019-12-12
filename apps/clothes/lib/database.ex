defmodule Clothes.Database do
  use GenServer

  @db_folder "./persist"

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    key
    |> choose_worker
    |> Clothes.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker
    |> Clothes.DatabaseWorker.get(key)
  end

  defp choose_worker(key) do
    GenServer.call(__MODULE__, {:choose_worker, key})
  end

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_folder)

    workers =
      Enum.reduce(0..2, %{}, fn id, acc ->
        {:ok, pid} = Clothes.DatabaseWorker.start(@db_folder)
        Map.put(acc, id, pid)
      end)

    {:ok, workers}
  end

  @impl GenServer
  def handle_call({:choose_worker, key}, _, state) do
    pid = state[:erlang.phash2(key, 3)]
    {:reply, pid, state}
  end
end
