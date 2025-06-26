defmodule AppWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use AppWeb, :controller
      use AppWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """
  alias AppWeb.ErrorHTML

  def static_paths, do: ~w(assets fonts images favicon.ico site.webmanifest robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: AppWeb.Layouts]

      use Gettext, backend: AppWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())

      defp render_not_found(conn) do
        conn |> put_status(:not_found) |> put_view(ErrorHTML) |> render(:"404")
      end

      defp get_guest_id(conn) do
        conn
        |> fetch_cookies(encrypted: ~w(guest-id))
        |> case do
          %{cookies: %{"guest-id" => guest_id}} -> guest_id
          _ -> nil
        end
      end
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {AppWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: AppWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import AppWeb.CoreComponents

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AppWeb.Endpoint,
        router: AppWeb.Router,
        statics: AppWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule AppWeb.NotFoundError do
  defexception [:message, plug_status: 404]
end

defimpl Plug.Exception, for: MyApp.NotFoundError do
  def status(_exception), do: 404
  def actions(_exception), do: []
end
