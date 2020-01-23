defmodule Clothes.Application do
  use Application

  def start(_, _) do
    Clothes.System.start_link()
  end
end
