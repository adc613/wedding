defmodule AppWeb.Router do
  use AppWeb, :router

  import AppWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :guest_live_view_extras do
    plug :insecurely_fetch_guest_id
  end

  pipeline :admin_layout do
    plug :put_layout, html: {AppWeb.Layouts, :admin}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/std", PageController, :std
    get "/story", PageController, :story
    get "/photos", PageController, :photos
    get "/travel", PageController, :travel
    get "/things", PageController, :things_to_do
    get "/robey", PageController, :robey
    get "/schedule", PageController, :schedule
    get "/registry", RegistryController, :registry
    post "/registry", RegistryController, :confirm_tor
  end

  scope "/rsvp", AppWeb do
    pipe_through :browser

    get "/", RSVPController, :rsvp
    post "/reset", RSVPController, :reset_guest_id
    put "/invite", RSVPController, :update_rsvp
    post "/lookup", RSVPController, :lookup_invite
    post "/add_guest", RSVPController, :add_guest
  end

  scope "/rsvp", AppWeb do
    pipe_through [:browser, :require_rsvp_lookup]

    get "/edit", RSVPController, :edit
    get "/thanks", RSVPController, :thanks

    scope "/confirm" do
      get "/", RSVPController, :confirm
      get "/add_guest", RSVPController, :add_guest_form
      get "/add_kids", RSVPController, :add_kid_form
      get "/:step_id", RSVPController, :confirm
    end
  end

  scope "/invitation", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    resources "/", InvitationController
    put "/:id/remove_guest", InvitationController, :remove_guest
    put "/:id/add_guest", InvitationController, :add_guest
  end

  scope "/guest", AppWeb do
    pipe_through [:browser, :maybe_require_authenticated_user]

    resources "/", GuestsController
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AppWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{AppWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      # Disable user registration to prevent any one from registering an account.
      # All account are registered by seeding the database.
      # NOTE: Some test will fail without this line. I'm too lazy to fix them.
      # live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/admin", AppWeb do
    pipe_through [:browser, :require_authenticated_user, :admin_layout]

    get "/", AdminController, :landing

    live_session :require_authenticated_admin,
      on_mount: [{AppWeb.UserAuth, :ensure_authenticated}] do
      live "/dash", DashboardLive
      live "/guest", GuestManageLive
      live "/invitation", InvitationManageLive
    end
  end

  scope "/export", AppWeb do
    pipe_through [:browser, :require_authenticated_user_or_super_secure_api_key]

    get "/invite", ExportController, :invite
    get "/rsvp", ExportController, :rsvp
    get "/guest", ExportController, :guest_list
  end

  scope "/", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AppWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", AppWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{AppWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/faq", AppWeb do
    pipe_through [:browser, :guest_live_view_extras]

    live_session :require_guest_id,
      on_mount: [{AppWeb.UserAuth, :mount_current_user}, {AppWeb.UserAuth, :mount_current_guest}] do
      live "/", FaqLive
    end
  end
end
