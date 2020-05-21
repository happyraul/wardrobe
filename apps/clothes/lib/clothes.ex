defmodule Clothes do
  @moduledoc """
  Documentation for Clothes.
  """
  import Ecto
  import Ecto.Query

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
    %Clothes.User{}
    |> Clothes.User.changeset_with_password(params)
    |> @repo.insert()
  end

  def all() do
    wears_select =
      from(
        wear in Clothes.Wear,
        select: %{
          item_id: wear.item_id,
          worn_at: max(wear.worn_at),
          wear_count: count("*")
        },
        group_by: [:item_id]
      )

    @repo.all(
      from(
        item in Clothes.Item,
        left_join: wear in subquery(wears_select),
        on: item.id == wear.item_id,
        select: %Clothes.Item{
          item
          | last_worn: wear.worn_at,
            wear_count: wear.wear_count
        }
      )
    )
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

  def delete_item(item_id) do
    %Clothes.Item{id: item_id}
    |> @repo.delete()
  end

  def wear_item(id) do
    %Clothes.Wear{}
    |> Clothes.Wear.changeset(%{
      item_id: id,
      worn_at: DateTime.now!("Etc/UTC")
    })
    |> @repo.insert()
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
