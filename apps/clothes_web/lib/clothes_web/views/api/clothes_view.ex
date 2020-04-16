defmodule ClothesWeb.Api.ClothesView do
  use ClothesWeb, :view

  def render("all.json", %{items: items}) do
    %{data: render_many(items, __MODULE__, "item_detail.json", as: :item)}
  end

  def render("item.json", %{item_id: item_id}) do
    %{data: %{id: item_id}}
  end

  def render("item_detail.json", %{item: item}) do
    %{
      id: item.id,
      name: item.name,
      color: item.color
    }
  end
end
