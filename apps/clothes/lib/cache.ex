defmodule Clothes.Cache do
  def start_link() do
    IO.puts("Starting clothes cache")

    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  def server_process(user_id) do
    case start_child(user_id) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(user_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Clothes.Server, user_id}
    )
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end
end
