defmodule Clothes.Item do
  import Ecto.Changeset
  use Ecto.Schema

  map_field = fn field ->
    name = to_string(field)

    if String.ends_with?(name, "_id") do
      "a_" <> String.slice(name, 0..-4)
    else
      "a_" <> name
    end
    |> String.to_atom()
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  @field_source_mapper map_field
  @foreign_key_type :binary_id

  schema "t_items" do
    field(:name, :string)
    field(:color, :string)
    field(:quantity, :integer, default: 1)
    field(:description, :string)
    field(:brand, :string)
    field(:value, :integer)
    field(:location, :string)
    belongs_to(:user, Clothes.User)
    timestamps()
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [
      :name,
      :color,
      :quantity,
      :description,
      :brand,
      :value,
      :location,
      :user_id
    ])
    |> validate_required([:name, :color, :user_id, :quantity])
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:brand, max: 50)
    |> validate_length(:location, max: 50)
    |> validate_length(:description, max: 500)
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:value, greater_than_or_equal_to: 0)
    |> assoc_constraint(:user)
  end
end
