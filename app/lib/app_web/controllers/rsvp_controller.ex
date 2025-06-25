defmodule AppWeb.RSVPController do
  use AppWeb, :controller

  alias App.Guest.RSVP
  alias App.MyGuest
  alias App.Guest.Guest

  def rsvp(conn, _params) do
    conn
    |> fetch_cookies(encrypted: ~w(guest-id))
    |> case do
      %{cookies: %{"guest-id" => guest_id}} ->
        conn |> render_invite(guest_id)

      _ ->
        conn |> render_lookup()
    end
  end

  def confirm_guest_details(conn, _params) do
    guest_id =
      conn
      |> fetch_cookies(encrypted: ~w(guest-id))
      |> case do
        %{cookies: %{"guest-id" => guest_id}} -> guest_id
        _ -> nil
      end

    invitation =
      case guest_id do
        nil -> nil
        guest_id -> MyGuest.get_invitation(guest_id: guest_id, preload: :guests)
      end

    if guest_id == nil or invitation == nil do
      conn |> render_not_found()
    else
      changeset = RSVP.changeset(%RSVP{})

      conn
      |> render(:confirm, invitation: invitation, changeset: changeset, guest_id: guest_id)
    end
  end

  def reset_guest_id(conn, _params) do
    conn
    |> delete_resp_cookie("guest-id")
    |> redirect(to: ~p"/rsvp")
  end

  def lookup_invite(conn, %{"guest" => %{"email" => email}}) do
    email = String.trim(email)

    case Guest.apply_lookup(%Guest{}, %{"email" => email}) do
      {:error, changeset} ->
        conn |> render_lookup(changeset: changeset)

      {:ok, _changeset} ->
        MyGuest.get_guest(email: email, preload: :rsvp)
        |> case do
          %Guest{rsvp: nil} = guest ->
            conn
            |> put_resp_cookie("guest-id", guest.id, encrypt: true)
            |> redirect(to: ~p"/rsvp/confirm")

          %Guest{} = guest ->
            conn
            |> put_resp_cookie("guest-id", guest.id, encrypt: true)
            |> redirect(to: ~p"/rsvp")

          _ ->
            conn |> render(:no_invitation, email: email)
        end
    end
  end

  def update_rsvp(conn, params) do
    _invitation = MyGuest.get_invitation(params["invitation_id"], preload: :guests)
    form_key = ~r/^(wedding|brunch|rehersal)-(\d+)$/

    params
    |> Enum.filter(fn {key, _value} -> Regex.match?(form_key, key) end)
    |> Enum.reduce(
      %{},
      fn {key, value}, acc ->
        {event, answer, guest_id} = parse_key(key, value, form_key)
        answers = [{event, answer} | Map.get(acc, guest_id, [])]
        Map.put(acc, guest_id, answers)
      end
    )
    |> Enum.each(fn {guest_id, answers} ->
      {events, declined_events} = parse_answers(answers)
      MyGuest.update_rsvp!(guest_id, %{"events" => events, "declined_events" => declined_events})
    end)

    conn
    |> put_flash(:info, "Updated RSVP")
    |> render_thanks()
  end

  defp render_thanks(conn) do
    conn |> render(:thanks)
  end

  defp render_lookup(conn, changeset: changeset) do
    conn |> render(:lookup, changeset: changeset, guests: [])
  end

  defp render_lookup(conn) do
    changeset = Guest.lookup_changeset(%Guest{})
    conn |> render(:lookup, changeset: changeset, guests: [])
  end

  defp render_invite(conn, guest_id) do
    case MyGuest.get_invitation(guest_id: guest_id, preload: :guests) do
      nil ->
        render(conn, :no_invitation, email: nil)

      invitation ->
        changeset = RSVP.changeset(%RSVP{})

        conn
        |> render(:rsvp, invitation: invitation, changeset: changeset, guest_id: guest_id)
    end
  end

  defp parse_key(key, value, form_key) do
    [_, event, guest_id] = Regex.run(form_key, key)

    if value == "yes" do
      {event, :yes, guest_id}
    else
      {event, :no, guest_id}
    end
  end

  defp parse_answers(answers) do
    Enum.reduce(answers, {[], []}, fn answer, {events, declined_events} ->
      case answer do
        {event, :yes} -> {[event | events], declined_events}
        {event, :no} -> {events, [event | declined_events]}
      end
    end)
  end
end
