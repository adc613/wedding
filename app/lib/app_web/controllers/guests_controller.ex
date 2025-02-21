defmodule AppWeb.GuestsController do
  use AppWeb, :controller

  alias App.Guest.RSVP
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
        |> redirect(to: ~p"/guest/#{guest}")

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
        |> redirect(to: ~p"/guest/#{guest}")

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

  def rsvp(conn, %{"guests_id" => guests_id, "secret" => secret}) do
    guest = MyGuest.get_guest(guests_id)

    guest =
      case guest do
        nil ->
          :not_found

        %{secret: nil} ->
          MyGuest.update!(guest, %{"secret" => secret})

        guest ->
          guest
      end

    case guest do
      :not_found ->
        render_not_found(conn)

      %{secret: ^secret} ->
        changeset = RSVP.changeset(%RSVP{})
        render(conn, :rsvp, guest: guest, changeset: changeset)

      _guest_with_incorrect_secret ->
        render_forbidden(conn)
    end
  end

  def rsvp(conn, %{"guests_id" => guests_id}) do
    rsvp(conn, %{"guests_id" => guests_id, "secret" => Guest.gen_secret()})
  end

  def rsvp_update(conn, %{"guests_id" => guests_id, "rsvp" => rsvp_params}) do
    MyGuest.get_or_create_rsvp!(guests_id)
    |> MyGuest.update(rsvp_params)

    put_flash(conn, :info, "Received RSVP")
    |> redirect(to: ~p"/guest/#{guests_id}/rsvp")
  end

  defp render_forbidden(conn) do
    render_not_found(conn)
  end
end
