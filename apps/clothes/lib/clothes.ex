defmodule Clothes do
  @moduledoc """
  Documentation for Clothes.
  """

  @repo Clothes.Repo

  @doc """
  Hello world.

  ## Examples

      iex> Clothes.new()
      %Clothes{}

  """

  # def new(), do: %Clothes{}

  # def new(entries \\ []) do
  #   Enum.reduce(entries, %Clothes{}, &add_item(&2, &1))
  # end

  def get_users() do
    @repo.all(Clothes.User)
  end

  def get_user(id), do: @repo.get!(Clothes.User, id)

  def find_user(id), do: @repo.get(Clothes.User, id)

  def insert_user(params) do
    Clothes.User
    |> struct(params)
    |> @repo.insert
  end

  def all() do
    @repo.all(Clothes.Item)
  end

  def add_item(item) do
    IO.inspect(item)

    %Clothes.Item{}
    |> Clothes.Item.changeset(item)
    |> @repo.insert()
  end

  # def clothes(items, name, color) do
  #   items.clothing
  #   |> Stream.filter(fn {_, item} -> item.name == name end)
  #   |> Enum.map(fn {_, item} -> item end)
  # end

  def update_item(%Clothes.Item{} = item, updates) do
    item
    |> Clothes.Item.changeset(updates)
    |> @repo.update()
  end

  # def delete_item(items, item_id) do
  #   new_clothing =
  #     items.clothing
  #     |> Stream.filter(fn {id, _} -> id != item_id end)
  #     |> Map.new()

  #   %Clothes{items | clothing: new_clothing}
  # end
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
