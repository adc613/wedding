defmodule AppWeb.ExportController do
  alias App.MyGuest
  use AppWeb, :controller

  def invite(conn, _params) do
    MyGuest.list_invitations()
    |> Enum.map(fn invite ->
      %{
        invitation_id: invite.id,
        additional_guests: invite.additional_guests,
        kids?: invite.permit_kids,
        brunch?: has_event(invite, :brunch),
        rehersal?: has_event(invite, :rehersal),
        wedding?: has_event(invite, :wedding),
        restrictions: invite.dietary_restrictions,
        robey?: invite.robey
      }
    end)
    |> CSV.encode(
      headers: [
        invitation_id: "Invitation ID",
        additional_guests: "Additional guest(s)",
        kids?: "Permit kids",
        brunch?: "Yes to Brunch",
        rehersal?: "Yes to Rehearsal",
        wedding?: "Yes to Wedding",
        restrictions: "Dietary Restrictions",
        robey?: "Robey"
      ]
    )
    |> Enum.join("")
    |> render_file(conn, "invites")
  end

  def rsvp(conn, _params) do
    MyGuest.list_guests(:with_invitations)
    |> Enum.map(fn guest ->
      %{
        first_name: guest.first_name,
        last_name: guest.last_name,
        invitation_id:
          if guest.invitation == nil do
            0
          else
            guest.invitation.id
          end,
        answered?: guest.rsvp != nil,
        brunch?: has_event(guest.rsvp, :brunch),
        rehersal?: has_event(guest.rsvp, :rehersal),
        wedding?: has_event(guest.rsvp, :wedding)
      }
    end)
    |> CSV.encode(
      headers: [
        first_name: "First name",
        last_name: "Last name",
        invitation_id: "Invitation ID",
        answered?: "RSVP'd",
        brunch?: "Yes to Brunch",
        rehersal?: "Yes to Rehearsal",
        wedding?: "Yes to Wedding"
      ]
    )
    |> Enum.join("")
    |> render_file(conn, "rsvps")
  end

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

  defp has_event(nil, _event), do: nil

  defp has_event(thing, event) do
    event in thing.events
  end
end
