defmodule AppWeb.GuestsController do 
  use AppWeb, :controller

  alias App.MyGuest
  alias App.Guest.Guest

  def index(conn, _params) do
    guests = MyGuest.list_guests();
    render(conn, :index, guests: guests)
  end

  def show(conn, %{"id" => id}) do
    guest = MyGuest.get_guest!(id)
    render(conn, :detail, guest: guest)
  end

  def edit(conn, %{"id" => id}) do
    guest = MyGuest.get_guest!(id)
    changeset = MyGuest.change_guest(guest)
    render(conn, :edit, guest: guest, changeset: changeset)
  end

  def new(conn, _params) do
    changeset = MyGuest.change_guest(%Guest{})
    conn
    |> put_flash(:info, "Creating Guest")
    |> render(:new, changeset: changeset)
  end

  def create(conn, %{"guest" => guest_params}) do
    case MyGuest.create(guest_params) do
      {:ok, guest} -> 
        conn
        |> put_flash(:info, "Created new Guest")
        |> redirect(to: ~p"/guests/#{guest}")
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
        |> redirect(to: ~p"/guests/#{guest}")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    guest = MyGuest.get_guest!(id)
    {:ok, _guest} = MyGuest.delete(guest)

    conn
    |> put_flash(:info, "Deleted guest")
    |> redirect(to: ~p"/guests")
  end
end
