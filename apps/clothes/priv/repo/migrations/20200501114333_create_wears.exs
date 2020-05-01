defmodule Clothes.Repo.Migrations.CreateWears do
  use Ecto.Migration

  def change do
    create table(:t_wears) do
      add :a_item, references(:t_items, column: :a_id), null: false
      add :a_worn_at, :utc_datetime, null: false
      add :a_location, :text, null: true
      timestamps(inserted_at: :a_inserted_at, updated_at: :a_updated_at)
    end

    create index(:t_wears, [:a_item])
  end
end
