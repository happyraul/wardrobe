# Since configuration is shared in umbrella projects, this file
# should only configure the :clothes_web application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

# General application configuration
config :clothes_web,
  generators: [context_app: false]

# Configures the endpoint
config :clothes_web, ClothesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7uJV1D67DF/sr6u48JbObkSH7we6xTBhvlP3qu8NOeh+SQIvT8gX91mETbLKRcuT",
  render_errors: [view: ClothesWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ClothesWeb.PubSub, adapter: Phoenix.PubSub.PG2]

config :phoenix,
  json_library: Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
