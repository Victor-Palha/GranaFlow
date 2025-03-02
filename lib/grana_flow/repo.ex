defmodule GranaFlow.Repo do
  use Ecto.Repo,
    otp_app: :grana_flow,
    adapter: Ecto.Adapters.Postgres
end
