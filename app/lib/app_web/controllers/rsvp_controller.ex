defmodule AppWeb.RSVPController do
  use AppWeb, :controller

  alias App.Guest.RSVP
  alias App.MyGuest
  alias App.Guest.Guest

  def rsvp(conn, _params) do
    conn
    |> get_guest_id()
    |> case do
      nil ->
        nil

      guest_id ->
        MyGuest.get_guest(guest_id, preload: :rsvp)
    end
    |> case do
      nil ->
        render_lookup(conn)

      %Guest{rsvp: nil} ->
        redirect(conn, to: ~p"/rsvp/edit")

      %Guest{invitation_id: invitation_id} ->
        if MyGuest.all_rsvp?(invitation_id) do
          redirect(conn, to: ~p"/rsvp/thanks")
        else
          redirect(conn, to: ~p"/rsvp/edit")
        end

      _ ->
        render_not_found(conn)
    end
  end

  def edit(conn, _params) do
    guest_id = get_guest_id(conn)

    case MyGuest.get_invitation(guest_id: guest_id, preload: :guests) do
      nil ->
        render(conn, :no_invitation, email: nil)

      invitation ->
        changeset = RSVP.changeset(%RSVP{})

        conn
        |> render(:rsvp, invitation: invitation, changeset: changeset, guest_id: guest_id)
    end
  end

  def confirm(conn, %{"step_id" => "0"}) do
    %{guest_id: guest_id, invitation: invitation} = get_confirm_details(conn)

    guest = MyGuest.get_guest!(guest_id)
    changeset = Guest.changeset(guest)

    if guest_id == nil or invitation == nil do
      conn |> render_not_found()
    else
      conn
      |> render(:confirm_email,
        invitation: invitation,
        guest_id: guest_id,
        step_id: 1,
        guest: guest,
        changeset: changeset
      )
    end
  end

  def confirm(conn, %{"step_id" => "1"}) do
    %{guest_id: guest_id, invitation: invitation} = get_confirm_details(conn)

    cond do
      guest_id == nil or invitation == nil ->
        conn |> render_not_found()

      invitation.additional_guests <= 0 ->
        confirm(conn, %{"step_id" => "2"})

      true ->
        conn |> render(:confirm_plus_ones, invitation: invitation, guest_id: guest_id, step_id: 1)
    end
  end

  def confirm(conn, %{"step_id" => "2"}) do
    %{guest_id: guest_id, invitation: invitation} = get_confirm_details(conn)

    cond do
      guest_id == nil or invitation == nil ->
        conn |> render_not_found()

      not invitation.permit_kids ->
        confirm(conn, %{"step_id" => "3"})

      true ->
        conn
        |> render(:confirm_kids, invitation: invitation, guest_id: guest_id, step_id: 2)
    end
  end

  def confirm(conn, %{"step_id" => "3"}) do
    %{guest_id: guest_id, invitation: invitation} = get_confirm_details(conn)

    if guest_id == nil or invitation == nil do
      conn |> render_not_found()
    else
      conn
      |> render(:confirm_guests, invitation: invitation, guest_id: guest_id, step_id: 3)
    end
  end

  def confirm(conn, %{"step_id" => _}), do: conn |> redirect(to: ~p"/rsvp")
  def confirm(conn, _params), do: conn |> redirect(to: ~p"/rsvp/confirm/0")

  def reset_guest_id(conn, _params),
    do: conn |> delete_resp_cookie("guest-id") |> redirect(to: ~p"/rsvp")

  def lookup_invite(conn, %{"guest" => %{"phone" => phone}}) do
    MyGuest.get_guest(phone: phone)
    |> case do
      nil -> nil
      :many_matches -> :many_matches
      guest -> MyGuest.load(guest, preload: :rsvp)
    end
    |> case do
      %Guest{rsvp: nil} = guest ->
        conn
        |> put_resp_cookie("guest-id", guest.id, encrypt: true)
        |> redirect(to: ~p"/rsvp/confirm")

      %Guest{} = guest ->
        conn
        |> put_resp_cookie("guest-id", guest.id, encrypt: true)
        |> redirect(to: ~p"/rsvp")

      :many_matches ->
        conn
        |> put_flash(
          :error,
          "There are multiple guest with the same information. Please contact Helen or Adam."
        )

      _ ->
        conn |> render(:no_invitation, email: nil, phone: phone)
    end
  end

  def lookup_invite(conn, %{"guest" => %{"email" => email}}) do
    email = String.trim(email) |> String.downcase()

    case Guest.apply_lookup(%Guest{}, %{"email" => email}) do
      {:error, changeset} ->
        conn |> render_lookup(changeset: changeset)

      {:ok, _changeset} ->
        MyGuest.get_guest(email: email)
        |> case do
          nil -> nil
          :many_matches -> :many_matches
          guest -> MyGuest.load(guest, preload: :rsvp)
        end
        |> case do
          %Guest{rsvp: nil} = guest ->
            conn
            |> put_resp_cookie("guest-id", guest.id, encrypt: true)
            |> redirect(to: ~p"/rsvp/confirm")

          %Guest{} = guest ->
            conn
            |> put_resp_cookie("guest-id", guest.id, encrypt: true)
            |> redirect(to: ~p"/rsvp")

          :many_matches ->
            conn
            |> put_flash(
              :error,
              "There are multiple guest with the same information. Please contact Helen or Adam."
            )

          _ ->
            conn |> render(:no_invitation, email: email, phone: nil)
        end
    end
  end

  def update_rsvp(conn, params) do
    invitation = MyGuest.get_invitation(params["invitation_id"], preload: :guests)
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

    case params["dietary_restrictions"] do
      nil -> {:ok, invitation}
      "" -> {:ok, invitation}
      dr -> MyGuest.update(invitation, %{"dietary_restrictions" => dr})
    end

    conn
    |> put_flash(:info, "Updated RSVP")
    |> redirect(to: ~p"/rsvp/thanks")
  end

  def add_guest(conn, %{"guest" => guest_params, "redirect" => redirect}) do
    guest_id = get_guest_id(conn)

    invitation = MyGuest.get_guest!(guest_id, preload: :invitation) |> then(& &1.invitation)

    cond do
      # guest_params invitation_id is  string, casting both values to a string
      # just protects against unforseen edge cases.
      to_string(guest_params["invitation_id"]) != to_string(invitation.id) -> :denied
      invitation == nil -> :denied
      invitation.permit_kids and guest_params["is_kid"] == "true" -> :ok
      invitation.additional_guests > 0 -> :ok
      true -> :denied
    end
    |> case do
      :ok ->
        case MyGuest.create_guest(guest_params, invitation) do
          {:ok, %Guest{is_kid: true} = guest} ->
            conn
            |> put_flash(
              :info,
              "#{guest.first_name} #{guest.last_name} was added to invite. Feel free to add more or click continue once done."
            )
            |> redirect(to: redirect)

          {:ok, guest} ->
            conn
            |> put_flash(
              :info,
              "Added #{guest.first_name} #{guest.last_name} to your invitation."
            )
            |> redirect(to: redirect)

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :add_guest, changeset: changeset)
        end

      :denied ->
        conn
        |> put_flash(
          :error,
          "You do not have permission to add guest. If you think this is a mistake please contact Adam or Helen."
        )
        |> redirect(to: ~p"/rsvp/confirm")
    end
  end

  def add_guest_form(conn, _params) do
    %{invitation: invitation} = get_confirm_details(conn)

    changeset = Guest.changeset(%Guest{})
    render(conn, :confirm_add_guest, changeset: changeset, step_id: 1, invitation: invitation)
  end

  def add_kid_form(conn, _params) do
    %{invitation: invitation} = get_confirm_details(conn)

    kids = Enum.filter(invitation.guests, & &1.is_kid)

    changeset = Guest.changeset(%Guest{})

    render(conn, :confirm_add_kids,
      changeset: changeset,
      step_id: 2,
      invitation: invitation,
      kids: kids
    )
  end

  def thanks(conn, _params) do
    %{invitation: invitation} = get_confirm_details(conn)
    guests = invitation.guests |> MyGuest.load(preload: :rsvp)

    if MyGuest.all_rsvp?(guests) do
      conn |> render(:thanks, invitation: invitation, guests: guests)
    else
      conn |> redirect(to: ~p"/rsvp/edit")
    end
  end

  defp get_confirm_details(conn) do
    guest_id = get_guest_id(conn)

    invitation =
      case guest_id do
        nil -> nil
        guest_id -> MyGuest.get_invitation(guest_id: guest_id, preload: :guests)
      end

    %{guest_id: guest_id, invitation: invitation}
  end

  defp render_lookup(conn, changeset: changeset) do
    conn |> render(:lookup, changeset: changeset, guests: [])
  end

  defp render_lookup(conn) do
    changeset = Guest.lookup_changeset(%Guest{})
    conn |> render(:lookup, changeset: changeset, guests: [])
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
