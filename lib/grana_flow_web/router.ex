defmodule GranaFlowWeb.Router do
  use GranaFlowWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :auth do
    plug Guardian.Plug.VerifyHeader,
      module: GranaFlow.Guardian,
      scheme: "Bearer",
      error_handler: GranaFlowWeb.GuardianErrorHandler

    plug Guardian.Plug.LoadResource,
      module: GranaFlow.Guardian,
      error_handler: GranaFlowWeb.GuardianErrorHandler

    plug Guardian.Plug.EnsureAuthenticated,
      module: GranaFlow.Guardian,
      error_handler: GranaFlowWeb.GuardianErrorHandler
  end

  pipeline :refresh do
    plug GranaFlowWeb.Plugs.EnsureTokenType, "refresh"
  end

  pipeline :main do
    plug GranaFlowWeb.Plugs.EnsureTokenType, "main"
  end

  pipeline :premium do
    plug GranaFlowWeb.Plugs.EnsureUserPremium, true
  end

  scope "/api", GranaFlowWeb do
    pipe_through :api
    pipe_through :auth
    pipe_through :main

    post "/wallet", WalletController, :create
    delete "/wallet", WalletController, :delete
    patch "/wallet", WalletController, :edit
    get "/wallet", WalletController, :all
    get "/wallet/:wallet_id/reports/annual", TransactionController, :annual_report
    get "/wallet/:wallet_id/reports/month", TransactionController, :month_report

    post "/transaction/single", TransactionController, :create
    post "/transaction/recurrent", TransactionController, :create_recurrent
    get "/transaction/balance", TransactionController, :balance
    get "/transaction/:transaction_id/:wallet_id", TransactionController, :get
    delete "/transaction/:transaction_id/:wallet_id", TransactionController, :delete
    patch "/transaction/:transaction_id/:wallet_id", TransactionController, :edit
    get "/transaction", TransactionController, :all

    post "/upgrade", PaymentController, :create
  end

  scope "/api/premium", GranaFlowWeb do
    pipe_through :api
    pipe_through :auth
    pipe_through :main
    pipe_through :premium

    post "/custom-subtypes", CustomSubtypeController, :create
    get "/custom-subtypes", CustomSubtypeController, :all
    post "/proof", ProofController, :create
  end

  scope "/auth", GranaFlowWeb do
    pipe_through :api

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/refresh", GranaFlowWeb do
    pipe_through :api
    pipe_through :auth
    pipe_through :refresh

    get "/", AuthController, :validate_token
  end

  scope "/payment", GranaFlowWeb do
    post "/notification", PaymentController, :notification
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:grana_flow, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: GranaFlowWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
