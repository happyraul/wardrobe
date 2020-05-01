defmodule Clothes.Wear do
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

  schema "t_wears" do
    field(:worn_at, :utc_datetime)
    field(:location, :string)
    belongs_to(:item, Clothes.Item)
    timestamps()
  end

  def changeset(wear, params \\ %{}) do
    wear
    |> cast(params, [
      :worn_at,
      :location,
      :item_id
    ])
    |> validate_required([:worn_at])
    |> validate_length(:location, max: 50)
    |> assoc_constraint(:item)
  end
end
