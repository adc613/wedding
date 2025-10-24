defmodule AppWeb.RegistryController do
  alias Inspect.AppWeb.PageController.RegistryForm
  use AppWeb, :controller

  defmodule RegistryForm do
    use Ecto.Schema

    # Omit this line if not backed by a database
    schema "registry_form" do
      field :tor, :boolean
    end

    def changeset(form_struct, attrs \\ %{}) do
      form_struct
      |> Ecto.Changeset.cast(attrs, [:tor])
      |> Ecto.Changeset.validate_required([:tor])
    end
  end

  def registry(conn, _params) do
    changeset = RegistryForm.changeset(%RegistryForm{tor: false}, %{"tor" => false})

    tor =
      conn
      |> fetch_cookies()
      |> then(&Map.get(&1.cookies, "tor", false))
      |> case do
        "true" -> true
        _ -> false
      end

    render(conn, :registry, %{changeset: changeset, show_link: tor})
  end

  def confirm_tor(conn, params) do
    params
    |> case do
      %{"registry_form" => %{"tor" => "true"}} ->
        conn
        |> put_resp_cookie("tor", "true")
        |> redirect(to: ~p"/registry")

      _ ->
        changeset = RegistryForm.changeset(%RegistryForm{}, %{"tor" => nil})
        render(conn, :registry, %{changeset: changeset, show_link: false})
    end
  end
end
