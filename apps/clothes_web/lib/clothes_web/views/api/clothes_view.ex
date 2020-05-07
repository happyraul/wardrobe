defmodule ClothesWeb.Api.ClothesView do
  use ClothesWeb, :view

  def render("all.json", %{items: items}) do
    %{data: render_many(items, __MODULE__, "item_detail.json", as: :item)}
  end

  def render("item.json", %{item_id: item_id}) do
    %{data: %{id: item_id}}
  end

  def render("wear.json", %{last_worn: last_worn}) do
    %{data: %{last_worn: last_worn}}
  end

  def render("item_detail.json", %{item: item}) do
    %{
      id: item.id,
      name: item.name,
      color: item.color,
      last_worn: item.last_worn
    }
  end
end
