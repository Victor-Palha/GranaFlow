defmodule GranaFlowWeb.Router do
  use GranaFlowWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug Guardian.Plug.VerifyHeader, module: GranaFlow.Guardian, scheme: "Bearer", error_handler: GranaFlowWeb.GuardianErrorHandler
    plug Guardian.Plug.LoadResource, module: GranaFlow.Guardian, error_handler: GranaFlowWeb.GuardianErrorHandler
    plug Guardian.Plug.EnsureAuthenticated, module: GranaFlow.Guardian, error_handler: GranaFlowWeb.GuardianErrorHandler
  end

  scope "/api", GranaFlowWeb do
    pipe_through :api
    pipe_through :auth

    get "/test", AuthController, :test
    post "/wallet", WalletController, :create
    delete "/wallet", WalletController, :delete
    get "/wallet", WalletController, :all
    post "/transaction", TransactionController, :create
    get "/transaction/:transaction_id", TransactionController, :get
  end


  scope "/auth", GranaFlowWeb do
    pipe_through :api

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
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
