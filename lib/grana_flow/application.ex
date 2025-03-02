defmodule GranaFlow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GranaFlowWeb.Telemetry,
      GranaFlow.Repo,
      {DNSCluster, query: Application.get_env(:grana_flow, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GranaFlow.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GranaFlow.Finch},
      # Start a worker by calling: GranaFlow.Worker.start_link(arg)
      # {GranaFlow.Worker, arg},
      # Start to serve requests, typically the last entry
      GranaFlowWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GranaFlow.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GranaFlowWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
