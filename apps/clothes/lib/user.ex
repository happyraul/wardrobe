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
    has_many(:items, Clothes.Item, on_delete: :delete_all)
    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [
      :display_name,
      :email_address
    ])
    |> validate_required([:display_name, :email_address, :hashed_password])
    |> lower_email()
    |> validate_length(:display_name, min: 1, max: 30)
    |> unique_constraint(:email_address)
  end

  def changeset_with_password(user, params \\ %{}) do
    user
    |> cast(params, [
      :password
    ])
    |> validate_required(:password)
    |> validate_length(:password, min: 8, max: 100)
    |> validate_confirmation(:password, required: true)
    |> hash_password()
    |> changeset(params)
  end

  defp hash_password(
         %Ecto.Changeset{
           changes: %{password: password}
         } = changeset
       ) do
    changeset
    |> put_change(:hashed_password, Clothes.Password.hash(password))
  end

  # if no password, do nothing
  defp hash_password(changeset), do: changeset

  defp lower_email(
         %Ecto.Changeset{
           changes: %{email_address: email_address}
         } = changeset
       ) do
    changeset
    |> put_change(:email_address, String.downcase(email_address))
  end

  # if no email, do nothing
  defp lower_email(changeset), do: changeset
end
