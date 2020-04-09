defmodule Clothes.User do
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @field_source_mapper fn f -> String.to_atom("a_" <> to_string(f)) end

  schema "t_users" do
    field(:email_address, :string)
    field(:password, :string, virtual: true)
    field(:hashed_password, :string)
    field(:display_name, :string)
    timestamps()
  end
end
