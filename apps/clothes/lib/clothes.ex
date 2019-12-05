defmodule Clothes do
  @moduledoc """
  Documentation for Clothes.
  """

  defstruct auto_id: 1, clothing: %{}

  @doc """
  Hello world.

  ## Examples

      iex> Clothes.new()
      %Clothes{}

  """
  def new(), do: %Clothes{}

  def new(entries \\ []) do
    Enum.reduce(entries, %Clothes{}, &add_item(&2, &1))
  end

  def add_item(items, item) do
    item = Map.put(item, :id, items.auto_id)
    new_clothing = Map.put(items.clothing, items.auto_id, item)

    %Clothes{items | clothing: new_clothing, auto_id: items.auto_id + 1}
  end

  def all(items) do
    items.clothing
    |> Enum.map(fn {_, item} -> item end)
  end

  def clothes(items, name, color) do
    items.clothing
    |> Stream.filter(fn {_, item} -> item.name == name end)
    |> Enum.map(fn {_, item} -> item end)
  end

  def update_item(items, item_id, updater_fun) do
    case Map.fetch(items.clothing, item_id) do
      :error ->
        items

      {:ok, old_item} ->
        new_item = updater_fun.(old_item)
        new_clothing = Map.put(items.clothing, new_item.id, new_item)
        %Clothes{items | clothing: new_clothing}
    end
  end

  def update_item(items, %{} = new_item) do
    update_item(items, new_item.id, fn _ -> new_item end)
  end

  def delete_item(items, item_id) do
    new_clothing =
      items.clothing
      |> Stream.filter(fn {id, _} -> id != item_id end)
      |> Map.new()

    %Clothes{items | clothing: new_clothing}
  end
end

defimpl Collectable, for: Clothes do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(clothing, {:cont, item}) do
    Clothes.add_item(clothing, item)
  end

  defp into_callback(clothing, :done), do: clothing
  defp into_callback(clothing, :halt), do: :ok
end
