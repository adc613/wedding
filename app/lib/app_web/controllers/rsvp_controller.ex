defmodule AppWeb.RSVPController do
  use AppWeb, :controller

  alias App.Guest.RSVP
  alias App.MyGuest
  alias App.Guest.Guest

  def lookup(conn, %{"guest" => %{"email" => email}}) do
    guest = MyGuest.get_guest(email: email)

    case guest do
      %Guest{id: id} ->
        redirect(conn, to: ~p"/guest/#{id}/rsvp")

      _ ->
        render_not_found(conn)
    end
  end

  def lookup(conn, _params) do
    changeset = Guest.lookup_changeset(%Guest{})
    render(conn, :landing, changeset: changeset, guests: [])
  end

  def rsvp(conn, %{"guests_id" => guests_id}) do
    case MyGuest.get_guest(guests_id) do
      nil ->
        render_not_found(conn)

      guest ->
        changeset = RSVP.changeset(%RSVP{})
        render(conn, :rsvp, guests: [guest], changeset: changeset)
    end
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
