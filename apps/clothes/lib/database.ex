defmodule Clothes.Database do
  @pool_size 3
  @db_folder "./persist"

  def child_spec(_) do
    File.mkdir_p!(@db_folder)

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: Clothes.DatabaseWorker,
        size: @pool_size
      ],
      [@db_folder]
    )
  end

  def store(key, data) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Clothes.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Clothes.DatabaseWorker.get(worker_pid, key)
      end
    )
  end
end
