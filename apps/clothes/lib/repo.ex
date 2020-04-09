defmodule Clothes.Repo do
  use Ecto.Repo,
    otp_app: :clothes,
    adapter: Ecto.Adapters.Postgres
end
