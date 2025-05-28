defmodule AppWeb.RSVPController do
  use AppWeb, :controller

  alias App.Guest.RSVP
  alias App.MyGuest
  alias App.Guest.Guest

  def rsvp(conn, _params) do
    changeset = Guest.lookup_changeset(%Guest{})
    render(conn, :lookup, changeset: changeset, guests: [])
  end

  def find_rsvp(conn, %{"guest" => %{"email" => email}}) do
    email = String.trim(email)

    case Guest.apply_lookup(%Guest{}, %{"email" => email}) do
      {:error, changeset} ->
        render(conn, :lookup, changeset: changeset, guests: [])

      {:ok, _changeset} ->
        MyGuest.get_guest(email: email)
        |> case do
          %Guest{} = guest ->
            redirect(conn, to: ~p"/rsvp/#{guest}")

          _ ->
            render(conn, :no_invitation, email: email)
        end
    end
  end

  def find_rsvp(conn, %{"guest_id" => guest_id}) do
    case MyGuest.get_invitation(guest_id: guest_id, preload: :guests) do
      nil ->
        render(conn, :no_invitation, email: nil)

      invitation ->
        changeset = RSVP.changeset(%RSVP{})

        put_flash(conn, :info, "Found invitation")
        |> render(:rsvp, invitation: invitation, changeset: changeset, guest_id: guest_id)
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
    |> redirect(to: ~p"/rsvp/1")
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
