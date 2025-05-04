defmodule AppWeb.GuestsController do
  use AppWeb, :controller

  alias App.MyGuest
  alias App.Guest.Guest

  def index(conn, _params) do
    guests = MyGuest.list_guests()
    render(conn, :index, guests: guests)
  end

  def show(conn, %{"id" => id}) do
    case MyGuest.get_guest(id) do
      nil -> render_not_found(conn)
      guest -> render(conn, :detail, guest: guest)
    end
  end

  def edit(conn, %{"id" => id}) do
    guest = MyGuest.get_guest!(id)
    changeset = Guest.changeset(guest)
    render(conn, :edit, guest: guest, changeset: changeset)
  end

  def new(conn, _params) do
    changeset = Guest.changeset(%Guest{})

    conn
    |> render(:new, changeset: changeset)
  end

  def create(conn, %{"guest" => guest_params}) do
    case MyGuest.create_guest(guest_params) do
      {:ok, guest} ->
        conn
        |> put_flash(:info, "Created new Guest")
        |> redirect(to: ~p"/guest_old/#{guest}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "guest" => guest_params}) do
    guest = MyGuest.get_guest!(id)

    case MyGuest.update(guest, guest_params) do
      {:ok, guest} ->
        conn
        |> put_flash(:info, "Updated guest")
        |> redirect(to: ~p"/guest_old/#{guest}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    result =
      MyGuest.get_guest!(id)
      |> MyGuest.delete()

    case result do
      {:ok, _guest} ->
        conn
        |> put_flash(:info, "Deleted guest")
        |> redirect(to: ~p"/guest")

      {:error, _guest} ->
        conn
        |> put_flash(:error, "Failed to delete guest")
        |> redirect(to: ~p"/guest")
    end
  end
end
