defmodule ClothesWeb.Api.ClothesView do
  use ClothesWeb, :view

  def render("all.json", %{items: items}) do
    %{data: items}
  end
end
