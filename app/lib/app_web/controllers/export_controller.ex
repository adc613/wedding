defmodule AppWeb.ExportController do
  alias App.MyGuest
  use AppWeb, :controller

  def guest_list(conn, _params) do
    MyGuest.list_guests(:with_invitations)
    |> Enum.map(fn guest ->
      %{
        first_name: guest.first_name,
        last_name: guest.last_name,
        phone: guest.phone,
        rsvp?: guest.rsvp != nil,
        additional_guests: additional_guests(guest.invitation),
        invitation?: guest.invitation != nil,
        wedding?: guest.invitation != nil and :wedding in guest.invitation.events,
        brunch?: guest.invitation != nil and :brunch in guest.invitation.events,
        rehersal?: guest.invitation != nil and :rehersal in guest.invitation.events,
        edit_guest: "https://wedding.adamcollins.io" <> ~p"/guest/#{guest}/edit",
        edit_invite: invite_link(guest.invitation)
      }
    end)
    |> CSV.encode(
      headers: [
        first_name: "First name",
        last_name: "Last name",
        phone: "Phone",
        rsvp?: "RSVP'd",
        invitation?: "Has invitation",
        additional_guests: "Plus One(s)",
        rehersal?: "Invited to Rehaersal",
        brunch?: "Invited to Brunch",
        edit_guest: "Edit Guest",
        edit_invite: "Edit Invite"
      ]
    )
    |> Enum.join("")
    |> render_file(conn, "guests")
  end

  defp render_file(data, conn, name) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{name}.csv\"")
    |> put_root_layout(false)
    |> send_resp(200, data)
  end

  defp additional_guests(nil), do: 0
  defp additional_guests(invitation), do: invitation.additional_guests

  defp invite_link(nil), do: ""

  defp invite_link(invitation),
    do: "https://wedding.adamcollins.io" <> ~p"/invitation/#{invitation}/edit"
end
