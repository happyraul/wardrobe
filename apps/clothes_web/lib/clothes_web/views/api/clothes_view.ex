defmodule ClothesWeb.Api.ClothesView do
  use ClothesWeb, :view

  def render("all.json", %{items: items}) do
    %{data: items}
  end

  def render("item.json", %{item_id: item_id}) do
    %{data: %{id: item_id}}
  end
end
