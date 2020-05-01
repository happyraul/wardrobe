defmodule Clothes.Server do
  use GenServer, restart: :temporary

  def start_link(user_id) do
    IO.puts("Starting clothes server for #{user_id}")
    GenServer.start_link(Clothes.Server, user_id, name: via_tuple(user_id))
  end

  defp via_tuple(user_id) do
    Clothes.ProcessRegistry.via_tuple({__MODULE__, user_id})
  end

  def add_item(pid, new_item) do
    GenServer.call(pid, {:add_item, new_item})
  end

  def all(pid) do
    GenServer.call(pid, :clothes)
  end

  def clothes(pid, name, color) do
    GenServer.call(pid, {:clothes, name, color})
  end

  def update_item(pid, %{} = new_item) do
    GenServer.cast(pid, {:update_item, new_item})
  end

  def delete_item(pid, item_id) do
    GenServer.cast(pid, {:delete_item, item_id})
  end

  @expiry_idle_timeout :timer.seconds(60)

  @impl GenServer
  def init(user_id) do
    send(self(), :real_init)
    {:ok, user_id, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_info(:real_init, user_id) do
    {:noreply, user_id, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_info(:timeout, user_id) do
    IO.puts("Stopping clothes server for #{user_id}")
    {:stop, :normal, user_id}
  end

  @impl GenServer
  def handle_cast({:update_item, new_item}, user_id) do
    %Clothes.Item{id: new_item.id, user_id: user_id}
    |> Clothes.update_item(new_item)

    {:noreply, user_id, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:delete_item, item_id}, user_id) do
    Clothes.delete_item(item_id)
    {:noreply, user_id, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call(:clothes, _, user_id) do
    {:reply, Clothes.all(), user_id, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:clothes, name, color}, _, user_id) do
    {:reply, Clothes.clothes(name, color), user_id, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:add_item, new_item}, _, user_id) do
    {:ok, item} = Clothes.add_item(Map.put(new_item, :user_id, user_id))
    {:reply, item.id, user_id, @expiry_idle_timeout}
  end
end
