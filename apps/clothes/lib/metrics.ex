defmodule Clothes.Metrics do
  use Task

  def start_link(_arg) do
    {:ok, pid} = Task.start_link(&loop/0)
    IO.inspect(pid)
    {:ok, pid}
  end

  defp loop() do
    Process.sleep(:timer.seconds(10))
    IO.inspect(collect_metrics())
    loop()
  end

  defp collect_metrics() do
    [
      memory_usage: :erlang.memory(:total),
      process_count: :erlang.system_info(:process_count)
    ]
  end
end
