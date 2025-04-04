# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :grana_flow,
  ecto_repos: [GranaFlow.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :grana_flow, GranaFlowWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: GranaFlowWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GranaFlow.PubSub,
  live_view: [signing_salt: "xoHVDKsT"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :grana_flow, GranaFlow.Mailer, adapter: Swoosh.Adapters.Local

# Dependencies
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]},
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :grana_flow, GranaFlow.Guardian,
  issuer: "grana_flow",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY")

config :grana_flow, GranaFlow.Services.Payment,
  mp_access_token: System.get_env("MP_ACCESS_TOKEN")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
