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
    |> Enum.filter(fn {key, _value} ->
      Regex.match?(form_key, key)
    end)
    |> Enum.reduce(
      %{},
      fn {key, value}, acc ->
        [_, event, guest] = Regex.run(form_key, key)

        answer =
          if value == "yes" do
            :yes
          else
            :no
          end

        answers = [{event, answer} | Map.get(acc, guest, [])]
        Map.put(acc, guest, answers)
      end
    )
    |> Enum.each(fn {guest_id, answers} ->
      {events, declined_events} = parse_answers(answers)
      MyGuest.update_rsvp!(guest_id, %{"events" => events, "declined_events" => declined_events})
    end)

    put_flash(conn, :info, "Updated RSVP")
    |> redirect(to: ~p"/rsvp/1")
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
