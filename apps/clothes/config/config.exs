use Mix.Config

config :clothes, ecto_repos: [Clothes.Repo]

config :clothes, Clothes.Repo,
  database: "wardrobe",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: "5432",
  migration_primary_key: [name: :a_id, type: :binary_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
