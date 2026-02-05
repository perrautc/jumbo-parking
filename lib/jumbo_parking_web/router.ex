defmodule JumboParkingWeb.Router do
  use JumboParkingWeb, :router

  import JumboParkingWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JumboParkingWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public pages
  scope "/", JumboParkingWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/booking", BookingLive, :index
  end

  # Admin login (guest only)
  scope "/admin", JumboParkingWeb.Admin do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live "/login", LoginLive, :index
  end

  # Admin authentication action routes
  scope "/admin", JumboParkingWeb do
    pipe_through [:browser]

    post "/login", UserSessionController, :create
    delete "/logout", UserSessionController, :delete
  end

  # Admin protected routes
  scope "/admin", JumboParkingWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin,
      on_mount: [{JumboParkingWeb.Admin.AdminAuth, :ensure_admin}] do
      live "/", DashboardLive, :index
      live "/customers", CustomersLive, :index
      live "/spaces", SpacesLive, :index
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:jumbo_parking, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: JumboParkingWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
