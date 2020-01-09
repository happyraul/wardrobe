defmodule Clothes.System do
  def start_link do
    Supervisor.start_link(
      [
        Clothes.ProcessRegistry,
        Clothes.Database,
        Clothes.Cache
      ],
      strategy: :one_for_one
    )
  end
end
