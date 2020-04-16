defmodule Clothes.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:t_items) do
      add :a_user, references(:t_users, column: :a_id), null: false
      add :a_name, :text, null: false
      add :a_color, :text, null: false
      add :a_quantity, :integer, null: false, default: 1
      add :a_description, :text, null: true
      add :a_brand, :text, null: true
      add :a_value, :integer, null: true
      add :a_location, :text, null: true
      timestamps(inserted_at: :a_inserted_at, updated_at: :a_updated_at)
    end

    create unique_index(:t_items, [:a_user, :a_name, :a_color])
    create index(:t_items, [:a_user])
  end
end
