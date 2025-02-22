defmodule AppWeb.RSVPController do
  use AppWeb, :controller

  alias App.Guest.RSVP
  alias App.MyGuest
  alias App.Guest.Guest

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
